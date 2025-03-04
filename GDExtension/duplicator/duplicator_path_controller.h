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
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include "OpenClosedList.h"

using namespace std;
using namespace godot;


// should be thread-safe
class DuplicatorPathController : public RefCounted {
    GDCLASS(DuplicatorPathController, RefCounted);

private:
    static const int DANGER_LV_MAX = 2;

    Node* gv = nullptr;
    Node2D* world = nullptr;

    int danger_lv = 0;
    Vector2i danger_escape_dir = Vector2i(1, 0);

protected:
	static void _bind_methods();

public:
    void set_gv(Node* _gv);
    Node* get_gv();
    void set_world(Node2D* w);
    Node2D* get_world();

    void update_danger(Vector2i pos_t);
    Vector3i get_action(Vector2i pos_t);
};

#endif