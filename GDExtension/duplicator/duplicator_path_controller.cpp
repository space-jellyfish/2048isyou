#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/mutex.hpp>
#include "actions.h"
#include "duplicator_path_controller.h"

using namespace std;
using namespace godot;
using namespace actions;


thread_local mt19937 DuplicatorPathController::generator{random_device{}()};

void DuplicatorPathController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_gv", "p_gv"), &DuplicatorPathController::set_gv);
	ClassDB::bind_method(D_METHOD("get_gv"), &DuplicatorPathController::get_gv);
	ClassDB::bind_method(D_METHOD("set_world", "p_world"), &DuplicatorPathController::set_world);
	ClassDB::bind_method(D_METHOD("get_world"), &DuplicatorPathController::get_world);
	ClassDB::bind_method(D_METHOD("set_cells", "p_cells"), &DuplicatorPathController::set_cells);
	ClassDB::bind_method(D_METHOD("get_cells"), &DuplicatorPathController::get_cells);
	ClassDB::bind_method(D_METHOD("set_entity", "p_entity"), &DuplicatorPathController::set_entity);
	ClassDB::bind_method(D_METHOD("get_entity"), &DuplicatorPathController::get_entity);
    ClassDB::bind_method(D_METHOD("on_entity_move_finalized", "pos_t", "is_reversed", "resulting_entity"), &DuplicatorPathController::on_entity_move_finalized);
    ClassDB::bind_method(D_METHOD("get_actions", "pos_t"), &DuplicatorPathController::get_actions);

    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "gv", PROPERTY_HINT_NODE_TYPE, "Node"), "set_gv", "get_gv");
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "world", PROPERTY_HINT_NODE_TYPE, "Node2D"), "set_world", "get_world");
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "cells", PROPERTY_HINT_NODE_TYPE, "TileMap"), "set_cells", "get_cells");
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "entity", PROPERTY_HINT_NODE_TYPE, "RefCounted"), "set_entity", "get_entity");
}

void DuplicatorPathController::set_gv(Node* p_gv) {
    gv = p_gv;
}

Node* DuplicatorPathController::get_gv() {
    return gv;
}

void DuplicatorPathController::set_world(Node2D* p_world) {
    world = p_world;
}

Node2D* DuplicatorPathController::get_world() {
    return world;
}

void DuplicatorPathController::set_cells(TileMap* p_cells) {
    cells = p_cells;
}

TileMap* DuplicatorPathController::get_cells() {
    return cells;
}

void DuplicatorPathController::set_entity(Ref<RefCounted> p_entity) {
    entity = p_entity;
}

Ref<RefCounted> DuplicatorPathController::get_entity() {
    return entity;
}

// NOTE this function is run from the main thread, so set_is_busy() => get_actions() won't be called until this function finishes
// NOTE calling function must lock tile_mutex
// NOTE godot signals emitted on the main thread are processed synchronously
// decrement danger level if move succeeded and resulting entity is duplicator
void DuplicatorPathController::on_entity_move_finalized(Vector2i pos_t, bool is_reversed, Ref<RefCounted> resulting_entity) {
    int resulting_entity_id = resulting_entity->get("entity_id");

    if (resulting_entity_id == EntityId::DUPLICATOR) {
        DuplicatorPathController* path_controller = RefCounted::cast_to<DuplicatorPathController>(resulting_entity->get("path_controller"));

        // ================ START CRITICAL SECTION ================
        danger_mutex.lock();
        path_controller->danger_mutex.lock();

        path_controller->danger.level = max(0, danger.level - 1);

        path_controller->danger_mutex.unlock();
        danger_mutex.unlock();
        // ================ END CRITICAL SECTION ================
    }
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
// embrace annihilation: don't escape if neighbor entity will die from merge
// set neighbor danger rn bc own danger will change once get_actions() returns
// NOTE assumes each entity has unique merge_priority
void DuplicatorPathController::update_danger(vector<vector<uint32_t>>& lv, Vector2i min_pos_t, Vector2i lv_pos) {
    uint32_t dest_stuff_id = lv[lv_pos.y][lv_pos.x];
    uint8_t dest_type_id = actions::get_type_id(dest_stuff_id);

    for (auto& [dir_id, dir] : DIRECTIONS) {
        Vector2i src_lv_pos = lv_pos + dir;
        uint32_t src_stuff_id = lv[src_lv_pos.y][src_lv_pos.x];
        uint8_t src_type_id = actions::get_type_id(src_stuff_id);

        // check type for early exit, not essential to logic
        if (!is_type_dominant(src_type_id, dest_type_id)) {
            continue;
        }

        // duplicator is safe if push_count is nonzero (not immediate merge where neighbor type_id is preserved)
        // lv width does not have to accommodate neighbor's tpl
        for (int action_id : {ActionId::SLIDE, ActionId::SPLIT}) {
            Vector3i action = Vector3i(-dir.x, -dir.y, action_id);

            if (!get_action_push_count(lv, src_lv_pos, action, true, true, false, false, false)) {
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
void DuplicatorPathController::get_actions(Vector2i pos_t) {
    // get answer buffer
    Array entity_actions = entity->get("actions");

    // get world info
    Vector2i min_pos_t = Vector2i(pos_t.x - LV_RADIUS, pos_t.y - LV_RADIUS);
    Vector2i lv_pos = pos_t - min_pos_t;
    vector<vector<uint32_t>> lv = vector<vector<uint32_t>>(LV_WIDTH, vector<uint32_t>(LV_WIDTH, StuffId::NONE));
    get_world_info(pos_t, min_pos_t, lv);

    // ================ START CRITICAL SECTION ================
    danger_mutex.lock();
    Danger temp_danger = danger;
    danger_mutex.unlock();
    // ================ END CRITICAL SECTION ================

    // update danger
    // NOTE danger level is unchanged if no dangerous neighbors detected
    update_danger(lv, min_pos_t, lv_pos);

    // try escape
    uint32_t src_stuff_id = lv[lv_pos.y][lv_pos.x];
    int src_tile_id = actions::get_tile_id(src_stuff_id);
    int src_power = tile_id_to_val(src_tile_id).x;

    // escape, hunt, wander, reproduce
    // don't make action deterministic, even if conditions suggest that a move is very good
    // don't merge with friendly tiles unless escaping
    vector<Action> actions;

    for (auto& [dir_id, dir] : DIRECTIONS) {
        Vector2i curr_lv_pos = lv_pos + dir;
        uint32_t curr_stuff_id = lv[curr_lv_pos.y][curr_lv_pos.x];
        uint8_t curr_type_id = actions::get_type_id(curr_stuff_id);

        for (int action_id : {ActionId::SLIDE, ActionId::SPLIT}) {
            Vector3i action = Vector3i(dir.x, dir.y, action_id);
            int action_push_count = get_action_push_count(lv, lv_pos, action, true, true, true, false, temp_danger.level);

            // don't move in -escape_dir if danger_level not in [0, DANGER_LV_MAX]
            if (temp_danger.level != 0 && temp_danger.level != DANGER_LV_MAX && dir == -temp_danger.escape_dir) {
                continue;
            }
            
            if (action_push_count != -1) {
                //find resulting power
                int resulting_power;
                if (!action_push_count) {
                    resulting_power = src_power;
                }
                else {
                    int action_src_tile_id = (action.z == ActionId::SPLIT) ? get_splitted_tile_id(src_tile_id) : src_tile_id;
                    int dest_tile_id = actions::get_tile_id(curr_stuff_id);
                    int merged_tile_id = get_merged_tile_id(action_src_tile_id, dest_tile_id);
                    resulting_power = tile_id_to_val(merged_tile_id).x;
                }
                int dot_escape_dir = dot(dir, temp_danger.escape_dir);
                int target_merge_priority = (!action_push_count && T_NONE_OR_REGULAR.find(curr_type_id) == T_NONE_OR_REGULAR.end()) ? merge_priorities.at(curr_type_id) : -1;

                actions.emplace_back(action, resulting_power, dot_escape_dir, target_merge_priority, temp_danger.level);
            }
        }
    }

    if (!actions.empty()) {
        sort(actions.begin(), actions.end());
        entity_actions.push_back(actions[0].action);
    }
    else {
        entity_actions.push_back(Vector3i(0, 0, ActionId::NONE));
    }
    entity->set("actions", entity_actions);
}

// choose slide over split (if escaping)
// else choose target entity over NONE/REGULAR (if hunting)
// else prefer escape dir over perp dir
// else prefer higher resulting power
// else prefer split over slide
DuplicatorPathController::Action::Action(Vector3i p_action, int p_resulting_power, int p_dot_escape_dir, int p_target_merge_priority, bool is_in_danger) :
    action(p_action),
    resulting_power(p_resulting_power),
    dot_escape_dir(p_dot_escape_dir),
    target_merge_priority(p_target_merge_priority)
{
    // escape-related stuff
    if (is_in_danger) {
        // only move toward danger source if danger_level in [0, DANGER_LV_MAX] and no other directions are available
        if (dot_escape_dir == -1) {
            weight -= 2000;
        }
        else {
            weight += (action.z == ActionId::SLIDE) * 2000;
            weight += dot_escape_dir * 10;
        }
    }

    // hunt-related stuff
    weight += (target_merge_priority != -1) * 1000;

    // wander-related stuff
    weight += (action.z == ActionId::SPLIT) * 6;

    // random term for unpredictability
    uniform_int_distribution<int> dist(0, 15);
    weight += dist(generator);
}

bool DuplicatorPathController::Action::operator<(const Action& other) const {
    int resulting_power_bonus = signi(resulting_power - other.resulting_power) * 7;
    int merge_priority_bonus = signi(target_merge_priority - other.target_merge_priority) * 3;
    int temp_weight = weight + resulting_power_bonus + merge_priority_bonus;

    // tiebreaking
    if (temp_weight == other.weight) {
        uniform_int_distribution<int> dist(0, 1);
        return dist(generator);
    }
    return temp_weight > other.weight;
}