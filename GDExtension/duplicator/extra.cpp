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