#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include "duplicator.h"

using namespace std;
using namespace godot;


void DuplicatorPathController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_gv", "_gv"), &DuplicatorPathController::set_gv);
	ClassDB::bind_method(D_METHOD("get_gv"), &DuplicatorPathController::get_gv);
	ClassDB::bind_method(D_METHOD("set_world", "w"), &DuplicatorPathController::set_world);
	ClassDB::bind_method(D_METHOD("get_world"), &DuplicatorPathController::get_world);

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

// check all four neighbors for tiles with higher merge priority, or other duplicators from which danger can be inherited
// NOTE assumes each entity has unique merge_priority
void DuplicatorPathController::update_danger(Vector2i pos_t) {
    Dictionary type_enum = gv->get("TypeId");
    Dictionary merge_priorities = gv->get("merge_priorities");
    Array directions = static_cast<Dictionary>(gv->get("DIRECTIONS")).values();
    int type_id = type_enum["DUPLICATOR"];
    int merge_priority = merge_priorities[type_id];

    for (int i = 0; i < directions.size(); ++i) {
        Vector2i dir = directions[i];
        Vector2i curr_pos_t = pos_t + dir;
        int curr_type_id = world->call("get_type_id", curr_pos_t, false);
        int curr_merge_priority = merge_priorities[curr_type_id];

        if (curr_merge_priority > merge_priority) {
            danger_lv = DANGER_LV_MAX;
            danger_escape_dir = -dir;
        }
        else if (curr_type_id == type_id) {
            Ref<RefCounted> entity = world->call("get_aligned_tile_entity", curr_type_id, curr_pos_t);
            
        }

        if (danger_lv == DANGER_LV_MAX) {
            break;
        }
    }


}

// action dir should be normalized
Vector3i DuplicatorPathController::get_action(Vector2i pos_t) {
    
    if (danger_lv) {
        if 
    }


}