#ifndef DUPLICATOR_PATH_CONTROLLER_HPP
#define DUPLICATOR_PATH_CONTROLLER_HPP

// We don't need windows.h in this example plugin but many others do, and it can
// lead to annoying situations due to the ton of macros it defines.
// So we include it and make sure CI warns us if we use something that conflicts
// with a Windows define.
#ifdef WIN32
#include <windows.h>
#endif

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include "OpenClosedList.h"

using namespace std;
using namespace godot;


class DuplicatorPathController : public Node {
    GDCLASS(DuplicatorPathController, Node);

private:
    Node* gv = nullptr;
    Node2D* world = nullptr;

protected:
	static void _bind_methods();

public:
    void set_gv(Node* _gv);
    Node* get_gv();
    void set_world(Node2D* w);
    Node2D* get_world();

    float test_gv();
};

#endif