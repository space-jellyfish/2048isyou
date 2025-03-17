/*
ClassDB::bind_method(D_METHOD("test_gv"), &DuplicatorPathController::test_gv);

int DuplicatorPathController::test_gv() {
    Dictionary d = gv->get("LayerId");
    return d["TILE"];
}

int test_gv();


// updates danger_lv and danger_escape_dir
// check all four neighbors for tiles with higher merge priority, or other duplicators from which danger can be inherited
// danger_lv is set to DANGER_LV_MAX if adjacent to a higher-merge-priority tile, or neighbor.danger_lv - 1 if adjacent to another duplicator
// danger_escape_dir is set to point away from souce of highest danger_lv, or any one if there are multiple
// NOTE assumes each entity has unique merge_priority
void DuplicatorPathController::update_danger(Vector2i pos_t) {
    Dictionary type_enum = gv->get("TypeId");
    int type_id = type_enum["DUPLICATOR"];
    Dictionary merge_priorities = gv->get("merge_priorities");
    int merge_priority = merge_priorities[type_id];
    Array layer_mutexes = world->get("layer_mutexes");
    int tile_layer_id = static_cast<Dictionary>(gv->get("LayerId"))["TILE"];
    Array directions = static_cast<Dictionary>(gv->get("DIRECTIONS")).values();

    danger_lv = 0;

    for (int i = 0; i < directions.size(); ++i) {
        Vector2i dir = directions[i];
        Vector2i curr_pos_t = pos_t + dir;
        // ================ START CRITICAL SECTION ================
        Ref<Mutex> tile_mutex = layer_mutexes[tile_layer_id];
        tile_mutex->lock();
        int curr_type_id = world->call("get_type_id", curr_pos_t, false);
        Ref<RefCounted> curr_tile_entity = world->call("get_aligned_tile_entity", curr_type_id, curr_pos_t);
        tile_mutex->unlock();
        // ================ END CRITICAL SECTION ================
        int curr_merge_priority = merge_priorities[curr_type_id];

        if (curr_merge_priority > merge_priority) {
            danger_lv = DANGER_LV_MAX;
            danger_escape_dir = -dir;
            return;
        }
        else if (curr_type_id == type_id) {
            assert(curr_tile_entity != nullptr);
            assert(danger_lv != DANGER_LV_MAX);
            DuplicatorPathController* path_controller = RefCounted::cast_to<DuplicatorPathController>(curr_tile_entity->get("path_controller"));
            if (path_controller->danger_lv - 1 > danger_lv) {
                danger_lv = path_controller->danger_lv - 1;
                danger_escape_dir = path_controller->danger_escape_dir;
            }
        }
    }
}
*/

/*
int DuplicatorPathController::get_danger_lv() {
    return danger_lv;
}

Vector2i DuplicatorPathController::get_danger_escape_dir() {
    return danger_escape_dir;
}
*/

/*
    // seed random generator
    DuplicatorPathController() :
        generator(random_device{}()),
        distribution(0, 1)
    {}
*/

/*
void DuplicatorPathController::update_danger(vector<vector<uint32_t>>& lv, Vector2i lv_pos, unordered_map<Vector2i, Danger>& neighbors) {
    for (auto& [dir_id, dir] : DIRECTIONS) {
        auto neighbor_itr = neighbors.find(dir);

        if (neighbor_itr != neighbors.end()) {
            // neighbor is duplicator
            Danger neighbor_danger = (*neighbor_itr).second;
            if (neighbor_danger.level - 1 > danger.level) {
                danger.level = neighbor_danger.level - 1;
                danger.escape_dir = neighbor_danger.escape_dir;
            }
        }
        else {
            Vector2i curr_lv_pos = lv_pos + dir;
            // duplicator is safe if push_count is nonzero (not immediate merge where neighbor type_id is preserved)
            // lv width does not have to accommodate neighbor's tpl
            if (!get_slide_push_count(lv, curr_lv_pos, -dir, true, true, false) || !get_split_push_count(lv, curr_lv_pos, -dir, true, true, false)) {
                danger.level = DANGER_LV_MAX;
                danger.escape_dir = -dir;
                break;
            }
        }
    }

    // update neighbor dangers

}

*/

/*
    ClassDB::bind_method(D_METHOD("get_danger_lv"), &DuplicatorPathController::get_danger_lv);
    ClassDB::bind_method(D_METHOD("get_danger_escape_dir"), &DuplicatorPathController::get_danger_escape_dir);
*/

/*
bool DuplicatorPathController::EscapeAction::operator<(const EscapeAction& other) const {
    if (action.z != other.action.z) {
        return action.z == ActionId::SLIDE;
    }
    if (is_escape_dir != other.is_escape_dir) {
        return is_escape_dir;
    }
    if (resulting_power != other.resulting_power) {
        return resulting_power > other.resulting_power;
    }
    uniform_int_distribution<int> distribution{0, 1};
    return distribution(generator);
}

bool DuplicatorPathController::HuntAction::operator<(const HuntAction& other) const {
    if (action.z != other.action.z) {
        return action.z == ActionId::SPLIT;
    }
    if (resulting_power != other.resulting_power) {
        return resulting_power > other.resulting_power;
    }
    if (target_merge_priority != other.target_merge_priority) {
        return target_merge_priority < other.target_merge_priority;
    }
    uniform_int_distribution<int> distribution{0, 1};
    return distribution(generator);
}


    // escape has highest priority
    if (danger.level) {
        // try escape_dir
        if (get_slide_push_count(lv, lv_pos, danger.escape_dir, true, true, false) != -1) {
            --danger.level;
            return Vector3i(danger.escape_dir.x, danger.escape_dir.y, ActionId::SLIDE);
        }
        if (get_split_push_count(lv, lv_pos, danger.escape_dir, true, true, false) != -1) {
            --danger.level;
            return Vector3i(danger.escape_dir.x, danger.escape_dir.y, ActionId::SPLIT);
        }

        // try dirs perpendicular to escape_dir
        uniform_int_distribution<int> distribution{0, 1};
        bool rand_bool = distribution(generator);

        for (int action_id : {ActionId::SLIDE, ActionId::SPLIT}) {
            for (const pair<int, Vector2i>& dir_entry : DIRECTIONS) {
                Vector2i dir = dir_entry.second;

                if (!dot(danger.escape_dir, dir)) {
                    if (rand_bool) {
                        dir *= -1;
                    }
                    Vector3i action = Vector3i(dir.x, dir.y, action_id);
                    if (get_action_push_count(lv, lv_pos, action, true, true, false) != -1) {
                        --danger.level;
                        return action;
                    }
                }
            }
        }

        // wait
        // NOTE there is rare case where if dominant tile is on top of duplicator membrane and split-mergeable,
        // sliding in -escape_dir can be a good move by pushing dominant tile out
        // ignore this case since duplicator shouldn't be that intelligent anyway
        return Vector3i(danger.escape_dir.x, danger.escape_dir.y, ActionId::NONE);
    }
*/

/*
                // check for type change
                if ((!allow_type_change || !allow_entity_death) && get_type_id(get_merged_stuff_id(src_stuff_id, curr_stuff_id)) != src_type_id) {
                    return -1;
                }
                //check for entity death via same-type merge
                if (!allow_entity_death && curr_type_id == src_type_id) {
                    return -1;
                }

const unordered_set<uint8_t> T_ENEMY = {TypeId::DUPLICATOR, TypeId::HOSTILE, TypeId::VOID, TypeId::SQUID};

    // hunt type-dominated, non-regular, no-type-change-mergeable neighbor
    // (don't die (become TileId::ZERO) for the hunt)
    vector<HuntAction> hunt_actions;

    for (auto& [dir_id, dir] : DIRECTIONS) {
        Vector2i curr_lv_pos = lv_pos + dir;
        uint32_t curr_stuff_id = lv[curr_lv_pos.y][curr_lv_pos.x];
        uint8_t curr_type_id = actions::get_type_id(curr_stuff_id);

        if (curr_type_id != TypeId::REGULAR && is_type_dominant(TypeId::DUPLICATOR, curr_type_id)) {

            for (int action_id : {ActionId::SLIDE, ActionId::SPLIT}) {
                Vector3i action = Vector3i(dir.x, dir.y, action_id);

                if (!get_action_push_count(lv, lv_pos, action, true, true, false)) {
                    // get power resulting from merge
                    int action_src_tile_id = (action.z == ActionId::SPLIT) ? get_splitted_tile_id(src_tile_id) : src_tile_id;
                    int dest_tile_id = actions::get_tile_id(curr_stuff_id);
                    int merged_tile_id = get_merged_tile_id(action_src_tile_id, dest_tile_id);
                    int resulting_power = tile_id_to_val(merged_tile_id).x;

                    // get target merge priority
                    int target_merge_priority = merge_priorities.at(curr_type_id);

                    hunt_actions.emplace_back(action, resulting_power, target_merge_priority);
                }
            }
        }
    }

    if (!hunt_actions.empty()) {
        sort(hunt_actions.begin(), hunt_actions.end());
        return hunt_actions[0].action;
    }

    struct HuntAction {
        int weight = 0;
        Vector3i action;
        int resulting_power;
        int target_merge_priority;

        HuntAction(Vector3i p_action, int p_resulting_power, int p_target_merge_priority);
        bool operator<(const HuntAction& other) const;
    };

// NOTE change of plan, interpret "else" as "to a lesser degree"
// prefer slide over split (always)
// else prefer escape dir
// else prefer higher resulting power
// else prefer random
DuplicatorPathController::EscapeAction::EscapeAction(Vector3i p_action, int p_dot_escape_dir, int p_resulting_power) :
    action(p_action),
    dot_escape_dir(p_dot_escape_dir),
    resulting_power(p_resulting_power)
{
    if (dot_escape_dir == -1) {
        weight -= 1000;
    }
    else {
        weight += (action.z == ActionId::SLIDE) * 1000;
        weight += dot_escape_dir * 11;
    }
    uniform_int_distribution<int> dist(0, 20);
    weight += dist(generator);
}

bool DuplicatorPathController::EscapeAction::operator<(const EscapeAction& other) const {
    int resulting_power_bonus = signi(resulting_power - other.resulting_power) * 7;
    int temp_weight = weight + resulting_power_bonus;
    
    if (temp_weight == other.weight) {
        uniform_int_distribution<int> dist(0, 1);
        return dist(generator);
    }
    return temp_weight > other.weight;
}

// prefer split over slide
// else prefer higher resulting power
// else prefer lower merge priority neighbor
// else prefer random
DuplicatorPathController::HuntAction::HuntAction(Vector3i p_action, int p_resulting_power, int p_target_merge_priority) :
    action(p_action),
    resulting_power(p_resulting_power),
    target_merge_priority(p_target_merge_priority)
{
    weight += (action.z == ActionId::SPLIT) * 10;
    uniform_int_distribution<int> dist(0, 25);
    weight += dist(generator);
}

bool DuplicatorPathController::HuntAction::operator<(const HuntAction& other) const {
    int resulting_power_bonus = signi(resulting_power - other.resulting_power) * 8;
    int merge_priority_bonus = signi(target_merge_priority - other.target_merge_priority) * 5;
    int temp_weight = weight + resulting_power_bonus + merge_priority_bonus;

    if (temp_weight == other.weight) {
        uniform_int_distribution<int> dist(0, 1);
        return dist(generator);
    }
    return temp_weight > other.weight;
}

    struct EscapeAction {
        int weight = 0;
        Vector3i action;
        int dot_escape_dir;
        int resulting_power;
        
        EscapeAction(Vector3i p_action, int p_dot_escape_dir, int p_resulting_power);
        bool operator<(const EscapeAction& other) const;
    };

    if (temp_danger.level) {
        vector<EscapeAction> escape_actions;

        // check all dirs bc there is rare case where if dominant tile is on top of duplicator membrane and split-mergeable,
        // sliding in -escape_dir can be a good move by pushing dominant tile out
        for (auto [dir_id, dir] : DIRECTIONS) {
            Vector2i curr_lv_pos = lv_pos + dir;
            uint32_t curr_stuff_id = lv[curr_lv_pos.y][curr_lv_pos.x];
            int dot_escape_dir = dot(dir, temp_danger.escape_dir);

            for (int action_id : {ActionId::SLIDE, ActionId::SPLIT}) {
                Vector3i action = Vector3i(dir.x, dir.y, action_id);
                // allow merging into friendlies when escaping
                // allow annihilation when escaping
                // but don't voluntarily initiate non-annihilation self-death
                int action_push_count = get_action_push_count(lv, lv_pos, action, true, true, true, false, true);

                if (action_push_count != -1) {
                    //find resulting power
                    int resulting_power;
                    if (!action_push_count) {
                        resulting_power = src_power;
                    }
                    else {
                        int action_src_tile_id = (action.z == ActionId::SPLIT) ? get_splitted_tile_id(src_tile_id) : src_tile_id;
                        int dest_tile_id = actions::get_tile_id(curr_stuff_id);
                        int merged_tile_id = get_merged_tile_id(action_src_tile_id, dest_tile_id);
                        resulting_power = tile_id_to_val(merged_tile_id).x;
                    }

                    escape_actions.emplace_back(action, dot_escape_dir, resulting_power);
                }
            }
        }

        if (!escape_actions.empty()) {
            sort(escape_actions.begin(), escape_actions.end());
            return escape_actions[0].action;
        }

        // wait
        return Vector3i(0, 0, ActionId::NONE);
    }
*/

/*
DuplicatorPathController::DuplicatorPathController() {
    if (Engine::get_singleton()->is_editor_hint()) {
        set_process_mode(Node::ProcessMode::PROCESS_MODE_DISABLED);
    }
}
*/

/*
        assert(curr_lv_pos.y >= 0 && curr_lv_pos.y < lv.size());
        assert(curr_lv_pos.x >= 0 && curr_lv_pos.x < lv[0].size());

*/

// decrement danger level if move succeeded and resulting entity is duplicator

/*
uint8_t atlas_coords_to_back_id(Vector2i back_atlas_coords, bool block_ungenerated) {
    if (block_ungenerated && back_atlas_coords.x == -1) {
        return BackId::BORDER_SQUARE;
    }
    return max(back_atlas_coords.x, 0);
}
*/