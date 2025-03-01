#ifndef DUPLICATOR_PATH_CONTROLLER_HPP
#define DUPLICATOR_PATH_CONTROLLER_HPP

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include "OpenClosedList.h"

using namespace std;
using namespace godot;


class DuplicatorPathController : public Node {
    GDCLASS(DuplicatorPathController, Node);

private:
    Node2D* world = nullptr;

protected:
	static void _bind_methods();

public:
    void set_world(Node2D* w);
    Node2D* get_world();

    Vector2i test_world();
};

#endif