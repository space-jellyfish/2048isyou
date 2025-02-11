#tilemap-based for better performance
#-Vector2i.ONE indicates cell hasn't been generated yet
#coords indicates atlas_coords from tileset
#empty atlas_coords indicates cell is empty
#val indicates Vector2i(pow, sign)
# save tile if it's not grid-aligned
class_name World
extends Node2D

signal premove_added;

@export var resolution_t:Vector2i = GV.RESOLUTION_T;
@export var min_pos:Vector2 = Vector2.ZERO;
@export var max_pos:Vector2 = GV.RESOLUTION;
@onready var game:Node2D = $"/root/Game";
@onready var tile_sheet:CompressedTexture2D = preload("res://Sprites/Sheets/tile_sheet.png");

@export var player_pos_t:Vector2i = Vector2i.ZERO;
var player_tile:TileForTilemap; #for when player isn't aligned

#for enemy intel
var is_player_alive:bool = true;
var player_shift_dir:Vector2i = Vector2i.ZERO;
var player_shift_remaining_t:int = 0;

var tile_noise = FastNoiseLite.new();
var wall_noise = FastNoiseLite.new();

var loaded_pos_t_min:Vector2i;
var loaded_pos_t_max:Vector2i; #inclusive

var resolution:Vector2;
var half_resolution:Vector2;

var premove_dirs:Array[Vector2i] = [];
var premoves:Array[String] = []; #slide, split, shift

#for input repeat delay
var atimer:AccelTimer = AccelTimer.new();
var last_input_type:int; #see GV.InputType
var last_input_modifier:String = "slide";
var last_input_move:String = "left";

#for animation and collision shapes
#Vector3i(last_saved_pos_t.x, last_saved_pos_t.y, ZId) -> TileForTilemap
#last_saved_pos_t is pos_t stored in TileMap that is reverted to if game crashes (or force quit)
var tile_pool:Array[TileForTilemap];


func _enter_tree():
	#set resolution (before tracking cam _ready())
	resolution = Vector2(resolution_t * GV.TILE_WIDTH);
	half_resolution = resolution / 2;

	#set position bounds (before tracking cam _ready())
	min_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MIN, GV.INT64_MIN);
	max_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MAX, GV.INT64_MAX);
	
func _ready():
	#signals
	premove_added.connect(_on_premove_added);
	
	set_level_name();
	
	if not GV.current_level_from_save: #first time entering lv
		#print("set initial SVID to ", GV.savepoint_id);
		GV.level_initial_savepoint_ids[GV.current_level_index] = GV.savepoint_id;
	
	#clear alternative_ids
	for tile_atlas_x in range(GV.TILE_SHEET_HFRAMES):
		for tile_atlas_y in range(GV.TILE_SHEET_VFRAMES):
			var tile_atlas_coords:Vector2i = Vector2i(tile_atlas_x, tile_atlas_y);
			for pos_t in $Cells.get_used_cells_by_id(GV.LayerId.TILE, GV.LayerId.TILE, tile_atlas_coords, 1):
				set_atlas_coords(GV.LayerId.TILE, pos_t, tile_atlas_coords, 0);

func get_pooled_tile(transit_id:int, pos_t:Vector2i, dir:Vector2i, target_dist_t:int, old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, back_tile:TileForTilemap, is_splitted:bool, is_merging:bool, governor_tile:TileForTilemap, pusher_entity_id:int) -> TileForTilemap:
	if not tile_pool.is_empty():
		var tile:TileForTilemap = tile_pool.pop_back()._init(self, transit_id, pos_t, dir, target_dist_t, tile_sheet, old_atlas_coords, new_atlas_coords, back_tile, is_splitted, is_merging, governor_tile, pusher_entity_id);
		return tile;
	var tile:TileForTilemap = TileForTilemap.new(self, transit_id, pos_t, dir, target_dist_t, tile_sheet, old_atlas_coords, new_atlas_coords, back_tile, is_splitted, is_merging, governor_tile, pusher_entity_id);
	return tile;

func return_pooled_tile(tile:TileForTilemap):
	assert(not tile.is_inside_tree());
	assert(tile.prev_sprite == null);
	assert(tile.curr_sprite == null);
	assert(tile.move_controller == null);
	assert(tile.back_tile == null);
	assert(tile.front_tile == null);
	
	for collision_id in [GV.CollisionId.DEFAULT, GV.CollisionId.SPLITTING, GV.CollisionId.COMBINING]:
		tile.set_collision_layer_value(collision_id, false);
	
	for collision_id in GV.CollisionId.values():
		tile.set_collision_mask_value(collision_id, false);
	
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
	if pos_t == player_pos_t:
		set_atlas_coords(GV.LayerId.TILE, player_pos_t, Vector2i(GV.TileId.ZERO - 1, GV.TypeId.PLAYER));
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

func get_event_modifier(event) -> String:
	for modifier in ["split", "shift"]:
		if event.is_action_pressed(modifier):
			return modifier;
	for modifier in ["split", "shift"]:
		if event.is_action_released(modifier):
			return "slide";
	return "";

func get_event_move(event) -> String:
	for move in ["left", "right", "up", "down"]:
		if event.is_action_pressed(move):
			return move;
	return "";

func is_last_move_held() -> bool:
	return Input.is_action_pressed(last_input_move);

func _input(event):
	var modifier:String = get_event_modifier(event);
	if modifier:
		last_input_modifier = modifier;
		if modifier != "slide" and is_last_move_held():
			add_premove_from_last_input();
		return;
	
	var move:String = get_event_move(event);
	if move:
		last_input_move = move;
		last_input_type = GV.InputType.MOVE;
		add_premove_from_last_input();
		
func add_premove_from_last_input():
	premove_dirs.push_back(GV.directions[last_input_move]);
	premoves.push_back(last_input_modifier);
	premove_added.emit();

func _on_premove_added():
	if is_stable(player_pos_t):
		consume_premove();

func get_atlas_coords(layer_id:int, pos_t:Vector2i) -> Vector2i:
	return $Cells.get_cell_atlas_coords(layer_id, pos_t);

func set_atlas_coords(layer_id:int, pos_t:Vector2i, coords:Vector2i, alternative_id:int = 0):
	$Cells.set_cell(layer_id, pos_t, layer_id, coords, alternative_id);

func get_alternative_id(pos_t:Vector2i):
	return $Cells.get_cell_alternative_tile(GV.LayerId.TILE, pos_t);

func get_tile_id(pos_t:Vector2i):
	return get_atlas_coords(GV.LayerId.TILE, pos_t).x + 1;

#return EMPTY if unstable
func get_stable_tile_id(pos_t:Vector2i):
	if is_stable(pos_t):
		return get_tile_id(pos_t);
	return GV.TileId.EMPTY;

func get_stable_tile_atlas_coords(pos_t:Vector2i):
	if is_stable(pos_t):
		return get_atlas_coords(GV.LayerId.TILE, pos_t);
	return -Vector2i.ONE;

func get_type_id(pos_t:Vector2i):
	var tile_atlas_y:int = get_atlas_coords(GV.LayerId.TILE, pos_t).y;
	return GV.TypeId.REGULAR if tile_atlas_y == -1 else tile_atlas_y;

func get_back_id(pos_t:Vector2i):
	return maxi(get_atlas_coords(GV.LayerId.BACK, pos_t).x, 0);

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
	var val:Vector2i = GV.id_to_tile_val(atlas_coords.x + 1);
	if not is_pow_splittable(val.x):
		return -Vector2i.ONE;
	return Vector2i(atlas_coords.x - val.y, atlas_coords.y if keep_type else GV.TypeId.REGULAR);

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
		curr_tile_id = get_stable_tile_id(curr_pos_t);
		
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

func initiate_slide(pusher_entity_id:int, pos_t:Vector2i, dir:Vector2i, push_count:int, is_splitted:bool):
	#start audio and animation
	animate_slide(pusher_entity_id, pos_t, dir, push_count, is_splitted, );
	
	var merge_pos_t:Vector2i = pos_t + (push_count + 1) * dir;
	if get_stable_tile_id(merge_pos_t):
		game.get_node("Audio/Combine").play();
	if is_splitted:
		game.get_node("Audio/Split").play();
	else:
		game.get_node("Audio/Slide").play();

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

#update player_pos_t, is_player_alive (NAH), player_shift_dir, player_shift_remaining_t
func initiate_shift(pusher_entity_id:int, pos_t:Vector2i, dir:Vector2i, distance:int):
	#var dest_pos_t:Vector2i = pos_t + distance * dir;
	#var src_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, pos_t);
	#set_atlas_coords(GV.LayerId.TILE, dest_pos_t, src_coords);
	#set_atlas_coords(GV.LayerId.TILE, pos_t, -Vector2i.ONE);
	
	#update tile_id, alternative_id, and player stats during animation
	animate_shift(pusher_entity_id, pos_t, dir, distance);
	
	#start audio
	game.get_node("Audio/Shift").play();

func set_player_pos_t(pos_t:Vector2i):
	if pos_t != player_pos_t:
		$Pathfinder.rrd_clear_iad();
	player_pos_t = pos_t;
	$Pathfinder.set_player_pos(pos_t);

func is_stable(pos_t:Vector2i):
	return get_alternative_id(pos_t) == GV.AlternativeId.STABLE;

func try_slide(pusher_entity_id:int, pos_t:Vector2i, dir:Vector2i, is_splitted:bool=false) -> bool:
	if not is_stable(pos_t): # affected by another entity
		return false;
	
	var push_count:int = get_slide_push_count(pos_t, dir);
	if push_count != -1:
		# set alternative_id, start audio/animation
		initiate_slide(pusher_entity_id, pos_t, dir, push_count, is_splitted);
		return true;
	return false;

func try_split(pusher_entity_id:int, pos_t:Vector2i, dir:Vector2i) -> bool:
	if not is_stable(pos_t):
		return false;
	
	var src_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, pos_t);
	var splitted_coords:Vector2i = get_splitted_tile_atlas_coords(src_coords);
	if splitted_coords == -Vector2i.ONE:
		return false;
	
	#halve tile, try_slide, then (re)set tile at pos_t
	set_atlas_coords(GV.LayerId.TILE, pos_t, splitted_coords);
	if try_slide(pusher_entity_id, pos_t, dir, true):
		#reset src coords (alternative)
		set_atlas_coords(GV.LayerId.TILE, pos_t, src_coords, 1);
		return true;
	else:
		#reset src coords (base)
		set_atlas_coords(GV.LayerId.TILE, pos_t, src_coords);
		return false;

#update player_pos_t
func try_shift(pusher_entity_id:int, pos_t:Vector2i, dir:Vector2i) -> bool:
	if not is_stable(pos_t):
		return false;
	
	var target_distance:int = get_shift_target_dist(pos_t, dir);
	if target_distance:
		initiate_shift(pusher_entity_id, pos_t, dir, target_distance);
		return true;
	return false;

func consume_premove():
	#check that player is alive
	if not is_player_alive:
		premoves.clear();
		premove_dirs.clear();
		return;
	
	#get first premove
	var action:String = premoves.pop_front();
	var dir:Vector2i = premove_dirs.pop_front();
	
	#try it
	var action_func:Callable = Callable(self, "try_" + action);
	if action_func.call(GV.EntityId.PLAYER, player_pos_t, dir): # returns true if action was initiated
		# animation should be started from action_func since hostiles don't call consume_premove()
		# same for sound effects
		# same for $Cells update

		# update player-position-related stats from action_func since player can be pushed (bc push priority adjustable from game settings)
		# these include player_pos_t, is_player_alive
		
		# update player_last_dir; this is used by enemies to predict player movement, so only player-initiated actions count
		$Pathfinder.set_player_last_dir(dir);

# hide tiles (by setting alternative_id) and initialize transit_tiles
# set alternative_id at target_pos_t (if it has a tile) to reserve (prevent other slides from merging into) it
# tile with TransitId.MERGE is created but doesn't start animating yet
# sliding (governor) tiles are added before splitting/merging (governed) tiles,
# so by tree order, position/remaining_dist is updated before SpriteAnimator.step()
func animate_slide(pusher_entity_id:int, pos_t:Vector2i, dir:Vector2i, tile_push_count:int, is_splitted:bool):
	#add sliding tiles
	var back_tile:TileForTilemap;
	var curr_atlas_coords:Vector2i;
	var merge_pos_t:Vector2i = pos_t + (tile_push_count + 1) * dir;
	var is_merging:bool = is_tile(merge_pos_t);
	
	for dist_to_src in range(tile_push_count + 1):
		#set alternative_id
		var curr_pos_t:Vector2i = pos_t + dist_to_src * dir;
		curr_atlas_coords = get_atlas_coords(GV.LayerId.TILE, curr_pos_t);
		set_atlas_coords(GV.LayerId.TILE, curr_pos_t, curr_atlas_coords, 1);
		
		#add transit tile
		var curr_splitted:bool = (not dist_to_src and is_splitted);
		var curr_merging:bool = (dist_to_src == tile_push_count and is_merging);
		if curr_splitted:
			curr_atlas_coords = get_splitted_tile_atlas_coords(curr_atlas_coords, true);
		var curr_tile:TileForTilemap = get_pooled_tile(GV.TransitId.SLIDE, pos_t, dir, 1, curr_atlas_coords, curr_atlas_coords, back_tile, curr_splitted, curr_merging, null, pusher_entity_id);
		
		#update back_tile
		back_tile = curr_tile;
	
	#init front_tiles and add slide tiles to tree
	#add frontmost tiles first so chain moves in sync every frame
	var curr_tile:TileForTilemap = back_tile;
	$TransitTiles.add_child(curr_tile);
	while curr_tile.back_tile != null:
		curr_tile.back_tile.front_tile = curr_tile;
		curr_tile = curr_tile.back_tile;
		$TransitTiles.add_child(curr_tile);

	#add splitting tile
	if is_splitted:
		var src_atlas_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, pos_t);
		var new_atlas_coords:Vector2i = get_splitted_tile_atlas_coords(src_atlas_coords, false);
		var splitting_tile:TileForTilemap = get_pooled_tile(GV.TransitId.SPLIT, pos_t, Vector2i.ZERO, 0, src_atlas_coords, new_atlas_coords, null, false, false, curr_tile, GV.EntityId.NONE); #cannot substitute with sprites bc collision shape needed
		$TransitTiles.add_child(splitting_tile);
	
	#add merging tile (without starting the animation)
	if is_merging:
		#set alternative_id
		var old_atlas_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, merge_pos_t);
		set_atlas_coords(GV.LayerId.TILE, merge_pos_t, old_atlas_coords, 1);
		
		#add transit_tile
		var new_atlas_coords:Vector2i = get_merged_atlas_coords(old_atlas_coords, curr_atlas_coords);
		var merging_tile:TileForTilemap = get_pooled_tile(GV.TransitId.MERGE, merge_pos_t, Vector2i.ZERO, 0, old_atlas_coords, new_atlas_coords, null, false, false, back_tile, GV.EntityId.NONE);
		$TransitTiles.add_child(merging_tile);

func animate_shift(pusher_entity_id:int, pos_t:Vector2i, dir:Vector2i, target_dist:int):
	#set alternative_id
	set_atlas_coords(GV.LayerId.TILE, pos_t, get_atlas_coords(GV.LayerId.TILE, pos_t), 1);
	
	#add transit_tile
	var atlas_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, pos_t);
	var tile:TileForTilemap = get_pooled_tile(GV.TransitId.SHIFT, pos_t, dir, target_dist, atlas_coords, atlas_coords, null, false, false, null, pusher_entity_id);
	$TransitTiles.add_child(tile);

#called when merge animation starts
func animate_merge(pos_t:Vector2i, slide_animator:TileForTilemapSlideController):
	pass;

# update tile_id at src_pos_t iff alternative_id is 1 (splitted or back_tile hasn't finalized yet)
# atlas_coord required because tile_id at src_pos_t might've been modified by back_tile
# is_merging required because if TileId.ZERO at target_pos_t, either push or pop possible
# slide does not update Tilemap immediately bc success is not guaranteed (might bounce off squid club)
func finalize_slide(src_pos_t:Vector2i, dir:Vector2i, tile_atlas_coords:Vector2i, is_splitted:bool, is_merging:bool):
	#set atlas_coords at target_pos_t
	var target_pos_t:Vector2i = src_pos_t + dir;
	if is_merging:
		var target_atlas_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, target_pos_t);
		assert(is_ids_mergeable(tile_atlas_coords.x + 1, target_atlas_coords.x + 1));
		var result_atlas_coords:Vector2i = get_merged_atlas_coords(tile_atlas_coords, target_atlas_coords);
		set_atlas_coords(GV.LayerId.TILE, target_pos_t, result_atlas_coords, 1); #alternative_id resets when merge animation finishes
	else:
		set_atlas_coords(GV.LayerId.TILE, target_pos_t, tile_atlas_coords, 0);
	
	#update atlas_coords at src_pos_t
	if is_splitted:
		var parent_coords:Vector2i = Vector2i(tile_atlas_coords.x, GV.TypeId.REGULAR);
		set_atlas_coords(GV.LayerId.TILE, src_pos_t, parent_coords, 1);
	elif get_alternative_id(src_pos_t) == 1:
		set_atlas_coords(GV.LayerId.TILE, src_pos_t, -Vector2i.ONE, 0);

func _on_animator_finished(successful:bool):
	#for consistency, update tilemap and player stats from animator
	
	#update premoves
	if not successful: #bounced
		premoves.clear();
		premove_dirs.clear();
	elif premoves:
		consume_premove();
