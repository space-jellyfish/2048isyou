#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/mutex.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/engine.hpp>
#include "actions.h"
#include "hostile_path_controller.h"

using namespace std;
using namespace godot;
using namespace actions;


void HostilePathController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_gv", "p_gv"), &HostilePathController::set_gv);
	ClassDB::bind_method(D_METHOD("get_gv"), &HostilePathController::get_gv);
	ClassDB::bind_method(D_METHOD("set_world", "p_world"), &HostilePathController::set_world);
	ClassDB::bind_method(D_METHOD("get_world"), &HostilePathController::get_world);
	ClassDB::bind_method(D_METHOD("set_cells", "p_cells"), &HostilePathController::set_cells);
	ClassDB::bind_method(D_METHOD("get_cells"), &HostilePathController::get_cells);
	ClassDB::bind_method(D_METHOD("set_entity", "p_entity"), &HostilePathController::set_entity);
	ClassDB::bind_method(D_METHOD("get_entity"), &HostilePathController::get_entity);
    ClassDB::bind_method(D_METHOD("get_actions"), &HostilePathController::get_actions);

    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "gv", PROPERTY_HINT_NODE_TYPE, "Node"), "set_gv", "get_gv");
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "world", PROPERTY_HINT_NODE_TYPE, "Node2D"), "set_world", "get_world");
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "cells", PROPERTY_HINT_NODE_TYPE, "TileMap"), "set_cells", "get_cells");
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "entity", PROPERTY_HINT_NODE_TYPE, "RefCounted"), "set_entity", "get_entity");
}

HostilePathController::HostilePathController() {
    random_device rd;
    generator = mt19937(rd());
}

HostilePathController::~HostilePathController() {

}

void HostilePathController::set_gv(Node* p_gv) {
    gv = p_gv;
}

Node* HostilePathController::get_gv() {
    return gv;
}

void HostilePathController::set_world(Node2D* p_world) {
    world = p_world;
}

Node2D* HostilePathController::get_world() {
    return world;
}

void HostilePathController::set_cells(TileMap* p_cells) {
    cells = p_cells;
}

TileMap* HostilePathController::get_cells() {
    return cells;
}

void HostilePathController::set_entity(Ref<RefCounted> p_entity) {
    entity = p_entity;
}

Ref<RefCounted> HostilePathController::get_entity() {
    return entity;
}


uint8_t HostilePathController::get_tile_id(Vector2i pos_t) {
    Vector2i atlas_coords = cells->get_cell_atlas_coords(LayerId::TILE, pos_t);
    return atlas_coords_to_tile_id(atlas_coords);
}

uint8_t HostilePathController::get_type_id(Vector2i pos_t) {
    Vector2i atlas_coords = cells->get_cell_atlas_coords(LayerId::TILE, pos_t);
    return atlas_coords_to_type_id(atlas_coords);
}

uint8_t HostilePathController::get_back_id(Vector2i pos_t) {
    Vector2i atlas_coords = cells->get_cell_atlas_coords(LayerId::BACK, pos_t);
    return atlas_coords_to_back_id(atlas_coords);
}

uint16_t HostilePathController::get_nav_id(Vector2i pos_t) {
    Vector2i atlas_coords = cells->get_cell_atlas_coords(LayerId::NAV, pos_t);
    return atlas_coords_to_nav_id(atlas_coords);
}

uint32_t HostilePathController::get_stuff_id(Vector2i pos_t) {
    return make_tile_bits(get_tile_id(pos_t)) + make_type_bits(get_type_id(pos_t)) + make_back_bits(get_back_id(pos_t)) + make_nav_bits(get_nav_id(pos_t));
}


// neighbor entry (dir : Danger) not added if neighbor isn't a hostile
void HostilePathController::get_world_info(Vector2i pos_t, Vector2i min_pos_t, vector<vector<uint32_t>>& lv) {

}


// action dir should be normalized
void HostilePathController::get_actions() {

}
