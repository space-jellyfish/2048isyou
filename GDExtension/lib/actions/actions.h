#ifndef ACTIONS_HPP
#define ACTIONS_HPP

#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/classes/tile_map.hpp>
#include <vector>
#include <unordered_map>
#include <unordered_set>

// "using declarations should be avoided in header files" nah i don't care
using namespace std;
using namespace godot;


namespace actions {

namespace DirectionId {
enum DirectionId {
	LEFT,
	DOWN,
	UP,
	RIGHT,
};
}

const unordered_map<int, Vector2i> DIRECTIONS = {
	{DirectionId::LEFT, Vector2i(-1, 0)},
	{DirectionId::DOWN, Vector2i(0, 1)},
	{DirectionId::UP, Vector2i(0, -1)},
	{DirectionId::RIGHT, Vector2i(1, 0)},
};

namespace ActionId {
enum ActionId {
    NONE, //wait
	SLIDE,
	SPLIT,
	SHIFT,
};
}

namespace LayerId {
enum LayerId {
	BACK,
	TILE,
	NAV,
};
}

namespace TilePow {
enum TilePow {
	VAL_ZERO = -1,
	VAL_ONE = 0,
	MAX = 14,
	MAX_PROCGEN = 11,
};
}

namespace TileId {
enum TileId {
	EMPTY = 0,
	ZERO = 16,
};
}

namespace TypeId {
enum TypeId {
    NONE = 0,
	PLAYER,
	DUPLICATOR,
	HOSTILE,
	VOID,
	REGULAR,
	SQUID,
};
}

// NOTE TypeId should be usable as EntityId without conversion
namespace EntityId {
enum EntityId {
    NONE = 0,
	PLAYER,
	DUPLICATOR,
	HOSTILE,
	VOID,
	REGULAR,
	SQUID_BODY,
	SQUID_CLUB,
	STP_SPAWNING,
	STP_SPAWNED,
	SNAKE,
};
}

namespace BackId {
enum BackId {
	EMPTY = 0,
	BORDER_ROUND,
	BORDER_SQUARE,
	MEMBRANE,
	BLACK_WALL,
	BLUE_WALL,
	RED_WALL,
	SAVEPOINT,
	GOAL,
	BOARD_FRAME,
};
}

const int NAV_REFCOUNT_MAX = 4; //one tile approaching per side (this is possible since corners are rounded)
const int NAV_DIR_BITLEN = 3; //should be long enough to store max refcount
const int NAV_BIT_BLOCK = (1 << NAV_DIR_BITLEN) - 1;
namespace NavId {
enum NavId {
	NONE = 0,
	LEFT = (1 << (DirectionId::LEFT * NAV_DIR_BITLEN)),
	DOWN = (1 << (DirectionId::DOWN * NAV_DIR_BITLEN)),
	UP = (1 << (DirectionId::UP * NAV_DIR_BITLEN)),
	RIGHT = (1 << (DirectionId::RIGHT * NAV_DIR_BITLEN)),
	ALL = LEFT + DOWN + UP + RIGHT,
};
}

const unordered_map<int, int> tile_push_limits = {
    {EntityId::NONE,            0},
	{EntityId::PLAYER,          2},
	{EntityId::DUPLICATOR,      0},
	{EntityId::HOSTILE,         1},
	{EntityId::VOID,            3},
	{EntityId::REGULAR,         0},
	{EntityId::SQUID_BODY,      0},
	{EntityId::SQUID_CLUB,      6},
	{EntityId::STP_SPAWNING,    0},
	{EntityId::STP_SPAWNED,     2},
	{EntityId::SNAKE,           4},
};

const unordered_map<uint8_t, bool> duplicate_upon_split = {
	{TypeId::NONE, false},
	{TypeId::PLAYER, false},
	{TypeId::DUPLICATOR, true},
	{TypeId::HOSTILE, false},
	{TypeId::VOID, false},
	{TypeId::REGULAR, false},
	{TypeId::SQUID, false},
};

const unordered_map<uint8_t, int> merge_priorities = {
    {TypeId::NONE,          -1},
	{TypeId::REGULAR,       0},
	{TypeId::PLAYER,        1},
	{TypeId::HOSTILE,       2},
	{TypeId::DUPLICATOR,    3},
	{TypeId::VOID,          4},
	{TypeId::SQUID,         5},
};

// push is possible if pusher push_weight >= pushed slide_weight
const unordered_map<int, int> slide_weights = {
    {EntityId::NONE,            0},
	{EntityId::PLAYER,          3},
	{EntityId::DUPLICATOR,      1},
	{EntityId::HOSTILE,         2},
	{EntityId::VOID,            0},
	{EntityId::REGULAR,         0},
	{EntityId::SQUID_BODY,      0},
	{EntityId::SQUID_CLUB,      INT64_MAX},
	{EntityId::STP_SPAWNING,    INT64_MAX},
	{EntityId::STP_SPAWNED,     INT64_MAX},
	{EntityId::SNAKE,           INT64_MAX},
};

// -1 if entity cannot push anything
const unordered_map<int, int> push_weights = {
    {EntityId::NONE,            -1},
	{EntityId::PLAYER,          2},
	{EntityId::DUPLICATOR,      1},
	{EntityId::HOSTILE,         1},
	{EntityId::VOID,            2},
	{EntityId::REGULAR,         -1},
	{EntityId::SQUID_BODY,      -1},
	{EntityId::SQUID_CLUB,      3},
	{EntityId::STP_SPAWNING,    -1},
	{EntityId::STP_SPAWNED,     2},
	{EntityId::SNAKE,           2},
};

const unordered_set<uint8_t> B_WALL_OR_BORDER = {BackId::BORDER_ROUND, BackId::BORDER_SQUARE, BackId::BLACK_WALL, BackId::BLUE_WALL, BackId::RED_WALL};
const unordered_set<uint8_t> B_SAVE_OR_GOAL = {BackId::SAVEPOINT, BackId::GOAL};
const unordered_set<uint8_t> B_EMPTY = {BackId::EMPTY, BackId::BOARD_FRAME};
const unordered_set<uint8_t> T_NONE_OR_REGULAR = {TypeId::NONE, TypeId::REGULAR};
const unordered_set<uint8_t> T_KILLABLE_BY_ZEROING = {TypeId::DUPLICATOR, TypeId::HOSTILE};
const unordered_set<int> E_HAS_PATHFINDING = {EntityId::DUPLICATOR};
const unordered_map<int, unordered_map<int, bool>> E_ENEMY = {
    { EntityId::NONE, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, false},
        {EntityId::DUPLICATOR, false},
        {EntityId::HOSTILE, false},
        {EntityId::VOID, false},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, false},
        {EntityId::SQUID_CLUB, false},
        {EntityId::STP_SPAWNING, false},
        {EntityId::STP_SPAWNED, false},
        {EntityId::SNAKE, false}
    }},
    { EntityId::PLAYER, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, true},
        {EntityId::DUPLICATOR, true},
        {EntityId::HOSTILE, true},
        {EntityId::VOID, true},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, true},
        {EntityId::SQUID_CLUB, true},
        {EntityId::STP_SPAWNING, true},
        {EntityId::STP_SPAWNED, true},
        {EntityId::SNAKE, true}
    }},
    { EntityId::DUPLICATOR, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, true},
        {EntityId::DUPLICATOR, false},
        {EntityId::HOSTILE, false},
        {EntityId::VOID, true},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, true},
        {EntityId::SQUID_CLUB, true},
        {EntityId::STP_SPAWNING, true},
        {EntityId::STP_SPAWNED, true},
        {EntityId::SNAKE, true}
    }},
    { EntityId::HOSTILE, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, true},
        {EntityId::DUPLICATOR, false},
        {EntityId::HOSTILE, false},
        {EntityId::VOID, true},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, true},
        {EntityId::SQUID_CLUB, true},
        {EntityId::STP_SPAWNING, true},
        {EntityId::STP_SPAWNED, true},
        {EntityId::SNAKE, true}
    }},
    { EntityId::VOID, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, true},
        {EntityId::DUPLICATOR, true},
        {EntityId::HOSTILE, true},
        {EntityId::VOID, false},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, true},
        {EntityId::SQUID_CLUB, true},
        {EntityId::STP_SPAWNING, true},
        {EntityId::STP_SPAWNED, true},
        {EntityId::SNAKE, true}
    }},
    { EntityId::REGULAR, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, false},
        {EntityId::DUPLICATOR, false},
        {EntityId::HOSTILE, false},
        {EntityId::VOID, false},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, false},
        {EntityId::SQUID_CLUB, false},
        {EntityId::STP_SPAWNING, false},
        {EntityId::STP_SPAWNED, false},
        {EntityId::SNAKE, false}
    }},
    { EntityId::SQUID_BODY, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, true},
        {EntityId::DUPLICATOR, true},
        {EntityId::HOSTILE, true},
        {EntityId::VOID, true},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, false},
        {EntityId::SQUID_CLUB, false},
        {EntityId::STP_SPAWNING, true},
        {EntityId::STP_SPAWNED, true},
        {EntityId::SNAKE, true}
    }},
    { EntityId::SQUID_CLUB, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, true},
        {EntityId::DUPLICATOR, true},
        {EntityId::HOSTILE, true},
        {EntityId::VOID, true},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, false},
        {EntityId::SQUID_CLUB, false},
        {EntityId::STP_SPAWNING, true},
        {EntityId::STP_SPAWNED, true},
        {EntityId::SNAKE, true}
    }},
    { EntityId::STP_SPAWNING, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, true},
        {EntityId::DUPLICATOR, true},
        {EntityId::HOSTILE, true},
        {EntityId::VOID, true},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, true},
        {EntityId::SQUID_CLUB, true},
        {EntityId::STP_SPAWNING, true},
        {EntityId::STP_SPAWNED, true},
        {EntityId::SNAKE, true}
    }},
    { EntityId::STP_SPAWNED, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, true},
        {EntityId::DUPLICATOR, true},
        {EntityId::HOSTILE, true},
        {EntityId::VOID, true},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, true},
        {EntityId::SQUID_CLUB, true},
        {EntityId::STP_SPAWNING, true},
        {EntityId::STP_SPAWNED, true},
        {EntityId::SNAKE, true}
    }},
    { EntityId::SNAKE, {
        {EntityId::NONE, false},
        {EntityId::PLAYER, true},
        {EntityId::DUPLICATOR, true},
        {EntityId::HOSTILE, true},
        {EntityId::VOID, true},
        {EntityId::REGULAR, false},
        {EntityId::SQUID_BODY, true},
        {EntityId::SQUID_CLUB, true},
        {EntityId::STP_SPAWNING, true},
        {EntityId::STP_SPAWNED, true},
        {EntityId::SNAKE, false}
    }}
};

const int TILE_ID_BITLEN = 5;
const int TYPE_ID_BITLEN = 3;
const int BACK_ID_BITLEN = 8;
const int NAV_ID_BITLEN = 16;
const int TILE_ID_BITPOS = 0;
const int TYPE_ID_BITPOS = TILE_ID_BITLEN;
const int BACK_ID_BITPOS = TILE_ID_BITLEN + TYPE_ID_BITLEN;
const int NAV_ID_BITPOS = TILE_ID_BITLEN + TYPE_ID_BITLEN + BACK_ID_BITLEN;
const uint32_t TILE_ID_MASK = (1 << TILE_ID_BITLEN) - 1;
const uint32_t TYPE_ID_MASK = ((1 << TYPE_ID_BITLEN) - 1) << TYPE_ID_BITPOS;
const uint32_t BACK_ID_MASK = ((1 << BACK_ID_BITLEN) - 1) << BACK_ID_BITPOS;
const uint32_t NAV_ID_MASK = ((1 << NAV_ID_BITLEN) - 1) << NAV_ID_BITPOS;
const uint32_t TILE_ID_INVERTED_MASK = numeric_limits<uint32_t>::max() - TILE_ID_MASK;
const uint32_t TYPE_ID_INVERTED_MASK = numeric_limits<uint32_t>::max() - TYPE_ID_MASK;
const uint32_t BACK_ID_INVERTED_MASK = numeric_limits<uint32_t>::max() - BACK_ID_MASK;
const uint32_t NAV_ID_INVERTED_MASK = numeric_limits<uint32_t>::max() - NAV_ID_MASK;

namespace StuffId {
enum StuffId {
    NONE = (TileId::EMPTY << TILE_ID_BITPOS) + (TypeId::NONE << TYPE_ID_BITPOS) + (BackId::EMPTY << BACK_ID_BITPOS) + (NavId::NONE << NAV_ID_BITPOS),
};
}

uint8_t atlas_coords_to_tile_id(Vector2i tile_atlas_coords);
uint8_t atlas_coords_to_type_id(Vector2i tile_atlas_coords);
uint8_t atlas_coords_to_back_id(Vector2i back_atlas_coords);
uint16_t atlas_coords_to_nav_id(Vector2i nav_atlas_coords);

uint32_t make_tile_bits(uint8_t tile_id);
uint32_t make_type_bits(uint8_t type_id);
uint32_t make_back_bits(uint8_t back_id);
uint32_t make_nav_bits(uint16_t nav_id);
uint32_t remove_tile_id(uint32_t stuff_id);
uint32_t remove_type_id(uint32_t stuff_id);
uint32_t remove_back_id(uint32_t stuff_id);
uint32_t remove_nav_id(uint32_t stuff_id);
uint32_t get_tile_bits(uint32_t stuff_id);
uint32_t get_type_bits(uint32_t stuff_id);
uint32_t get_back_bits(uint32_t stuff_id);
uint32_t get_nav_bits(uint32_t stuff_id);
uint8_t get_tile_id(uint32_t stuff_id);
uint8_t get_type_id(uint32_t stuff_id);
uint8_t get_back_id(uint32_t stuff_id);
uint16_t get_nav_id(uint32_t stuff_id);

int signi(int x);
int dot(Vector2i a, Vector2i b);
int dir_to_dir_id(Vector2i dir);
Vector2i tile_id_to_val(uint8_t tile_id);
bool is_vals_mergeable(Vector2i val1, Vector2i val2);
bool is_ids_mergeable(uint8_t tile_id1, uint8_t tile_id2);
bool is_type_preserved(uint8_t src_type_id, uint8_t dest_type_id);
bool is_type_dominant(uint8_t src_type_id, uint8_t dest_type_id);
bool is_id_splittable(uint8_t tile_id);
uint8_t get_splitted_tile_id(uint8_t tile_id);
uint8_t get_merged_tile_id(uint8_t tile_id1, uint8_t tile_id2);
uint32_t get_merged_stuff_id(uint32_t src_stuff_id, uint32_t dest_stuff_id);

bool is_compatible(uint8_t type_id, uint8_t back_id);
bool is_navigable(Vector2i dir, uint16_t nav_id);

int get_dist_to_lv_edge(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir);
int get_slide_push_count(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir, bool check_back, bool check_nav, bool allow_enemy_annihilation_type_change, bool allow_other_type_change, bool allow_same_type_merge);
int get_split_push_count(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir, bool check_back, bool check_nav, bool allow_enemy_annihilation_type_change, bool allow_other_type_change, bool allow_same_type_merge);
int get_action_push_count(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector3i action, bool check_back, bool check_nav, bool allow_enemy_annihilation_type_change, bool allow_other_type_change, bool allow_same_type_merge);
void perform_slide(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir, int push_count);
bool try_slide(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir);
bool try_split(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir);

}


#endif