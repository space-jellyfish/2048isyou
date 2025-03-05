#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/mutex.hpp>
#include "actions.h"
#include "duplicator_path_controller.h"

using namespace std;
using namespace godot;


void DuplicatorPathController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_gv", "_gv"), &DuplicatorPathController::set_gv);
	ClassDB::bind_method(D_METHOD("get_gv"), &DuplicatorPathController::get_gv);
	ClassDB::bind_method(D_METHOD("set_world", "w"), &DuplicatorPathController::set_world);
	ClassDB::bind_method(D_METHOD("get_world"), &DuplicatorPathController::get_world);
    ClassDB::bind_method(D_METHOD("get_danger_lv"), &DuplicatorPathController::get_danger_lv);
    ClassDB::bind_method(D_METHOD("get_danger_escape_dir"), &DuplicatorPathController::get_danger_escape_dir);

    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "gv", PROPERTY_HINT_NODE_TYPE, "Node"), "set_gv", "get_gv");
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "world", PROPERTY_HINT_NODE_TYPE, "Node2D"), "set_world", "get_world");
}

void DuplicatorPathController::set_gv(Node* _gv) {
    gv = _gv;
}

Node* DuplicatorPathController::get_gv() {
    return gv;
}

void DuplicatorPathController::set_world(Node2D* w) {
    world = w;
}

Node2D* DuplicatorPathController::get_world() {
    return world;
}

void DuplicatorPathController::set_cells(TileMap* t) {
    cells = t;
}

TileMap* DuplicatorPathController::get_cells() {
    return cells;
}


uint8_t DuplicatorPathController::get_tile_id(Vector2i pos_t) {
    Vector2i atlas_coords = cells->get_cell_atlas_coords(LayerId::TILE, pos_t);
    return atlas_coords_to_tile_id(atlas_coords);
}

uint8_t DuplicatorPathController::get_type_id(Vector2i pos_t) {
    Vector2i atlas_coords = cells->get_cell_atlas_coords(LayerId::TILE, pos_t);
    return atlas_coords_to_type_id(atlas_coords);
}

uint8_t DuplicatorPathController::get_back_id(Vector2i pos_t) {
    Vector2i atlas_coords = cells->get_cell_atlas_coords(LayerId::BACK, pos_t);
    return atlas_coords_to_back_id(atlas_coords);
}

uint16_t DuplicatorPathController::get_nav_id(Vector2i pos_t) {
    Vector2i atlas_coords = cells->get_cell_atlas_coords(LayerId::NAV, pos_t);
    return atlas_coords_to_nav_id(atlas_coords);
}

uint32_t DuplicatorPathController::get_stuff_id(Vector2i pos_t) {
    return make_tile_bits(get_tile_id(pos_t)) + make_type_bits(get_type_id(pos_t)) + make_back_bits(get_back_id(pos_t)) + make_nav_bits(get_nav_id(pos_t));
}


// neighbor entry (dir : Danger) not added if neighbor isn't a duplicator
void DuplicatorPathController::get_world_info(Vector2i pos_t, Vector2i min_pos_t, vector<vector<uint32_t>>& lv, unordered_map<Vector2i, Danger>& neighbors) {
    Array layer_mutexes = world->get("layer_mutexes");
    Ref<Mutex> tile_mutex = layer_mutexes[LayerId::TILE];
    // ================ START CRITICAL SECTION ================
    tile_mutex->lock();

    for (int dx = 0; dx < lv[0].size(); ++dx) {
        Vector2i curr_pos_t = Vector2i(min_pos_t.x + dx, pos_t.y);
        Vector2i curr_lv_pos = curr_pos_t - min_pos_t;
        lv[curr_lv_pos.y][curr_lv_pos.x] = get_stuff_id(curr_pos_t);
    }
    for (int dy = 0; dy <= lv.size(); ++dy) {
        Vector2i curr_pos_t = Vector2i(pos_t.x, min_pos_t.y + dy);
        Vector2i curr_lv_pos = curr_pos_t - min_pos_t;
        lv[curr_lv_pos.y][curr_lv_pos.x] = get_stuff_id(curr_pos_t);
    }
    for (auto& [dir_id, dir] : DIRECTIONS) {
        Vector2i curr_pos_t = pos_t + dir;
        uint8_t curr_type_id = get_type_id(curr_pos_t);
        if (curr_type_id == TypeId::DUPLICATOR) {
            Ref<RefCounted> curr_tile_entity = world->call("get_aligned_tile_entity", curr_type_id, curr_pos_t);
            DuplicatorPathController* path_controller = RefCounted::cast_to<DuplicatorPathController>(curr_tile_entity->get("path_controller"));
            neighbors[dir] = path_controller->danger;
        }
    }

    tile_mutex->unlock();
    // ================ END CRITICAL SECTION ================
}

// check all four neighbors for tiles with higher merge priority, or other duplicators from which danger can be inherited
// danger_lv is set to DANGER_LV_MAX if adjacent to a higher-merge-priority tile, or neighbor.danger_lv - 1 if adjacent to another duplicator
// danger_escape_dir is set to point away from souce of highest danger_lv, or any one if there are multiple
// NOTE assumes each entity has unique merge_priority
void DuplicatorPathController::update_danger(vector<vector<uint32_t>>& lv, Vector2i lv_pos, unordered_map<Vector2i, Danger>& neighbors) {
    for (auto& [dir_id, dir] : DIRECTIONS) {
        auto neighbor_itr = neighbors.find(dir);

        if (neighbor_itr != neighbors.end()) {
            // neighbor is duplicator
            Danger neighbor_danger = (*neighbor_itr).second;
            if (neighbor_danger.level - 1 > danger.level) {
                danger.level = neighbor_danger.level - 1;
                danger.escape_dir = neighbor_danger.escape_dir;
            }
        }
        else {
            Vector2i curr_lv_pos = lv_pos + dir;
            // duplicator is safe if push_count is nonzero (not immediate merge where neighbor type_id is preserved)
            // lv width does not have to accommodate neighbor's tpl
            if (!get_slide_push_count(lv, curr_lv_pos, -dir, false, true, true) || !get_split_push_count(lv, curr_lv_pos, -dir, false, true, true)) {
                danger.level = DANGER_LV_MAX;
                danger.escape_dir = -dir;
                return;
            }
        }
    }
}

// action dir should be normalized
Vector3i DuplicatorPathController::get_action(Vector2i pos_t) {
    // get world info
    Vector2i min_pos_t = Vector2i(pos_t.x - LV_RADIUS, pos_t.y - LV_RADIUS);
    Vector2i lv_pos = pos_t - min_pos_t;
    vector<vector<uint32_t>> lv = vector<vector<uint32_t>>(LV_WIDTH, vector<uint32_t>(LV_WIDTH, StuffId::NONE));
    unordered_map<Vector2i, Danger> neighbors;
    get_world_info(pos_t, min_pos_t, lv, neighbors);

    // update danger
    update_danger(lv, lv_pos, neighbors);

    // escape has highest priority
    if (danger.level) {
        // try escape_dir
        if (world->call("try_slide"))
    }
}