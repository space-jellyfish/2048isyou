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
using namespace actions;


// should be thread-safe
class DuplicatorPathController : public RefCounted {
    GDCLASS(DuplicatorPathController, RefCounted);

private:
    // random generator stuff for tiebreaking
    mt19937 generator;

    struct Danger {
        int level = 0;
        Vector2i escape_dir = DIRECTIONS.at(DirectionId::RIGHT);
    };

    // to make final action non-deterministic, calculate a priority score in constructor
    // and compare priority score in the operator overload
    struct Action {
        DuplicatorPathController* dpc;
        int weight = 0;

        Vector3i action;
        int resulting_power;
        int dot_escape_dir;
        int target_merge_priority; //-1 if not merge or target isn't an entity
    
        Action(DuplicatorPathController* p_dpc, Vector3i p_action, int p_resulting_power, int p_dot_escape_dir, int p_target_merge_priority, bool is_in_danger);
        bool operator<(const Action& other) const;
    };

    // stuff from scene tree
    Node* gv = nullptr;
    Node2D* world = nullptr;
    TileMap* cells = nullptr;
    Ref<RefCounted> entity = nullptr;

    static const int DANGER_LV_MAX = 2;
    int LV_RADIUS = tile_push_limits.at(EntityId::DUPLICATOR) + 1;
    int LV_WIDTH = 2 * LV_RADIUS + 1;

    Danger danger;
    recursive_mutex danger_mutex;

protected:
	static void _bind_methods();

public:
    // these require tile_mutex lock
    uint8_t get_tile_id(Vector2i pos_t);
    uint8_t get_type_id(Vector2i pos_t);
    uint8_t get_back_id(Vector2i pos_t);
    uint16_t get_nav_id(Vector2i pos_t);
    uint32_t get_stuff_id(Vector2i pos_t);

    // getter/setters
    void set_gv(Node* p_gv);
    Node* get_gv();
    void set_world(Node2D* p_world);
    Node2D* get_world();
    void set_cells(TileMap* p_cells);
    TileMap* get_cells();
    void set_entity(Ref<RefCounted> p_entity);
    Ref<RefCounted> get_entity();

    DuplicatorPathController();
    ~DuplicatorPathController();

    void get_world_info(Vector2i pos_t, Vector2i min_pos_t, vector<vector<uint32_t>>& lv);
    int get_neighbor_duplicator_count(vector<vector<uint32_t>>& lv, Vector2i lv_pos);
    void update_danger(vector<vector<uint32_t>>& lv, Vector2i min_pos_t, Vector2i lv_pos);
    void update_neighbor_dangers(Vector2i min_pos_t, Vector2i lv_pos);
    void on_entity_move_finalized(Vector2i pos_t, bool is_reversed, Ref<RefCounted> resulting_entity);
    void get_actions(Vector2i pos_t);
};

#endif