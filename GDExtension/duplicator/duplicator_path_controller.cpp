#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/mutex.hpp>
#include "actions.h"
#include "duplicator_path_controller.h"

using namespace std;
using namespace godot;
using namespace actions;


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
void DuplicatorPathController::get_world_info(Vector2i pos_t, Vector2i min_pos_t, vector<vector<uint32_t>>& lv) {
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

    tile_mutex->unlock();
    // ================ END CRITICAL SECTION ================
}

// check all four neighbors for tiles with higher merge priority, or other duplicators from which danger can be inherited
// danger_lv is set to DANGER_LV_MAX if adjacent to a higher-merge-priority tile, or neighbor.danger_lv - 1 if adjacent to another duplicator
// danger_escape_dir is set to point away from souce of highest danger_lv, or any one if there are multiple
// set neighbor danger rn bc own danger will change once get_action() returns
// NOTE assumes each entity has unique merge_priority
void DuplicatorPathController::update_danger(vector<vector<uint32_t>>& lv, Vector2i min_pos_t, Vector2i lv_pos) {
    uint32_t dest_stuff_id = lv[lv_pos.y][lv_pos.x];
    uint8_t dest_type_id = actions::get_type_id(dest_stuff_id);

    for (auto& [dir_id, dir] : DIRECTIONS) {
        Vector2i src_lv_pos = lv_pos + dir;
        uint32_t src_stuff_id = lv[src_lv_pos.y][src_lv_pos.x];
        uint8_t src_type_id = actions::get_type_id(src_stuff_id);

        // duplicator is safe if push_count is nonzero (not immediate merge where neighbor type_id is preserved)
        // lv width does not have to accommodate neighbor's tpl
        // to be conservative, assume allow_type_change for dominant tile
        if (is_type_dominant(src_type_id, dest_type_id) && (!get_slide_push_count(lv, src_lv_pos, -dir, true, true, true) || !get_split_push_count(lv, src_lv_pos, -dir, true, true, true))) {
            // ================ START CRITICAL SECTION ================
            danger_mutex.lock();
            danger.level = DANGER_LV_MAX;
            danger.escape_dir = -dir;
            danger_mutex.unlock();
            // ================ END CRITICAL SECTION ================
            update_neighbor_dangers(min_pos_t, lv_pos);
            break;
        }
    }
}

void DuplicatorPathController::update_neighbor_dangers(Vector2i min_pos_t, Vector2i lv_pos) {
    // update neighbor dangers
    Vector2i pos_t = min_pos_t + lv_pos;
    Array layer_mutexes = world->get("layer_mutexes");
    Ref<Mutex> tile_mutex = layer_mutexes[LayerId::TILE];

    for (auto& [dir_id, dir] : DIRECTIONS) {
        Vector2i curr_pos_t = pos_t + dir;

        // ================ START CRITICAL SECTION ================
        tile_mutex->lock();
        uint8_t curr_type_id = get_type_id(curr_pos_t);
        if (curr_type_id == TypeId::DUPLICATOR) {
            Ref<RefCounted> curr_tile_entity = world->call("get_aligned_tile_entity", curr_type_id, curr_pos_t);
            DuplicatorPathController* path_controller = RefCounted::cast_to<DuplicatorPathController>(curr_tile_entity->get("path_controller"));
            // ================ START CRITICAL SECTION ================
            danger_mutex.lock();
            path_controller->danger_mutex.lock();
            Danger& neighbor_danger = path_controller->danger;
            if (danger.level - 1 > neighbor_danger.level) {
                neighbor_danger.level = danger.level - 1;
                neighbor_danger.escape_dir = danger.escape_dir;
            }
            path_controller->danger_mutex.unlock();
            danger_mutex.unlock();
            // ================ END CRITICAL SECTION ================
        }
        tile_mutex->unlock();
        // ================ END CRITICAL SECTION ================
    }
}

// action dir should be normalized
Vector3i DuplicatorPathController::get_action(Vector2i pos_t) {
    // get world info
    Vector2i min_pos_t = Vector2i(pos_t.x - LV_RADIUS, pos_t.y - LV_RADIUS);
    Vector2i lv_pos = pos_t - min_pos_t;
    vector<vector<uint32_t>> lv = vector<vector<uint32_t>>(LV_WIDTH, vector<uint32_t>(LV_WIDTH, StuffId::NONE));
    unordered_map<Vector2i, Danger> neighbors;
    get_world_info(pos_t, min_pos_t, lv);

    // update danger
    update_danger(lv, min_pos_t, lv_pos);

    // escape has highest priority
    if (danger.level) {
        vector<EscapeAction> escape_actions;
        
        // try escape_dir
        if (get_slide_push_count(lv, lv_pos, danger.escape_dir, false, true, true) != -1) {
            --danger.level;
            return Vector3i(danger.escape_dir.x, danger.escape_dir.y, ActionId::SLIDE);
        }
        if (get_split_push_count(lv, lv_pos, danger.escape_dir, false, true, true) != -1) {
            --danger.level;
            return Vector3i(danger.escape_dir.x, danger.escape_dir.y, ActionId::SPLIT);
        }

        // try dirs perpendicular to escape_dir
        uniform_int_distribution<int> distribution{0, 1};
        bool rand_bool = distribution(generator);

        for (int action_id : {ActionId::SLIDE, ActionId::SPLIT}) {
            for (const pair<int, Vector2i>& dir_entry : DIRECTIONS) {
                Vector2i dir = dir_entry.second;

                if (!dot(danger.escape_dir, dir)) {
                    if (rand_bool) {
                        dir *= -1;
                    }
                    Vector3i action = Vector3i(dir.x, dir.y, action_id);
                    if (get_action_push_count(lv, lv_pos, action, false, true, true) != -1) {
                        --danger.level;
                        return action;
                    }
                }
            }
        }

        // wait
        // NOTE there is rare case where if dominant tile is on top of duplicator membrane and split-mergeable,
        // sliding in -escape_dir can be a good move by pushing dominant tile out
        // ignore this case since duplicator shouldn't be that intelligent anyway
        return Vector3i(danger.escape_dir.x, danger.escape_dir.y, ActionId::NONE);
    }

    // hunt type-dominated, non-regular, no-type-change-mergeable neighbor
    // (don't die (become TileId::ZERO) for the hunt)
    uint32_t src_stuff_id = lv[lv_pos.y][lv_pos.x];
    vector<HuntAction> hunt_actions;

    for (auto& [dir_id, dir] : DIRECTIONS) {
        Vector2i curr_lv_pos = lv_pos + dir;
        uint32_t curr_stuff_id = lv[curr_lv_pos.y][curr_lv_pos.x];
        uint8_t curr_type_id = actions::get_type_id(curr_stuff_id);

        if (curr_type_id != TypeId::REGULAR && is_type_dominant(TypeId::DUPLICATOR, curr_type_id)) {

            for (int action_id : {ActionId::SLIDE, ActionId::SPLIT}) {
                Vector3i action = Vector3i(dir.x, dir.y, action_id);

                if (!get_action_push_count(lv, lv_pos, action, false, true, true)) {
                    // get power resulting from merge
                    int src_tile_id = actions::get_tile_id(src_stuff_id);
                    if (action.z == ActionId::SPLIT) {
                        src_tile_id = get_splitted_tile_id(src_tile_id);
                    }
                    int dest_tile_id = actions::get_tile_id(curr_stuff_id);
                    int merged_tile_id = get_merged_tile_id(src_tile_id, dest_tile_id);
                    int resulting_power = tile_id_to_val(merged_tile_id).x;

                    // get target merge priority
                    int target_merge_priority = merge_priorities.at(curr_type_id);

                    hunt_actions.emplace_back(action, resulting_power, target_merge_priority);
                }
            }
        }
    }

    if (!hunt_actions.empty()) {
        sort(hunt_actions.begin(), hunt_actions.end());
        return hunt_actions[0].action;
    }

    // wander and reproduce
    // don't make wander action deterministic, even if conditions suggest that a move is very good
    // generally prefer split over slide and high resulting pow over low
}

// prefer slide over split
// prefer randomly chosen perpendicular dir
bool DuplicatorPathController::EscapeAction::operator<(const EscapeAction& other) const {
    if (action.z != other.action.z) {
        return action.z == ActionId::SPLIT;
    }
}

// prefer split over slide
// else prefer higher resulting power
// else prefer lower merge priority neighbor
// else prefer randomly chosen neighbor
bool DuplicatorPathController::HuntAction::operator<(const HuntAction& other) const {
    if (action.z != other.action.z) {
        return action.z == ActionId::SPLIT;
    }
    if (resulting_power != other.resulting_power) {
        return resulting_power > other.resulting_power;
    }
    if (target_merge_priority != other.target_merge_priority) {
        return target_merge_priority < other.target_merge_priority;
    }
    uniform_int_distribution<int> distribution{0, 1};
    return distribution(generator);
}