#include <godot_cpp/variant/utility_functions.hpp>
#include "actions.h"

using namespace std;
using namespace godot;


namespace actions {

uint8_t atlas_coords_to_tile_id(Vector2i tile_atlas_coords) {
    return tile_atlas_coords.x + 1;
}

uint8_t atlas_coords_to_type_id(Vector2i tile_atlas_coords) {
    return tile_atlas_coords.y + 1;
}

uint8_t atlas_coords_to_back_id(Vector2i back_atlas_coords) {
    return max(back_atlas_coords.x, 0);
}

uint16_t atlas_coords_to_nav_id(Vector2i nav_atlas_coords) {
    return nav_atlas_coords.x + 1;
}


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

uint32_t remove_tile_id(uint32_t stuff_id) {
    return stuff_id & TILE_ID_INVERTED_MASK;
}

uint32_t remove_type_id(uint32_t stuff_id) {
    return stuff_id & TYPE_ID_INVERTED_MASK;
}

uint32_t remove_back_id(uint32_t stuff_id) {
    return stuff_id & BACK_ID_INVERTED_MASK;
}

uint32_t remove_nav_id(uint32_t stuff_id) {
    return stuff_id & NAV_ID_INVERTED_MASK;
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

int dot(Vector2i a, Vector2i b) {
    return a.x * b.x + a.y * b.y;
}

int dir_to_dir_id(Vector2i dir) {
    return 1.5 * dir.x - 0.5 * dir.y + 1.5;
}

Vector2i tile_id_to_val(uint8_t tile_id) {
    if (tile_id == TileId::ZERO || tile_id == TileId::EMPTY) {
        return Vector2i(-1, -1);
    }
    int signed_incremented_pow = tile_id - TileId::ZERO;
    return Vector2i(abs(signed_incremented_pow) - 1, signi(signed_incremented_pow));
}

bool is_vals_mergeable(Vector2i val1, Vector2i val2) {
    if (val1.x == TilePow::VAL_ZERO || val2.x == TilePow::VAL_ZERO) {
        return true;
    }
    if (val1.x == val2.x && (val1.x < TilePow::MAX || val1.y != val2.y)) {
        return true;
    }
    return false;
}

bool is_ids_mergeable(uint8_t tile_id1, uint8_t tile_id2) {
    if (tile_id1 == TileId::EMPTY || tile_id2 == TileId::EMPTY) {
        return true;
    }
    Vector2i val1 = tile_id_to_val(tile_id1);
    Vector2i val2 = tile_id_to_val(tile_id2);
    return is_vals_mergeable(val1, val2);
}

bool is_type_preserved(uint8_t src_type_id, uint8_t dest_type_id) {
    return merge_priorities.at(src_type_id) >= merge_priorities.at(dest_type_id);
}

// equivalent to !is_type_preserved(dest_type_id, src_type_id)
bool is_type_dominant(uint8_t src_type_id, uint8_t dest_type_id) {
    return merge_priorities.at(src_type_id) > merge_priorities.at(dest_type_id);
}

bool is_id_splittable(uint8_t tile_id) {
    Vector2i val = tile_id_to_val(tile_id);
    return val.x > TilePow::VAL_ONE;
}

// return TileId::EMPTY if not splittable
uint8_t get_splitted_tile_id(uint8_t tile_id) {
    Vector2i val = tile_id_to_val(tile_id);
    if (val.x <= TilePow::VAL_ONE) {
        return TileId::EMPTY;
    }
    return tile_id - val.y;
}

// assume tile ids are mergeable
uint8_t get_merged_tile_id(uint8_t tile_id1, uint8_t tile_id2) {
    if (tile_id1 == TileId::EMPTY) {
        return tile_id2;
    }
    if (tile_id2 == TileId::EMPTY) {
        return tile_id1;
    }
    if (tile_id1 == TileId::ZERO) {
        return tile_id2;
    }
    if (tile_id2 == TileId::ZERO) {
        return tile_id1;
    }
    if (signi(tile_id1 - TileId::ZERO) != signi(tile_id2 - TileId::ZERO)) {
        return TileId::ZERO;
    }
    return tile_id1 + signi(tile_id1 - TileId::ZERO);
}

uint32_t get_merged_stuff_id(uint32_t src_stuff_id, uint32_t dest_stuff_id) {
    uint8_t src_tile_id = get_tile_id(src_stuff_id);
    uint8_t dest_tile_id = get_tile_id(dest_stuff_id);
    uint8_t src_type_id = get_type_id(src_stuff_id);
    uint8_t dest_type_id = get_type_id(dest_stuff_id);
    uint8_t merged_tile_id = get_merged_tile_id(src_tile_id, dest_tile_id);
    uint8_t merged_type_id = is_type_preserved(src_type_id, dest_type_id) ? src_type_id : dest_type_id;

    if (merged_tile_id == TileId::ZERO && T_KILLABLE_BY_ZEROING.find(merged_type_id) != T_KILLABLE_BY_ZEROING.end()) {
        merged_type_id = TypeId::REGULAR;
    }
    return remove_type_id(remove_tile_id(dest_stuff_id)) + make_type_bits(merged_type_id) + make_tile_bits(merged_tile_id);
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
// NOTE dist_to_lv_edge must be checked
// entity death includes both type change and merging into an entity of the same type
int get_slide_push_count(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir, bool check_back, bool check_nav, bool allow_enemy_annihilation_type_change, bool allow_other_type_change, bool allow_same_type_merge) {
    uint32_t src_stuff_id = lv[lv_pos.y][lv_pos.x];
    uint8_t src_type_id = get_type_id(src_stuff_id);
    Vector2i curr_lv_pos = lv_pos;
    uint32_t curr_stuff_id = src_stuff_id;
    uint8_t curr_tile_id = get_tile_id(curr_stuff_id);
    uint8_t curr_type_id = src_type_id;
    int push_count = 0;
    int nearest_merge_push_count = -1;
    int dist_to_lv_edge = get_dist_to_lv_edge(lv, lv_pos, dir);
    
    while (push_count <= min(tile_push_limits.at(src_type_id), dist_to_lv_edge - 1)) {
        uint8_t prev_type_id = curr_type_id;
        curr_lv_pos += dir;
        curr_stuff_id = lv[curr_lv_pos.y][curr_lv_pos.x];
        curr_type_id = get_type_id(curr_stuff_id);
        uint8_t curr_back_id = get_back_id(curr_stuff_id);

        if ((check_back && !is_compatible(prev_type_id, curr_back_id)) ||
        (check_nav && !is_navigable(dir, get_nav_id(curr_stuff_id)))) {
            return nearest_merge_push_count;
        }

        uint8_t prev_tile_id = curr_tile_id;
        curr_tile_id = get_tile_id(curr_stuff_id);

        if (is_ids_mergeable(prev_tile_id, curr_tile_id)) {
            // assume merge happens if curr_type_id is non-regular
            if (!push_count) {
                // check for type change
                if (!allow_enemy_annihilation_type_change || !allow_other_type_change) {
                    uint8_t merged_type_id = get_type_id(get_merged_stuff_id(src_stuff_id, curr_stuff_id));

                    if (merged_type_id != src_type_id) {
                        if (E_ENEMY.at(src_type_id).at(curr_type_id) && merged_type_id == TypeId::REGULAR) {
                            if (!allow_enemy_annihilation_type_change) {
                                return -1;
                            }
                        }
                        else {
                            if (!allow_other_type_change) {
                                return -1;
                            }
                        }
                    }
                }

                //check for same-type merge
                if (!allow_same_type_merge && curr_type_id == src_type_id) {
                    return -1;
                }
            }

            if (nearest_merge_push_count == -1) {
                nearest_merge_push_count = push_count;
            }
            if (curr_tile_id != TileId::ZERO || curr_type_id != TypeId::REGULAR) {
                if (prev_tile_id == TileId::ZERO && curr_tile_id == TileId::EMPTY) {
                    return push_count; //bubble
                }
                return nearest_merge_push_count;
            }
        }

        if (push_count == tile_push_limits.at(src_type_id) ||
        push_weights.at(src_type_id) < slide_weights.at(curr_type_id)) {
            return nearest_merge_push_count;
        }
        push_count += 1;
    }
    return -1;
}

int get_split_push_count(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir, bool check_back, bool check_nav, bool allow_enemy_annihilation_type_change, bool allow_other_type_change, bool allow_same_type_merge) {
    // check if split possible
    uint32_t src_stuff_id = lv[lv_pos.y][lv_pos.x];
    uint8_t src_tile_id = get_tile_id(src_stuff_id);
    uint8_t splitted_tile_id = get_splitted_tile_id(src_tile_id);
    if (splitted_tile_id == TileId::EMPTY) {
        return -1;
    }

    uint32_t splitted_stuff_id = remove_tile_id(src_stuff_id) + make_tile_bits(splitted_tile_id);
    lv[lv_pos.y][lv_pos.x] = splitted_stuff_id;
    int push_count = get_slide_push_count(lv, lv_pos, dir, check_back, check_nav, allow_enemy_annihilation_type_change, allow_other_type_change, allow_same_type_merge);
    lv[lv_pos.y][lv_pos.x] = src_stuff_id;
    return push_count;
}

int get_action_push_count(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector3i action, bool check_back, bool check_nav, bool allow_enemy_annihilation_type_change, bool allow_other_type_change, bool allow_same_type_merge) {
    Vector2i dir = Vector2i(action.x, action.y);
    switch (action.z) {
        case ActionId::SLIDE:
            return get_slide_push_count(lv, lv_pos, dir, check_back, check_nav, allow_enemy_annihilation_type_change, allow_other_type_change, allow_same_type_merge);
        case ActionId::SPLIT:
            return get_split_push_count(lv, lv_pos, dir, check_back, check_nav, allow_enemy_annihilation_type_change, allow_other_type_change, allow_same_type_merge);
        default:
            return -1;
    }
}

void perform_slide(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir, int push_count) {
    Vector2i merge_lv_pos = lv_pos + (push_count + 1) * dir;
    uint32_t merge_stuff_id = lv[merge_lv_pos.y][merge_lv_pos.x];
    Vector2i curr_lv_pos = merge_lv_pos;
    uint32_t curr_static_id = remove_type_id(remove_tile_id(merge_stuff_id));
    uint32_t result_stuff_id;

    for (int dist_to_merge = 0; dist_to_merge <= push_count; ++dist_to_merge) {
        Vector2i prev_lv_pos = curr_lv_pos - dir;
        uint32_t prev_stuff_id = lv[prev_lv_pos.y][prev_lv_pos.x];

        if (dist_to_merge) {
            // push
            result_stuff_id = curr_static_id + remove_back_id(remove_nav_id(prev_stuff_id));
        }
        else {
            // merge
            result_stuff_id = get_merged_stuff_id(prev_stuff_id, merge_stuff_id);
        }
        lv[curr_lv_pos.y][curr_lv_pos.x] = result_stuff_id;

        // update loop vars
        curr_lv_pos -= dir;
        curr_static_id = remove_type_id(remove_tile_id(prev_stuff_id));
    }

    // remove src tile
    lv[lv_pos.y][lv_pos.x] = remove_type_id(remove_tile_id(lv[lv_pos.y][lv_pos.x]));
}

bool try_slide(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir) {
    int push_count = get_slide_push_count(lv, lv_pos, dir, true, true, true, true, true);
    if (push_count != -1) {
        perform_slide(lv, lv_pos, dir, push_count);
        return true;
    }
    return false;
}

bool try_split(vector<vector<uint32_t>>& lv, Vector2i lv_pos, Vector2i dir) {
    // check if split possible
    uint32_t src_stuff_id = lv[lv_pos.y][lv_pos.x];
    uint8_t src_tile_id = get_tile_id(src_stuff_id);
    uint8_t splitted_tile_id = get_splitted_tile_id(src_tile_id);
    if (splitted_tile_id == TileId::EMPTY) {
        return false;
    }

    uint32_t splitted_stuff_id = remove_tile_id(src_stuff_id) + make_tile_bits(splitted_tile_id);
    lv[lv_pos.y][lv_pos.x] = splitted_stuff_id;
    bool initiated = try_slide(lv, lv_pos, dir);
    if (initiated) {
        uint8_t src_type_id = get_type_id(src_stuff_id);
        uint8_t splitter_type_id = (duplicate_upon_split.at(src_type_id)) ? src_type_id : TypeId::REGULAR;
        lv[lv_pos.y][lv_pos.x] = remove_type_id(splitted_stuff_id) + make_type_bits(splitter_type_id);
    }
    else {
        lv[lv_pos.y][lv_pos.x] = src_stuff_id;
    }
    return initiated;
}

}