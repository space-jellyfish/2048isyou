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
#include <godot_cpp/classes/tile_map.hpp>
#include "actions.h"

using namespace std;
using namespace godot;


// should be thread-safe
class DuplicatorPathController : public RefCounted {
    GDCLASS(DuplicatorPathController, RefCounted);

private:
    struct Danger {
        int level = 0;
        Vector2i escape_dir = DIRECTIONS.at(DirectionId::RIGHT);
    };

    static const int DANGER_LV_MAX = 2;
    int LV_RADIUS = tile_push_limits.at(EntityId::DUPLICATOR) + 1;
    int LV_WIDTH = 2 * LV_RADIUS + 1;

    Node* gv = nullptr;
    Node2D* world = nullptr;
    TileMap* cells = nullptr;

    Danger danger;

protected:
	static void _bind_methods();

public:
    void set_gv(Node* _gv);
    Node* get_gv();
    void set_world(Node2D* w);
    Node2D* get_world();
    void set_cells(TileMap* t);
    TileMap* get_cells();

    int get_danger_lv();
    Vector2i get_danger_escape_dir();

    uint8_t get_tile_id(Vector2i pos_t);
    uint8_t get_type_id(Vector2i pos_t);
    uint8_t get_back_id(Vector2i pos_t);
    uint16_t get_nav_id(Vector2i pos_t);
    uint32_t get_stuff_id(Vector2i pos_t);

    void get_world_info(Vector2i pos_t, Vector2i min_pos_t, vector<vector<uint32_t>>& lv, unordered_map<Vector2i, Danger>& neighbors);
    void update_danger(Vector2i pos_t);
    Vector3i get_action(Vector2i pos_t);
};

#endif