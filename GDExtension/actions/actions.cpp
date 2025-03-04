#include "actions.h"

using namespace std;
using namespace godot;


uint32_t make_tile_bits(uint8_t tile_id) {
    return tile_id << TILE_ID_BITPOS;
}

uint32_t make_type_bits(uint8_t type_id) {
    return type_id << TYPE_ID_BITPOS;
}

uint32_t make_back_bits(uint8_t back_id) {
    return back_id << BACK_ID_BITPOS;
}

uint32_t make_nav_bits(uint16_t nav_id) {
    return nav_id << NAV_ID_BITPOS;
}

uint32_t get_tile_bits(uint32_t stuff_id) {
    return stuff_id & TILE_ID_MASK;
}

uint32_t get_type_bits(uint32_t stuff_id) {
    return stuff_id & TYPE_ID_MASK;
}

uint32_t get_back_bits(uint32_t stuff_id) {
    return stuff_id & BACK_ID_MASK;
}

uint32_t get_nav_bits(uint32_t stuff_id) {
    return stuff_id & NAV_ID_MASK;
}

uint8_t get_tile_id(uint32_t stuff_id) {
    return get_tile_bits(stuff_id) >> TILE_ID_BITPOS;
}

uint8_t get_type_id(uint32_t stuff_id) {
    return get_type_bits(stuff_id) >> TYPE_ID_BITPOS;
}

uint8_t get_back_id(uint32_t stuff_id) {
    return get_back_bits(stuff_id) >> BACK_ID_BITPOS;
}

uint16_t get_nav_id(uint32_t stuff_id) {
    return get_nav_bits(stuff_id) >> NAV_ID_BITPOS;
}

int signi(int x) {
    return (x > 0) - (x < 0);
}

int dir_to_dir_id(Vector2i dir) {
    return 1.5 * dir.x - 0.5 * dir.y + 1.5;
}

Vector2i tile_id_to_val(uint8_t tile_id) {
    if (tile_id == TileId::ZERO) {
        return Vector2i(-1, -1);
    }
    int signed_incremented_pow = tile_id - TileId::ZERO;
    return Vector2i(abs(signed_incremented_pow) - 1, signi(signed_incremented_pow));
}

bool is_vals_mergeable(Vector2i val1, Vector2i val2) {
    if (val1.x == -1 or )
}

bool is_compatible(uint8_t type_id, uint8_t back_id) {
    if (B_EMPTY.find(back_id) != B_EMPTY.end()) {
        return true;
    }
    if (B_WALL_OR_BORDER.find(back_id) != B_WALL_OR_BORDER.end()) {
        return false;
    }
    if (back_id == BackId::MEMBRANE) {
        return type_id == TypeId::PLAYER;
    }

    // back_id is in B_SAVE_OR_GOAL
    return type_id == TypeId::PLAYER || type_id == TypeId::REGULAR;
}

bool is_navigable(Vector2i dir, uint16_t nav_id) {
    return (nav_id & (NAV_BIT_BLOCK << dir_to_dir_id(dir))) == 0;
}

bool is_ids_mergeable(uint8_t tile_id1, uint8_t tile_id2) {
    if (tile_id1 == TileId::EMPTY || tile_id2 == TileId::EMPTY) {
        return true;
    }
    Vector2i val1 = tile_id_to_val(tile_id1);
    Vector2i val2 = tile_id_to_val(tile_id2);
    return is_vals_mergeable(val1, val2);
}

// returns negative number if lv_pos is out of bounds in dir
int get_dist_to_lv_edge(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir) {
    if (dir == Vector2i(1, 0)) {
        return lv[0].size() - 1 - lv_pos.x;
    }
    if (dir == Vector2i(0, 1)) {
        return lv.size() - 1 - lv_pos.y;
    }
    if (dir == Vector2i(-1, 0)) {
        return lv_pos.x;
    }
    return lv_pos.y;
}

// assume pusher entity is the lv_pos tile
int get_slide_push_count(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir, bool allow_type_change, bool check_back, bool check_nav) {
    Vector2i curr_lv_pos = lv_pos;
    uint32_t curr_stuff_id = lv[curr_lv_pos.y][curr_lv_pos.x];
    uint8_t curr_tile_id = get_tile_id(curr_stuff_id);
    uint8_t src_type_id = get_type_id(curr_stuff_id);
    uint8_t curr_type_id = src_type_id;
    int push_count = 0;
    int nearest_merge_push_count = -1;
    
    while (push_count < tile_push_limits.at(src_type_id)) {
        uint8_t prev_type_id = curr_type_id;
        curr_lv_pos += dir;
        curr_stuff_id = lv[curr_lv_pos.y][curr_lv_pos.x];
        curr_type_id = get_type_id(curr_stuff_id);
        uint8_t curr_back_id = get_back_id(curr_stuff_id);

        if ((check_back && !is_compatible(prev_type_id, curr_back_id)) ||
        (check_nav && !is_navigable(dir, get_nav_id(curr_stuff_id))) ||
        push_weights.at(src_type_id) < slide_weights.at(curr_type_id)) {
            return nearest_merge_push_count;
        }

        uint8_t prev_tile_id = curr_tile_id;
        curr_tile_id = get_tile_id(curr_stuff_id);

        if is_ids_mergeable(prev_tile_id, curr_tile_id) {
            if (nearest_merge_push_count == -1) {
                nearest_merge_push_count = push_count;
            }
            if (curr_tile_id != TileId::ZERO || T_NONE_OR_REGULAR.find(curr_type_id) == T_NONE_OR_REGULAR.end()) {
                if (prev_tile_id == TileId::ZERO && curr_tile_id == TileId::EMPTY) {
                    return push_count; //bubble
                }
                return nearest_merge_push_count;
            }
        }

        if (push_count == tile_push_limits.at(src_type_id)) {
            return nearest_merge_push_count;
        }
        push_count += 1;
    }

    return -1;
}

bool try_slide(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir, bool allow_type_change) {
    int push_count = get_slide_push_count(dir, allow_type_change);
    if (push_count != -1) {
        shared_ptr<SASearchNode_t> m = node_pool.acquire<SASearchNode_t>();
        m->sanode = node_pool.acquire<SANode>();
        *(m->sanode) = SANode(*sanode);
        m->prev = static_pointer_cast<SASearchNode_t>(this->shared_from_this());
        m->prev_push_count = push_count;
        m->prune_backtrack(dir);
        m->sanode->perform_slide(dir, push_count);
        return m;
    }
    return nullptr;
}

bool try_split(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir, bool allow_type_change) {
    uint32_t src_sid = sanode->get_lv_sid(sanode->lv_pos);
    int src_pow = get_tile_pow(get_tile_id(src_sid));
    if (!is_pow_splittable(src_pow)) {
        return nullptr;
    }

    //halve src tile, try_slide, then (re)set its tile_id
    //splitted is new tile, splitter is old tile
    uint32_t untyped_split_sid = get_back_bits(src_sid) + get_splitted_tid(get_tile_id(src_sid));
    uint32_t splitted_sid = untyped_split_sid + get_type_bits(src_sid);
    sanode->set_lv_sid(sanode->lv_pos, splitted_sid);
    shared_ptr<SASearchNode_t> ans = try_slide(dir, allow_type_change);
    if (ans != nullptr) {
        //insert splitter tile
        uint32_t splitter_sid = untyped_split_sid + REGULAR_TYPE_BITS;
        ans->sanode->set_lv_sid(sanode->lv_pos, splitter_sid);
    }
    //reset src tile in this
    sanode->set_lv_sid(sanode->lv_pos, src_sid);

    return ans;
}