#ifndef HOSTILE_PATH_CONTROLLER_HPP
#define HOSTILE_PATH_CONTROLLER_HPP

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
#include <godot_cpp/classes/tile_map.hpp>
#include <random>
#include <mutex>
#include "actions.h"

using namespace std;
using namespace godot;
using namespace actions;


// should be thread-safe
class HostilePathController : public RefCounted {
    GDCLASS(HostilePathController, RefCounted);

private:
    // random generator stuff for tiebreaking
    mt19937 generator;

    // stuff from scene tree
    Node* gv = nullptr;
    Node2D* world = nullptr;
    TileMap* cells = nullptr;
    Ref<RefCounted> entity = nullptr;

protected:
	static void _bind_methods();

public:
    HostilePathController();
    ~HostilePathController();

    // registered with GDScript
    void set_gv(Node* p_gv);
    Node* get_gv();
    void set_world(Node2D* p_world);
    Node2D* get_world();
    void set_cells(TileMap* p_cells);
    TileMap* get_cells();
    void set_entity(Ref<RefCounted> p_entity);
    Ref<RefCounted> get_entity();

    // these require tile_mutex
    uint8_t get_tile_id(Vector2i pos_t);
    uint8_t get_type_id(Vector2i pos_t);
    uint8_t get_back_id(Vector2i pos_t);
    uint16_t get_nav_id(Vector2i pos_t);
    uint32_t get_stuff_id(Vector2i pos_t);

    void get_world_info(Vector2i pos_t, Vector2i min_pos_t, vector<vector<uint32_t>>& lv);
    void get_actions();
};

#endif