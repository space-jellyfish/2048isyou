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
            if (!get_slide_push_count(lv, curr_lv_pos, -dir, false, true, true) || !get_split_push_count(lv, curr_lv_pos, -dir, false, true, true)) {
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
        if (get_slide_push_count(lv, lv_pos, danger.escape_dir, false, true, true) != -1) {
            --danger.level;
            return Vector3i(danger.escape_dir.x, danger.escape_dir.y, ActionId::SLIDE);
        }
        if (get_split_push_count(lv, lv_pos, danger.escape_dir, false, true, true) != -1) {
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
                    if (get_action_push_count(lv, lv_pos, action, false, true, true) != -1) {
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