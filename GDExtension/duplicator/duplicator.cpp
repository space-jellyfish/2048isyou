#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/window.hpp>
#include "duplicator.h"

using namespace std;
using namespace godot;


void DuplicatorPathController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_gv", "_gv"), &DuplicatorPathController::set_gv);
	ClassDB::bind_method(D_METHOD("get_gv"), &DuplicatorPathController::get_gv);
	ClassDB::bind_method(D_METHOD("set_world", "w"), &DuplicatorPathController::set_world);
	ClassDB::bind_method(D_METHOD("get_world"), &DuplicatorPathController::get_world);
    ClassDB::bind_method(D_METHOD("test_gv"), &DuplicatorPathController::test_gv);

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

float DuplicatorPathController::test_gv() {
    return gv->get("SHIFT_TIME");
}