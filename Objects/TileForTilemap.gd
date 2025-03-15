class_name TileForTilemap
extends CharacterBody2D;

signal moved_for_tracking_cam;
var atlas_coords:Vector2i;
var curr_sprite:TileForTilemapSprite;
var prev_sprite:TileForTilemapSprite;
var move_controller:TileForTilemapController;
var front_tile:TileForTilemap; #in direction of initial action
var back_tile:TileForTilemap; #in direction of initial action
var world:World;
var tile_sheet:CompressedTexture2D;
var old_type_id:int;
var new_type_id:int;
var merger_tile:TileForTilemap;
var splitter_tile:TileForTilemap;
# id of entity that initiated move, GV.EntityId.NONE if tile not moving
# used to index GV.slide_priorities for tiebreaking
var is_merging:bool = false;
var is_splitted:bool = false;
var pusher_entity_id:int = GV.EntityId.NONE;
var move_transit_id:int = GV.TransitId.NONE;
var conversion_transit_id:int = GV.TransitId.NONE;
var is_initializing_transit:bool = false;
var is_aligned:bool = true;
var was_aligned:bool = true; #at start of move transit
# if is_aligned, represents current pos_t
# if was_aligned, represents src_pos_t
# since pos_t should be invalid during ROAM, is_aligned should be false during ROAM
var pos_t:Vector2i;

@onready var collision_shape:CollisionPolygon2D = get_node("CollisionPolygon2D");


#must be empty so packed_tile instantiates with script attached
func _init():
	pass;
	
func initialize(world:World, tile_sheet:CompressedTexture2D, pos_t:Vector2i):
	assert(is_aligned);
	self.world = world;
	self.tile_sheet = tile_sheet;
	self.pos_t = pos_t;
	position = GV.pos_t_to_world(pos_t);

func set_merger_tile(tile:TileForTilemap):
	assert(tile);
	merger_tile = tile;
	add_collision_exception_with(tile);

func set_splitter_tile(tile:TileForTilemap):
	assert(tile);
	splitter_tile = tile;
	add_collision_exception_with(tile);

func clear_collision_values():
	for collision_id in GV.CollisionId.values():
		set_collision_layer_value(collision_id, false);
		set_collision_mask_value(collision_id, false);

func clear_curr_sprite():
	if curr_sprite:
		curr_sprite.queue_free();
		curr_sprite = null;

func clear_prev_sprite():
	if prev_sprite:
		prev_sprite.queue_free();
		prev_sprite = null;

func clear_sprites():
	clear_prev_sprite();
	clear_curr_sprite();

func initialize_roam(atlas_coords:Vector2i):
	#print("initialize roam")
	assert(not move_controller);
	move_transit_id = GV.TransitId.ROAM;
	is_aligned = false;
	self.atlas_coords = atlas_coords;
	old_type_id = world.atlas_coords_to_type_id(atlas_coords);
	new_type_id = old_type_id;
	velocity = Vector2.ZERO;
	move_controller = TileForTilemapRoamController.new();

# does not require tile to be aligned
# delay movement by one frame to wait for tilemap collider update
func initialize_slide(pusher_entity_id:int, dir:Vector2i, atlas_coords:Vector2i, is_splitted:bool, is_merging:bool, p_back_tile:TileForTilemap):
	#print("initialize slide")
	assert(not is_initializing_transit);
	assert(not move_controller);
	back_tile = p_back_tile;
	
	# sprites (static frame)
	if conversion_transit_id == GV.TransitId.NONE:
		clear_sprites();
		curr_sprite = TileForTilemapSprite.new(self, tile_sheet, atlas_coords, GV.ZId.DEFAULT, 1);
		add_child(curr_sprite);
	elif conversion_transit_id == GV.TransitId.MERGE:
		prev_sprite.z_index = GV.ZId.COMBINING_OLD_MOVING;
		curr_sprite.z_index = GV.ZId.COMBINING_NEW_MOVING;
	
	# ensure finalize_transit() will do the right thing if called during await
	# (make the correct return-to-pool, update-self-entity-key decisions)
	is_initializing_transit = true;
	await world.get_tree().physics_frame;
	is_initializing_transit = false;
	
	assert(not move_controller);
	move_transit_id = GV.TransitId.SLIDE;
	self.pusher_entity_id = pusher_entity_id;
	self.is_splitted = is_splitted;
	self.is_merging = is_merging;
	self.atlas_coords = atlas_coords;
	
	old_type_id = world.atlas_coords_to_type_id(atlas_coords);
	new_type_id = old_type_id;
	velocity = Vector2.ZERO;
	was_aligned = is_aligned;
	move_controller = TileForTilemapSlideController.new(self, dir);
	is_aligned = false;
	
	# add NAV wall for pathfinder
	if was_aligned:
		world.add_nav_id(pos_t, GV.NAV_UNITS[-dir]);
		world.add_nav_id(pos_t + dir, GV.NavId.ALL);
	else:
		#TODO
		pass;
	
	# collision layers and masks
	# don't set MEMBRANE mask if src_back_id is MEMBRANE (REGULAR can get inside MEMBRANE via player splitting)
	clear_collision_values();
	set_collision_layer_value(GV.CollisionId.DEFAULT, true);
	
	set_collision_mask_value(GV.CollisionId.DEFAULT, true);
	if old_type_id != GV.TypeId.PLAYER and not (was_aligned and world.get_back_id(pos_t) == GV.BackId.MEMBRANE):
		set_collision_mask_value(GV.CollisionId.MEMBRANE, true);
	if GV.E_ENEMY[GV.EntityId.PLAYER][old_type_id]:
		set_collision_mask_value(GV.CollisionId.SAVE_OR_GOAL, true);
	
	# sprite animators
	#curr_sprite.add_animators([], null);

func initialize_shift(dir:Vector2i, target_dist_t:int, atlas_coords:Vector2i):
	#print("initialize shift")
	assert(not is_initializing_transit);
	assert(not move_controller);
	
	# sprites (static frame)
	if conversion_transit_id == GV.TransitId.NONE:
		clear_sprites();
		curr_sprite = TileForTilemapSprite.new(self, tile_sheet, atlas_coords, GV.ZId.DEFAULT, 1);
		add_child(curr_sprite);
	elif conversion_transit_id == GV.TransitId.MERGE:
		prev_sprite.z_index = GV.ZId.COMBINING_OLD_MOVING;
		curr_sprite.z_index = GV.ZId.COMBINING_NEW_MOVING;
	
	is_initializing_transit = true;
	await world.get_tree().physics_frame;
	is_initializing_transit = false;
	
	assert(not move_controller);
	assert(is_aligned);
	move_transit_id = GV.TransitId.SHIFT;
	self.atlas_coords = atlas_coords;
	old_type_id = world.atlas_coords_to_type_id(atlas_coords);
	new_type_id = old_type_id;
	velocity = Vector2.ZERO;
	was_aligned = is_aligned;
	move_controller = TileForTilemapShiftController.new(self, dir, target_dist_t);
	is_aligned = false;
	
	# add NAV wall for pathfinder
	world.add_nav_id(pos_t, GV.NAV_UNITS[-dir]);
	world.add_nav_id(pos_t + dir, GV.NavId.ALL);
	
	# collision layers and masks
	# don't set MEMBRANE mask if src_back_id is MEMBRANE (REGULAR can get inside MEMBRANE via player splitting)
	clear_collision_values();
	set_collision_layer_value(GV.CollisionId.DEFAULT, true);
	
	set_collision_mask_value(GV.CollisionId.DEFAULT, true);
	if old_type_id != GV.TypeId.PLAYER and not (was_aligned and world.get_back_id(pos_t) == GV.BackId.MEMBRANE):
		set_collision_mask_value(GV.CollisionId.MEMBRANE, true);
	if GV.E_ENEMY[GV.EntityId.PLAYER][old_type_id]:
		set_collision_mask_value(GV.CollisionId.SAVE_OR_GOAL, true);
	
	# sprite animators
	#curr_sprite.add_animators([], null);

func initialize_split(old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, governor_tile:TileForTilemap):
	#print("initialize split")
	assert(not is_initializing_transit);
	assert(not move_controller);
	
	# sprites (static frame)
	clear_sprites();
	prev_sprite = TileForTilemapSprite.new(self, tile_sheet, old_atlas_coords, GV.ZId.SPLITTING_OLD, 1);
	curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.SPLITTING_NEW, 0);
	add_child(prev_sprite);
	add_child(curr_sprite);
	
	is_initializing_transit = true;
	await world.get_tree().physics_frame;
	is_initializing_transit = false;
	
	assert(not move_controller);
	assert(not is_merging);
	assert(not is_splitted);
	assert(is_aligned);
	conversion_transit_id = GV.TransitId.SPLIT;
	atlas_coords = new_atlas_coords;
	old_type_id = world.atlas_coords_to_type_id(old_atlas_coords);
	new_type_id = world.atlas_coords_to_type_id(new_atlas_coords);
	velocity = Vector2.ZERO;
	
	# add NAV wall for pathfinder
	world.add_nav_id(pos_t, GV.NavId.ALL);
	
	# collision layers and masks
	clear_collision_values();
	set_collision_layer_value(GV.CollisionId.DEFAULT, true);
	
	# sprite animators
	prev_sprite.add_animators([GV.ConversionAnimatorId.DWING_FADE_OUT, GV.ConversionAnimatorId.DWING], governor_tile);
	curr_sprite.add_animators([GV.ConversionAnimatorId.DWING_FADE_IN, GV.ConversionAnimatorId.DWING], governor_tile);

func initialize_merge(old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, governor_tile:TileForTilemap):
	#print("initialize merge")
	assert(not is_initializing_transit);
	assert(not move_controller);
	
	# sprites (static frame)
	clear_sprites();
	prev_sprite = TileForTilemapSprite.new(self, tile_sheet, old_atlas_coords, GV.ZId.COMBINING_OLD, 1);
	curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.COMBINING_NEW, 0);
	add_child(prev_sprite);
	add_child(curr_sprite);
	
	is_initializing_transit = true;
	await world.get_tree().physics_frame;
	is_initializing_transit = false;
	
	assert(not move_controller);
	assert(not is_merging);
	assert(not is_splitted);
	assert(is_aligned);
	conversion_transit_id = GV.TransitId.MERGE;
	atlas_coords = new_atlas_coords;
	old_type_id = world.atlas_coords_to_type_id(old_atlas_coords);
	new_type_id = world.atlas_coords_to_type_id(new_atlas_coords);
	velocity = Vector2.ZERO;
	
	# add NAV wall for pathfinder
	world.add_nav_id(pos_t, GV.NavId.ALL);
	
	# collision layers and masks
	clear_collision_values();
	set_collision_layer_value(GV.CollisionId.DEFAULT, true);
	
	# sprite animators
	prev_sprite.add_animators([GV.ConversionAnimatorId.DUANG_FADE_OUT, GV.ConversionAnimatorId.DUANG], governor_tile);
	curr_sprite.add_animators([GV.ConversionAnimatorId.DUANG_FADE_IN, GV.ConversionAnimatorId.DUANG], governor_tile);

#pooled tiles do not call _physics_process() since it's only called if the node is present in the scene tree
func _physics_process(delta: float) -> void:
	if move_controller:
		if not move_controller.step(delta):
			#check if aligned
			var curr_pos_t:Vector2i = GV.world_to_pos_t(position);
			var offset:Vector2 = position - GV.pos_t_to_world(curr_pos_t); #this is the vector from nearest grid center (not intersection) to tile position
			var is_aligned:bool = (move_controller.dir.x and abs(offset.y) <= GV.SNAP_TOLERANCE) or \
									(move_controller.dir.y and abs(offset.x) <= GV.SNAP_TOLERANCE);
			finalize_transit(move_transit_id, is_aligned, curr_pos_t, move_controller.is_reversed);

# NOTE don't use governor_tile.is_splitted/is_merging to get prev_transit_id bc it might've been returned to pool already
# NOTE when merger/splitter finalizes depends on framerate, so they should only be responsible for entity key (switch to pos_t), atlas_coords, aligned_tiles_in_transient, and return to pool
# NOTE skip if is_initializing_transit
# NOTE if is_move_finalize and is_reversed, finalize merger/splitter too bc splitter tile finalizing late could cause unexpected collision
func finalize_transit(prev_transit_id:int, is_aligned:bool, pos_t:Vector2i, is_reversed:bool):
	#print("finalize ", "reversed " if is_reversed else "", GV.TransitId.keys()[prev_transit_id], " at ", pos_t, position, " is_aligned: ", is_aligned);
	if is_initializing_transit:
		assert(is_aligned);
		assert(prev_transit_id != move_transit_id);
		#print("SKIP")
		return;
	
	# snap position
	if is_aligned:
		position = GV.pos_t_to_world(pos_t);

	# find derived flags
	# don't overuse them, they obfuscate the logic
	var is_move_finalize:bool = (prev_transit_id == move_transit_id);
	var is_self_entity_preserved:bool = not is_move_finalize or not is_merging or is_reversed or (merger_tile.new_type_id == old_type_id and merger_tile.old_type_id != old_type_id);
	
	# update transit_ids
	if prev_transit_id == move_transit_id:
		move_transit_id = GV.TransitId.NONE;
	else:
		assert(conversion_transit_id == prev_transit_id);
		conversion_transit_id = GV.TransitId.NONE;
	
	# update is_aligned and pos_t, which are used by entity.set_is_busy() and add_aligned_tile_in_transient()
	self.is_aligned = is_aligned;
	self.pos_t = pos_t;
	
	# asserts
	if is_move_finalize:
		if is_merging:
			assert(not merger_tile.is_initializing_transit);
		if is_splitted:
			assert(not splitter_tile.is_initializing_transit);
	
	# ================ START CRITICAL SECTION ================
	world.layer_mutexes[GV.LayerId.TILE].lock();
	# get self entity
	var tile_entity_id:int = old_type_id if is_reversed else new_type_id;
	var tile_entity:Entity = world.get_entity(tile_entity_id, self);
	
	# find resulting entity at pos_t
	# NOTE null if not aligned, assume this is only used for moved_for_PC signal
	var resulting_entity:Entity;
	if is_aligned:
		if is_self_entity_preserved:
			resulting_entity = tile_entity;
		else:
			assert(is_move_finalize and is_merging);
			# NOTE this will be null iff merger entity is getting removed
			resulting_entity = world.get_entity(merger_tile.new_type_id, merger_tile);
	
	# emit moved for path controller
	# NOTE this should be done before "remove self entity" so path controller can do its finalize logic
	if tile_entity and is_aligned and is_move_finalize:
		tile_entity.moved_for_path_controller.emit(pos_t, is_reversed, resulting_entity);
	
	# remove self entity
	if tile_entity and not is_self_entity_preserved:
		tile_entity.die(resulting_entity);
		tile_entity = null;
	
	# set self entity key
	# NOTE assume type did not change if not is_aligned
	# NOTE don't change key to pos_t if still converting
	if tile_entity and is_aligned and move_transit_id == GV.TransitId.NONE:
		if is_move_finalize and is_merging and not is_reversed and is_self_entity_preserved:
			#print("set entity key to merger tile at pos_t ", merger_tile.pos_t);
			tile_entity.set_body(merger_tile);
		elif conversion_transit_id == GV.TransitId.NONE:
			#print("set entity key to pos_t ", pos_t);
			tile_entity.set_pos_t(pos_t);
		
	# emit moved for tracking cam
	# NOTE this should be done after "remove self entity" so no pan is triggered if agent dies (tile_entity must be checked)
	if tile_entity and is_aligned and is_move_finalize:
		tile_entity.moved_for_tracking_cam.emit();
	
	# remove merger/splitter entity
	# if governor and merger_tile have the same type, merger entity is kept
	if is_move_finalize:
		if is_merging and not is_reversed and merger_tile.new_type_id != merger_tile.old_type_id:
			var merger_tile_entity:Entity = world.get_entity(merger_tile.old_type_id, merger_tile);
			if merger_tile_entity:
				merger_tile_entity.die(resulting_entity);
		if is_splitted and is_reversed:
			var splitter_tile_entity:Entity = world.get_entity(splitter_tile.old_type_id, splitter_tile);
			if splitter_tile_entity:
				splitter_tile_entity.die(resulting_entity);
	
	# update tilemap TILE layer
	var is_poolable:bool = is_aligned and move_transit_id == GV.TransitId.NONE and (conversion_transit_id == GV.TransitId.NONE or (is_move_finalize and is_merging and not is_reversed));
	if is_poolable:
		if (not is_merging and prev_transit_id != GV.TransitId.SPLIT) or (prev_transit_id == GV.TransitId.SPLIT and not is_reversed) or (is_move_finalize and is_merging and is_reversed):
			var final_atlas_coords:Vector2i = world.get_doubled_tile_atlas_coords(atlas_coords) if is_splitted and is_reversed else atlas_coords;
			world.set_atlas_coords(GV.LayerId.TILE, pos_t, GV.TileSetSourceId.TILE, final_atlas_coords);
	
	# remove from aligned_tiles_in_transient
	if is_poolable and not is_move_finalize:
		world.remove_aligned_tile_in_transient(self);
	
	# add to aligned_tiles_in_transient and AltId TILE
	# NOTE add self as well if converting and no successful merge happens
	if is_move_finalize:
		if not is_reversed and is_merging:
			assert(is_aligned);
			world.add_aligned_tile_in_transient(merger_tile);
			assert(world.get_atlas_coords(GV.LayerId.TILE, merger_tile.pos_t) == -Vector2i.ONE);
			world.set_atlas_coords(GV.LayerId.TILE, merger_tile.pos_t, GV.TileSetSourceId.TILE, merger_tile.atlas_coords, 1, false);
		elif conversion_transit_id != GV.TransitId.NONE:
			assert(is_aligned);
			world.add_aligned_tile_in_transient(self);
			assert(world.get_atlas_coords(GV.LayerId.TILE, pos_t) == -Vector2i.ONE);
			world.set_atlas_coords(GV.LayerId.TILE, pos_t, GV.TileSetSourceId.TILE, atlas_coords, 1, false);
		if not is_reversed and is_splitted:
			assert(is_aligned);
			world.add_aligned_tile_in_transient(splitter_tile);
			assert(world.get_atlas_coords(GV.LayerId.TILE, splitter_tile.pos_t) == -Vector2i.ONE);
			world.set_atlas_coords(GV.LayerId.TILE, splitter_tile.pos_t, GV.TileSetSourceId.TILE, splitter_tile.atlas_coords, 1, false);
		
	world.layer_mutexes[GV.LayerId.TILE].unlock();
	# ================ END CRITICAL SECTION ================
	
	# update tilemap NAV layer
	if is_aligned and was_aligned and is_move_finalize:
		world.remove_nav_id(pos_t, GV.NavId.ALL);
		world.remove_nav_id(pos_t - move_controller.dir, GV.NAV_UNITS[-move_controller.dir]);
		
		if is_merging:
			world.remove_nav_id(merger_tile.pos_t, GV.NavId.ALL);
		if is_splitted:
			world.remove_nav_id(splitter_tile.pos_t, GV.NavId.ALL);
	
	# set self entity not busy
	if tile_entity and is_move_finalize and is_self_entity_preserved:
		tile_entity.set_is_busy(false);
	
	# set splitter/merger entity not busy IF THEY"RE NOT MOVING
	if is_move_finalize:
		if is_merging and not is_self_entity_preserved:
			assert(merger_tile.move_transit_id == GV.TransitId.NONE);
			var merger_tile_entity:Entity = world.get_entity(merger_tile.new_type_id, merger_tile);
			if merger_tile_entity:
				merger_tile_entity.set_is_busy(false);
		if is_splitted and not is_reversed:
			assert(splitter_tile.move_transit_id == GV.TransitId.NONE);
			var splitter_tile_entity:Entity = world.get_entity(splitter_tile.new_type_id, splitter_tile);
			if splitter_tile_entity:
				splitter_tile_entity.set_is_busy(false);
	
	# finalize merger and splitter tiles
	# NOTE assume this doesn't queue_free() them, so that remove_collision_exception_with() will succeed
	if is_move_finalize and is_reversed:
		if is_merging:
			merger_tile.finalize_transit(GV.TransitId.MERGE, true, merger_tile.pos_t, true);
		if is_splitted:
			splitter_tile.finalize_transit(GV.TransitId.SPLIT, true, splitter_tile.pos_t, true);
	
	# return to pool or update misc. properties to prepare for next transition
	if is_poolable:
		assert(not tile_entity or tile_entity.body != self);
		world.return_pooled_tile(self);
	else:
		if move_transit_id == GV.TransitId.NONE:
			move_controller = null;
			if front_tile:
				front_tile.back_tile = null;
				front_tile = null;
			if back_tile:
				back_tile.front_tile = null;
				back_tile = null;
			if merger_tile:
				remove_collision_exception_with(merger_tile);
				merger_tile = null;
			if splitter_tile:
				remove_collision_exception_with(splitter_tile);
				splitter_tile = null;
		
			is_splitted = false;
			is_merging = false;
			old_type_id = new_type_id;
			pusher_entity_id = GV.EntityId.NONE;
			
			# update collision values
			clear_collision_values();
			set_collision_layer_value(GV.CollisionId.DEFAULT, true);
		
		if conversion_transit_id == GV.TransitId.NONE:
			# remove the unused sprite
			# clear animators to prevent duplicate conversion finalize
			if not is_move_finalize:
				if is_reversed:
					clear_curr_sprite();
					prev_sprite.modulate.a = 1;
					prev_sprite.scale = Vector2.ONE;
					prev_sprite.z_index = GV.ZId.DEFAULT;
					prev_sprite.animators.clear();
				else:
					clear_prev_sprite();
					curr_sprite.modulate.a = 1;
					curr_sprite.scale = Vector2.ONE;
					curr_sprite.z_index = GV.ZId.DEFAULT;
					curr_sprite.animators.clear();
			
			# update collision values
			# ALL DONE

func are_sprite_animators_finished() -> bool:
	return (not prev_sprite or prev_sprite.animators.is_empty()) and (not curr_sprite or curr_sprite.animators.is_empty());
