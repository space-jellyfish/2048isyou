#tilemap-based for better performance
#-Vector2i.ONE indicates cell hasn't been generated yet
#coords indicates atlas_coords from tileset
#empty atlas_coords indicates cell is empty
#val indicates Vector2i(pow, sign)
# save tile if it's not grid-aligned
class_name World
extends Node2D

@onready var game:Node2D = $"/root/Game";
var packed_tile:PackedScene = preload("res://Objects/TileForTilemap.tscn");
var tile_sheet:CompressedTexture2D = preload("res://Sprites/Sheets/tile_sheet.png");

var tile_noise = FastNoiseLite.new();
var wall_noise = FastNoiseLite.new();

var loaded_pos_t_min:Vector2i;
var loaded_pos_t_max:Vector2i; #inclusive

var resolution:Vector2;
var half_resolution:Vector2;

var entities:Dictionary; #Dictionary[EntityId, Dictionary[pos_t or body, Entity]]
var entities_with_curr_frame_premoves:Dictionary; #[EntityId, Dictionary[Entity, DONT_CARE]]
var premove_callback_upcoming:bool = false;

#for enemy intel
@export var initial_player_pos_t:Vector2i = Vector2i.ZERO; #used for enemy path planning; approx when player isn't aligned
var player:Entity; #alias for entities[GV.EntityId.PLAYER].get_values()[0]
var is_player_alive:bool = true;

#for input repeat delay
var atimer:AccelTimer = AccelTimer.new();

#for animation and collision shapes
#Vector3i(last_saved_pos_t.x, last_saved_pos_t.y, ZId) -> TileForTilemap
#last_saved_pos_t is pos_t stored in TileMap that is reverted to if game crashes (or force quit)
var tile_pool:Array[TileForTilemap];

	
func _ready():
	set_level_name();
	
	if not GV.current_level_from_save: #first time entering lv
		#print("set initial SVID to ", GV.savepoint_id);
		GV.level_initial_savepoint_ids[GV.current_level_index] = GV.savepoint_id;
	
	#init entities
	for entity_id in GV.EntityId.values():
		entities[entity_id] = Dictionary();
	
	player = Entity.new(self, null, GV.EntityId.PLAYER, initial_player_pos_t);
	add_entity(GV.EntityId.PLAYER, initial_player_pos_t, player);
	
	#init entities_with_curr_frame_premoves
	for entity_id in GV.EntityId.values():
		entities_with_curr_frame_premoves[entity_id] = Dictionary();
	
	#init trackingCam stuff
	$TrackingCam.set_target_entity(player, false);
	$TrackingCam.set_zoom_and_area_scale(GV.VIEWPORT_RESOLUTION.x / GV.tracking_cam_resolution.x);

func add_curr_frame_premove_entity(entity:Entity):
	#add to entities_with_curr_frame_premoves
	entities_with_curr_frame_premoves[entity.entity_id][entity] = true;
	
	#callback
	if not premove_callback_upcoming:
		call_deferred("try_curr_frame_premoves");
		premove_callback_upcoming = true;

# call deferred so that premove priority is respected
func try_curr_frame_premoves():
	for entity_id in GV.ENTITY_IDS_DECREASING_PREMOVE_PRIORITY:
		var typed_entities:Dictionary = entities_with_curr_frame_premoves[entity_id];
		
		for entity in typed_entities.keys():
			entity.try_curr_frame_premoves();
			
			# always remove entity after trying premove
			# if it fails, premoves will be cleared
			# if it succeeds, entity will be busy
			typed_entities.erase(entity);
				
	premove_callback_upcoming = false;

func viewport_to_tile_pos(viewport_pos:Vector2) -> Vector2i:
	var local_pos:Vector2 = $TrackingCam.position - GV.VIEWPORT_RESOLUTION/2 + viewport_pos;
	return get_node("Cells").local_to_map(local_pos);
	
func get_pooled_tile(pusher_entity_id:int, transit_id:int, pos_t:Vector2i, dir:Vector2i, target_dist_t:int, old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, back_tile:TileForTilemap, is_splitted:bool, is_merging:bool, governor_tile:TileForTilemap) -> TileForTilemap:
	var tile:TileForTilemap;
	if not tile_pool.is_empty():
		tile = tile_pool.pop_back();
		tile.collision_shape.disabled = false;
	else:
		tile = packed_tile.instantiate();
	
	tile.initialize(self, pusher_entity_id, transit_id, pos_t, dir, target_dist_t, tile_sheet, old_atlas_coords, new_atlas_coords, back_tile, is_splitted, is_merging, governor_tile);
	return tile;

func return_pooled_tile(tile:TileForTilemap):
	#assert(not tile.is_inside_tree());
	#assert(tile.prev_sprite == null);
	#assert(tile.curr_sprite == null);
	#assert(tile.move_controller == null);
	#assert(tile.back_tile == null);
	#assert(tile.front_tile == null);

	$TransitTiles.remove_child(tile);
	if tile.curr_sprite:
		tile.curr_sprite.queue_free();
		tile.curr_sprite = null;
	if tile.prev_sprite:
		tile.prev_sprite.queue_free();
		tile.prev_sprite = null;
	tile.move_controller = null;
	tile.back_tile = null;
	tile.front_tile = null;
	tile.merger_tile = null;
		
	for collision_id in GV.CollisionId.values():
		tile.set_collision_layer_value(collision_id, false);
	
	for collision_id in GV.CollisionId.values():
		tile.set_collision_mask_value(collision_id, false);
	
	# disabling collision shape fixes a rare collision bug where pusher tile teleports to an adjacent cell
	# so this line is staying
	tile.collision_shape.disabled = true;
	# wait for collision shape to update
	await get_tree().physics_frame;
	
	tile_pool.append(tile);

func set_level_name():
	if has_node("LevelName"):
		game.current_level_name = $LevelName;
		game.current_level_name.modulate.a = 0;
	else:
		game.current_level_name = null;

func save():
	var save_dict = {
		
	};

func _exit_tree():
	#print_orphan_nodes();
	pass;

func is_world_border(pos_t:Vector2i) -> bool:
	if pos_t.x == GV.BORDER_MIN_POS_T.x or pos_t.x == GV.BORDER_MAX_POS_T.x:
		if pos_t.y >= GV.BORDER_MIN_POS_T.y and pos_t.y <= GV.BORDER_MAX_POS_T.y:
			return true;
	if pos_t.y == GV.BORDER_MIN_POS_T.y or pos_t.y == GV.BORDER_MAX_POS_T.y:
		if pos_t.x >= GV.BORDER_MIN_POS_T.x and pos_t.x <= GV.BORDER_MAX_POS_T.x:
			return true;
	return false;

func on_copy():
	if not GV.abilities["copy"]:
		return;
	
	#declare and init level array
	var level_array = [];
#	for row_itr in resolution_t.y:
#		var row = [];
#		row.resize(resolution_t.x);
#		row.fill(GV.TileId.EMPTY);
#		level_array.push_back(row);
	
	#add to clipboard
	DisplayServer.clipboard_set(str(level_array));
	
	return level_array;

#use tilemap, don't unload manually
func _on_camera_transition_started(target:Vector2, track_dir:Vector2i):
	var temp_pos_t_min:Vector2i = loaded_pos_t_min;
	var temp_pos_t_max:Vector2i = loaded_pos_t_max;
	if track_dir.x:
		var load_min_x:float = target.x - half_resolution.x - (GV.TILE_LOAD_BUFFER if track_dir.x < 0 else GV.TILE_UNLOAD_BUFFER);
		var load_max_x:float = target.x + half_resolution.x + (GV.TILE_LOAD_BUFFER if track_dir.x > 0 else GV.TILE_UNLOAD_BUFFER);
		temp_pos_t_min.x = GV.world_to_xt(load_min_x);
		temp_pos_t_max.x = GV.world_to_xt(load_max_x);
	if track_dir.y:
		var load_min_y:float = target.y - half_resolution.y - (GV.TILE_LOAD_BUFFER if track_dir.y < 0 else GV.TILE_UNLOAD_BUFFER);
		var load_max_y:float = target.y + half_resolution.y + (GV.TILE_LOAD_BUFFER if track_dir.y > 0 else GV.TILE_UNLOAD_BUFFER);
		temp_pos_t_min.y = GV.world_to_xt(load_min_y);
		temp_pos_t_max.y = GV.world_to_xt(load_max_y);
	update_map(loaded_pos_t_min, loaded_pos_t_max, temp_pos_t_min, temp_pos_t_max);
	loaded_pos_t_min = temp_pos_t_min;
	loaded_pos_t_max = temp_pos_t_max;
	
func update_map(old_pos_t_min:Vector2i, old_pos_t_max:Vector2i, new_pos_t_min:Vector2i, new_pos_t_max:Vector2i):
	var overlap_min:Vector2i = Vector2i(maxi(old_pos_t_min.x, new_pos_t_min.x), maxi(old_pos_t_min.y, new_pos_t_min.y));
	var overlap_max:Vector2i = Vector2i(mini(old_pos_t_max.x, new_pos_t_max.x), mini(old_pos_t_max.y, new_pos_t_max.y));
	if overlap_min.x > overlap_max.x or overlap_min.y > overlap_max.y: #no overlap
		load_rect(new_pos_t_min, new_pos_t_max);
	else:
		#new rect
		load_rect(new_pos_t_min, Vector2i(new_pos_t_max.x, overlap_min.y - 1));
		load_rect(Vector2i(new_pos_t_min.x, overlap_min.y), Vector2i(overlap_min.x - 1, overlap_max.y));
		load_rect(Vector2i(overlap_max.x + 1, overlap_min.y), Vector2i(new_pos_t_max.x, overlap_max.y));
		load_rect(Vector2i(new_pos_t_min.x, overlap_max.y + 1), new_pos_t_max);

func load_rect(pos_t_min:Vector2i, pos_t_max:Vector2i):
	for ty in range(pos_t_min.y, pos_t_max.y+1):
		for tx in range(pos_t_min.x, pos_t_max.x+1):
			var pos_t:Vector2i = Vector2i(tx, ty);
			generate_cell(pos_t);

func generate_cell(pos_t:Vector2i):
	if get_atlas_coords(GV.LayerId.BACK, pos_t) != -Vector2i.ONE:
		#once generated, tile may return to -Vector2i.ONE, so use BackId to mark generated cells
		return; #cell was previously generated
	if is_world_border(pos_t):
		set_atlas_coords(GV.LayerId.BACK, pos_t, Vector2i(GV.BackId.BORDER_SQUARE, 0));
		return;
	if pos_t == initial_player_pos_t:
		set_atlas_coords(GV.LayerId.TILE, pos_t, Vector2i(GV.TileId.ZERO - 1, GV.TypeId.PLAYER));
		set_atlas_coords(GV.LayerId.BACK, pos_t, Vector2i(GV.BackId.EMPTY, 0)); #to mark as generated
		#set_atlas_coords(GV.LayerId.BACK, player_pos_t, Vector2i(GV.BackId.MEMBRANE, 0));
		return;
	
	#back
	var n_wall:float = clamp(wall_noise.get_noise_2d(pos_t.x, pos_t.y), -1, 1); #[-1, 1]
	if absf(n_wall) < 0.009:
		set_atlas_coords(GV.LayerId.BACK, pos_t, Vector2i(GV.BackId.BLACK_WALL, 0));
		return;
	if absf(n_wall) < 0.02:
		set_atlas_coords(GV.LayerId.BACK, pos_t, Vector2i(GV.BackId.MEMBRANE, 0));
		return;

	#tile
	var n_tile:float = clamp(tile_noise.get_noise_2d(pos_t.x, pos_t.y), -1, 1); #[-1, 1]
	var ssign:int = int(signf(n_tile));
	n_tile = pow(absf(n_tile), 1); #[0, 1]; use power > 1 to bias towards 0
	var power:int = GV.TILE_GEN_POW_MAX if (n_tile == 1.0) else int((GV.TILE_GEN_POW_MAX + 2) * n_tile) - 1;
	var tile_id:int = GV.tile_val_to_id(power, ssign);
	
	#type
	var type:int = GV.TypeId.REGULAR;
	var n_type:float = randf();
	if n_type < GV.P_GEN_INVINCIBLE:
		type = GV.TypeId.INVINCIBLE;
	elif n_type < GV.P_GEN_HOSTILE:
		type = GV.TypeId.HOSTILE;
	
	set_atlas_coords(GV.LayerId.TILE, pos_t, Vector2i(tile_id-1, type));
	set_atlas_coords(GV.LayerId.BACK, pos_t, Vector2i(GV.BackId.EMPTY, 0)); #to mark as generated

func get_event_dir(event:InputEventKey) -> Vector2i:
	if event.keycode in [KEY_W, KEY_UP]:
		return GV.directions["up"];
	if event.keycode in [KEY_S, KEY_DOWN]:
		return GV.directions["down"];
	if event.keycode in [KEY_A, KEY_LEFT]:
		return GV.directions["left"];
	if event.keycode in [KEY_D, KEY_RIGHT]:
		return GV.directions["right"];
	return Vector2i.ZERO;

func update_last_input_premove(event:InputEventKey, action_id:int):
	var dir:Vector2i = get_event_dir(event);
	if dir != Vector2i.ZERO:
		var premove = Premove.new(player, dir, action_id);
		player.add_premove(premove);

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.is_command_or_control_pressed():
			update_last_input_premove(event, GV.ActionId.SPLIT);
		elif event.shift_pressed:
			update_last_input_premove(event, GV.ActionId.SHIFT);
		else:
			update_last_input_premove(event, GV.ActionId.SLIDE);

func get_atlas_coords(layer_id:int, pos_t:Vector2i) -> Vector2i:
	return $Cells.get_cell_atlas_coords(layer_id, pos_t);

func set_atlas_coords(layer_id:int, pos_t:Vector2i, coords:Vector2i):
	$Cells.set_cell(layer_id, pos_t, layer_id, coords);

func atlas_coords_to_tile_id(tile_atlas_coords:Vector2i):
	return tile_atlas_coords.x + 1;

func atlas_coords_to_type_id(tile_atlas_coords:Vector2i):
	return GV.TypeId.REGULAR if tile_atlas_coords.y == -1 else tile_atlas_coords.y;

func atlas_coords_to_back_id(back_atlas_coords:Vector2i):
	return maxi(back_atlas_coords.x, 0);
	
func get_tile_id(pos_t:Vector2i):
	return atlas_coords_to_tile_id(get_atlas_coords(GV.LayerId.TILE, pos_t));

func get_type_id(pos_t:Vector2i):
	var atlas_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, pos_t);
	return atlas_coords_to_type_id(atlas_coords);

func get_back_id(pos_t:Vector2i):
	return atlas_coords_to_back_id(get_atlas_coords(GV.LayerId.BACK, pos_t));

func is_tile(pos_t:Vector2i):
	return get_tile_id(pos_t) != 0;

func is_vals_mergeable(pow1:int, sign1:int, pow2:int, sign2:int):
	if pow1 == -1 or pow2 == -1:
		return true;
	if pow1 == pow2 and (pow1 < GV.TILE_POW_MAX or sign1 != sign2):
		return true;
	return false;

func is_ids_mergeable(tile_id1:int, tile_id2:int):
	if tile_id1 == 0 or tile_id2 == 0: #either cell empty
		return true;
	var val1:Vector2i = GV.id_to_tile_val(tile_id1);
	var val2:Vector2i = GV.id_to_tile_val(tile_id2);
	return is_vals_mergeable(val1.x, val1.y, val2.x, val2.y);

func is_id_splittable(tile_id:int):
	var val:Vector2i = GV.id_to_tile_val(tile_id);
	return not tile_id == GV.TileId.EMPTY and val.x > 0;

func is_pow_splittable(pow:int):
	return pow > 0;

#return -Vector2i.ONE if not splittable
func get_splitted_tile_atlas_coords(atlas_coords:Vector2i, keep_type:bool = true):
	var tile_val:Vector2i = GV.id_to_tile_val(atlas_coords.x + 1);
	if not is_pow_splittable(tile_val.x):
		return -Vector2i.ONE;
	return Vector2i(atlas_coords.x - tile_val.y, atlas_coords.y if keep_type else GV.TypeId.REGULAR);

func get_doubled_tile_atlas_coords(atlas_coords:Vector2i, keep_type:bool = true):
	var tile_id:int = atlas_coords_to_tile_id(atlas_coords);
	var tile_val:Vector2i = GV.id_to_tile_val(tile_id);
	assert(tile_val.x < GV.TILE_POW_MAX);
	
	if tile_id == GV.TileId.ZERO:
		return atlas_coords;
	return Vector2i(atlas_coords.x + tile_val.y, atlas_coords.y if keep_type else GV.TypeId.REGULAR);

func is_compatible(type_id:int, back_id:int):
	if back_id in GV.B_EMPTY:
		return true;
	if back_id in GV.B_WALL_OR_BORDER:
		return false;
	if back_id == GV.BackId.MEMBRANE:
		return type_id == GV.TypeId.PLAYER;
	#back_id in GV.B_SAVE_OR_GOAL
	return type_id == GV.TypeId.PLAYER or type_id == GV.TypeId.REGULAR;

#-1 if slide not possible
#assume src_pos_t is stable
func get_slide_push_count(src_pos_t:Vector2i, dir:Vector2i):
	var curr_pos_t:Vector2i = src_pos_t;
	var curr_tile_id:int = get_tile_id(src_pos_t);
	var src_type_id:int = get_type_id(src_pos_t);
	var curr_type_id:int = src_type_id;
	var push_count:int = 0;
	var nearest_merge_push_count:int = -1;
	
	while push_count <= GV.tile_push_limits[src_type_id]:
		#check for obstruction
		var prev_type_id:int = curr_type_id;
		curr_pos_t += dir;
		curr_type_id = get_type_id(curr_pos_t);
		var curr_back_id:int = get_back_id(curr_pos_t);
		#if is_immediate_collision(dir, get_collision_id(curr_pos_t)) or \
		if not is_compatible(prev_type_id, curr_back_id) or \
			(push_count > 0 and src_type_id in GV.T_ENEMY and curr_type_id == GV.TypeId.PLAYER):
			return nearest_merge_push_count;
		
		#push/merge logic
		var prev_tile_id:int = curr_tile_id;
		curr_tile_id = get_tile_id(curr_pos_t);
		
		if is_ids_mergeable(prev_tile_id, curr_tile_id):
			if nearest_merge_push_count == -1:
				nearest_merge_push_count = push_count;
			if curr_tile_id != GV.TileId.ZERO or curr_type_id != GV.TypeId.REGULAR:
				if prev_tile_id == GV.TileId.ZERO and curr_tile_id == GV.TileId.EMPTY:
					return push_count; #bubble
				return nearest_merge_push_count;
		
		if push_count == GV.tile_push_limits[src_type_id]:
			return nearest_merge_push_count;
		push_count += 1;
	return -1;

func get_tile_type_merge_priority(type_id:int):
	return GV.merge_priorities[type_id];

#assume tile ids are mergeable
func get_merged_tile_id(tile_id1:int, tile_id2:int):
	if tile_id1 == GV.TileId.EMPTY:
		return tile_id2;
	if tile_id2 == GV.TileId.EMPTY:
		return tile_id1;
	if tile_id1 == GV.TileId.ZERO:
		return tile_id2;
	if tile_id2 == GV.TileId.ZERO:
		return tile_id1;
	if sign(tile_id1 - GV.TileId.ZERO) != sign(tile_id2 - GV.TileId.ZERO):
		return GV.TileId.ZERO;
	return tile_id1 + sign(tile_id1 - GV.TileId.ZERO);

#assume at most one is -Vector2i.ONE
func get_merged_atlas_coords(coords1:Vector2i, coords2:Vector2i):
	var atlas_y:int = coords1.y if get_tile_type_merge_priority(coords1.y) > get_tile_type_merge_priority(coords2.y) else coords2.y;
	var atlas_x:int = get_merged_tile_id(coords1.x + 1, coords2.x + 1) - 1;
	#hostile death
	if atlas_x == GV.TileId.ZERO - 1 and atlas_y == GV.TypeId.HOSTILE:
		atlas_y = GV.TypeId.REGULAR;
	assert(atlas_y != -1 && atlas_x != -1);
	return Vector2i(atlas_x, atlas_y);

#used for shift speed calculation
#assume src_pos_t stable
func get_shift_target_dist(src_pos_t:Vector2i, dir:Vector2i) -> int:
	var max_distance:int = GV.max_shift_dists[get_type_id(src_pos_t)];
	var next_pos_t:Vector2i = src_pos_t + dir;
	var distance:int = 0;
	var src_type_id:int = get_type_id(src_pos_t);

	#while distance < max_distance and not is_immediate_collision(dir, get_collision_id(next_pos_t)) and is_compatible(src_type_id, get_back_id(next_pos_t)) and not is_tile(next_pos_t):
	while distance < max_distance and is_compatible(src_type_id, get_back_id(next_pos_t)) and not is_tile(next_pos_t):
		distance += 1;
		next_pos_t += dir;
	return distance;

# returns true if slide is initiated
# if is_splitted, assume atlas_coord at pos_t is already splitted with keep_type = true
func try_slide(pusher_entity_id:int, tile_entity:Entity, dir:Vector2i, is_splitted:bool=false, unsplit_atlas_coords=Vector2i.ZERO) -> bool:
	if tile_entity.body:
		assert(tile_entity.body is TileForTilemap);
		tile_entity.body.move_controller = TileForTilemapSlideController.new(tile_entity.body, dir);
		return true;
	if not is_tile(tile_entity.pos_t): # moving due to another entity
		return false;
	
	var push_count:int = get_slide_push_count(tile_entity.pos_t, dir);
	if push_count != -1:
		# start animation
		animate_slide(pusher_entity_id, tile_entity.pos_t, dir, push_count, is_splitted, unsplit_atlas_coords);
			
		return true;
	return false;

func try_split(pusher_entity_id:int, tile_entity:Entity, dir:Vector2i) -> bool:
	#if not tile_entity.is_busy and tile_entity.body:
	if tile_entity.body:
		assert(tile_entity.body is TileForTilemap);
		game.show_message(GV.MessageId.SPLIT_NA);
		return false;
	if not is_tile(tile_entity.pos_t):
		return false;
	
	#check if split possible
	var src_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, tile_entity.pos_t);
	var splitted_coords:Vector2i = get_splitted_tile_atlas_coords(src_coords);
	if splitted_coords == -Vector2i.ONE:
		return false;
	
	# Slide finishes before split animation, so splitting tile can safely switch from TileForTilemap to Tilemap
	# once split animation finishes (without worrying about the slide bouncing)
	# set splitted coord for try_slide().get_slide_push_count() (and try_slide() does not have to calculate it again)
	# try_slide() will add parent_atlas_coords at src_pos_t if it initiates
	set_atlas_coords(GV.LayerId.TILE, tile_entity.pos_t, splitted_coords);
	var initiated:bool = try_slide(pusher_entity_id, tile_entity, dir, true, src_coords);
	if not initiated:
		#reset src coords
		set_atlas_coords(GV.LayerId.TILE, tile_entity.pos_t, src_coords);
	return initiated;

#update player_pos_t
func try_shift(pusher_entity_id:int, tile_entity:Entity, dir:Vector2i) -> bool:
	if tile_entity.body:
		assert(tile_entity.body is TileForTilemap);
		game.show_message(GV.MessageId.SHIFT_NA);
		return false;
	if not is_tile(tile_entity.pos_t):
		return false;
	
	var target_distance:int = get_shift_target_dist(tile_entity.pos_t, dir);
	if target_distance:
		#update tile_id and player stats during animation
		animate_shift(pusher_entity_id, tile_entity.pos_t, dir, target_distance);
		
		return true;
	return false;

func get_entity(entity_id:int, key:Variant):
	return entities[entity_id].get(key);

func remove_entity(entity_id:int, key:Variant):
	entities[entity_id].erase(key);

func add_entity(entity_id:int, key:Variant, entity:Entity):
	entities[entity_id][key] = entity;

# erase cells and initialize transit_tiles
# tile with TransitId.MERGE is created but doesn't start animating yet
# sliding (governor) tiles are added before splitting/merging (governed) tiles,
# so by tree order, position/remaining_dist is updated before SpriteAnimator.step()
# update affected entities
# NOTE problem: collision persists after clearing TileMap cell
# add_child via call_deferred doesn't work bc it's already in idle time so the tiles still get added immediately
# add tile via await get_tree().physics_frame doesn't work bc tile might not exist during render
func animate_slide(pusher_entity_id:int, pos_t:Vector2i, dir:Vector2i, tile_push_count:int, is_splitted:bool, unsplit_atlas_coords:Vector2i):	
	#add sliding tiles
	var back_tile:TileForTilemap;
	var curr_atlas_coords:Vector2i;
	var merge_pos_t:Vector2i = pos_t + (tile_push_count + 1) * dir;
	var is_merging:bool = is_tile(merge_pos_t);
	
	for dist_to_src in range(tile_push_count + 1):
		# get atlas_coord and erase from tilemap
		var curr_pos_t:Vector2i = pos_t + dist_to_src * dir;
		curr_atlas_coords = get_atlas_coords(GV.LayerId.TILE, curr_pos_t);
		var curr_type_id:int = atlas_coords_to_type_id(curr_atlas_coords);
		set_atlas_coords(GV.LayerId.TILE, curr_pos_t, -Vector2i.ONE);
		
		# add transit tile
		var curr_splitted:bool = (not dist_to_src and is_splitted);
		var curr_merging:bool = (dist_to_src == tile_push_count and is_merging);
		var curr_tile:TileForTilemap = get_pooled_tile(pusher_entity_id, GV.TransitId.SLIDE, curr_pos_t, dir, 1, curr_atlas_coords, curr_atlas_coords, back_tile, curr_splitted, curr_merging, null);
		$TransitTiles.add_child(curr_tile);
		#$TransitTiles.call_deferred("add_child", curr_tile);
		
		# update entity
		if curr_type_id != GV.EntityId.NONE:
			get_entity(curr_type_id, curr_pos_t).set_entity_id_and_body(curr_type_id, curr_tile);
		
		# update back_tile
		back_tile = curr_tile;
		
		# play sound
		# NOTE attach split/merge sounds to split/merge tiles
		if not dist_to_src and not is_splitted:
			curr_tile.get_node("Audio/Slide").play();
	
	# init front_tiles and add slide tiles to tree
	# add frontmost tiles first so chain moves in sync every frame? NAH, collision uses positions from previous frame
	var curr_tile:TileForTilemap = back_tile;
	while curr_tile.back_tile != null:
		curr_tile.back_tile.front_tile = curr_tile;
		curr_tile = curr_tile.back_tile;

	# add splitting tile
	if is_splitted:
		var split_atlas_coords:Vector2i = Vector2i(curr_tile.atlas_coords.x, GV.TypeId.REGULAR);
		var splitting_tile:TileForTilemap = get_pooled_tile(GV.EntityId.NONE, GV.TransitId.SPLIT, pos_t, Vector2i.ZERO, 0, unsplit_atlas_coords, split_atlas_coords, null, false, false, curr_tile); #cannot substitute with sprites bc collision shape needed
		$TransitTiles.add_child(splitting_tile);
		#$TransitTiles.call_deferred("add_child", splitting_tile);
		
		# play sound
		splitting_tile.get_node("Audio/Split").play();
	
	# add merging tile (without starting the animation)
	if is_merging:
		# get atlas_coords and erase from tilemap
		var old_atlas_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, merge_pos_t);
		var old_type_id:int = atlas_coords_to_type_id(old_atlas_coords);
		set_atlas_coords(GV.LayerId.TILE, merge_pos_t, -Vector2i.ONE);
		
		# add transit_tile
		var new_atlas_coords:Vector2i = get_merged_atlas_coords(old_atlas_coords, curr_atlas_coords);
		var merging_tile:TileForTilemap = get_pooled_tile(GV.EntityId.NONE, GV.TransitId.MERGE, merge_pos_t, Vector2i.ZERO, 0, old_atlas_coords, new_atlas_coords, null, false, false, back_tile);
		back_tile.set_merger_tile(merging_tile);
		$TransitTiles.add_child(merging_tile);
		#$TransitTiles.call_deferred("add_child", merging_tile);
		
		# update entity
		if old_type_id != GV.EntityId.NONE:
			# use old_type_id until merge animation finishes
			# don't switch to new_type_id when governor_tile finishes to stay consistent with splitting tile
			get_entity(old_type_id, merge_pos_t).set_entity_id_and_body(old_type_id, merging_tile);
		
		# play sound
		merging_tile.get_node("Audio/Combine").play();

func animate_shift(pusher_entity_id:int, pos_t:Vector2i, dir:Vector2i, target_dist:int):
	#get atlas_coords and erase from tilemap
	var atlas_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, pos_t);
	var type_id:int = atlas_coords_to_type_id(atlas_coords);
	set_atlas_coords(GV.LayerId.TILE, pos_t, -Vector2i.ONE);
	
	#add transit_tile
	var tile:TileForTilemap = get_pooled_tile(pusher_entity_id, GV.TransitId.SHIFT, pos_t, dir, target_dist, atlas_coords, atlas_coords, null, false, false, null);
	$TransitTiles.add_child(tile);
	#$TransitTiles.call_deferred("add_child", tile);
	
	#update entity
	if type_id != GV.EntityId.NONE:
		get_entity(type_id, pos_t).set_entity_id_and_body(type_id, tile);

	#start audio
	tile.get_node("Audio/Shift").play();
