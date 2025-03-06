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
#include <random>
#include <mutex>
#include "actions.h"

using namespace std;
using namespace godot;


// should be thread-safe
class DuplicatorPathController : public RefCounted {
    GDCLASS(DuplicatorPathController, RefCounted);

private:
    // random generator stuff for tiebreaking
    static thread_local mt19937 generator;

    struct Danger {
        int level = 0;
        Vector2i escape_dir = DIRECTIONS.at(DirectionId::RIGHT);
    };

    struct EscapeAction {
        Vector3i action;
        int resulting_power;
        
        EscapeAction(Vector3i p_action, int p_resulting_power) :
            action(p_action),
            resulting_power(p_resulting_power)
        {}

        bool operator<(const EscapeAction& other) const;
    };

    struct HuntAction {
        Vector3i action;
        int resulting_power;
        int target_merge_priority;

        HuntAction(Vector3i p_action, int p_resulting_power, int p_target_merge_priority) :
            action(p_action),
            resulting_power(p_resulting_power),
            target_merge_priority(p_target_merge_priority)
        {}

        bool operator<(const HuntAction& other) const;
    };

    // stuff from scene tree
    Node* gv = nullptr;
    Node2D* world = nullptr;
    TileMap* cells = nullptr;

    static const int DANGER_LV_MAX = 2;
    int LV_RADIUS = tile_push_limits.at(EntityId::DUPLICATOR) + 1;
    int LV_WIDTH = 2 * LV_RADIUS + 1;

    Danger danger;
    mutex danger_mutex;

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

    // these require tile_mutex
    uint8_t get_tile_id(Vector2i pos_t);
    uint8_t get_type_id(Vector2i pos_t);
    uint8_t get_back_id(Vector2i pos_t);
    uint16_t get_nav_id(Vector2i pos_t);
    uint32_t get_stuff_id(Vector2i pos_t);

    void get_world_info(Vector2i pos_t, Vector2i min_pos_t, vector<vector<uint32_t>>& lv);
    void update_danger(vector<vector<uint32_t>>& lv, Vector2i min_pos_t, Vector2i lv_pos);
    void update_neighbor_dangers(Vector2i min_pos_t, Vector2i lv_pos);
    Vector3i get_action(Vector2i pos_t);
};
thread_local mt19937 DuplicatorPathController::generator{random_device{}()};

#endif