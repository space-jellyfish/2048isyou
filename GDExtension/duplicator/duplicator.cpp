#include <godot_cpp/variant/vector2i.hpp>
#include "duplicator.h"

using namespace std;
using namespace godot;


void DuplicatorPathController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_world", "w"), &DuplicatorPathController::set_world);
	ClassDB::bind_method(D_METHOD("get_world"), &DuplicatorPathController::get_world);
    ClassDB::bind_method(D_METHOD("test_world"), &DuplicatorPathController::test_world);

	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "world", PROPERTY_HINT_NODE_TYPE, "Node2D"), "set_world", "get_world");
}

void DuplicatorPathController::set_world(Node2D* w) {
    world = w;
}

Node2D* DuplicatorPathController::get_world() {
    return world;
}

Vector2i DuplicatorPathController::test_world() {
    Vector2i atlas_coords = world->call("get_atlas_coords", 1, Vector2i(0, 0), false);
    return atlas_coords;
}