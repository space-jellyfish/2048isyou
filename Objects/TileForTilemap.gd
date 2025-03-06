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
	self.merger_tile = tile;
	add_collision_exception_with(tile);

func set_splitter_tile(tile:TileForTilemap):
	self.splitter_tile = tile;
	add_collision_exception_with(tile);

func clear_collision_values():
	for collision_id in GV.CollisionId.values():
		set_collision_layer_value(collision_id, false);
		set_collision_mask_value(collision_id, false);

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
func initialize_slide(pusher_entity_id:int, dir:Vector2i, atlas_coords:Vector2i, back_tile:TileForTilemap, is_splitted:bool, is_merging:bool):
	#print("initialize slide")
	assert(not move_controller);
	move_transit_id = GV.TransitId.SLIDE;
	self.pusher_entity_id = pusher_entity_id;
	self.is_splitted = is_splitted;
	self.is_merging = is_merging;
	self.atlas_coords = atlas_coords;
	self.back_tile = back_tile;
	old_type_id = world.atlas_coords_to_type_id(atlas_coords);
	new_type_id = old_type_id;
	velocity = Vector2.ZERO;
	was_aligned = is_aligned;
	move_controller = TileForTilemapSlideController.new(self, dir);
	
	# add NAV wall for pathfinder
	if is_aligned:
		world.add_nav_id(pos_t, GV.NAV_UNITS[dir]);
		world.add_nav_id(pos_t + dir, GV.NavId.ALL);
	else:
		#TODO
		pass;
	
	# sprites
	if conversion_transit_id == GV.TransitId.NONE:
		curr_sprite = TileForTilemapSprite.new(self, tile_sheet, atlas_coords, GV.ZId.DEFAULT, 1, [], null);
		add_child(curr_sprite);
	elif conversion_transit_id == GV.TransitId.MERGE:
		prev_sprite.z_index = GV.ZId.COMBINING_OLD_MOVING;
		curr_sprite.z_index = GV.ZId.COMBINING_NEW_MOVING;
	
	# collision layers and masks
	# don't set MEMBRANE mask if src_back_id is MEMBRANE (REGULAR can get inside MEMBRANE via player splitting)
	clear_collision_values();
	set_collision_layer_value(GV.CollisionId.DEFAULT, true);
	
	set_collision_mask_value(GV.CollisionId.DEFAULT, true);
	if old_type_id != GV.TypeId.PLAYER and not (is_aligned and world.get_back_id(pos_t) == GV.BackId.MEMBRANE):
		set_collision_mask_value(GV.CollisionId.MEMBRANE, true);
	if old_type_id in GV.T_ENEMY:
		set_collision_mask_value(GV.CollisionId.SAVE_OR_GOAL, true);
	
	is_aligned = false;

func initialize_shift(dir:Vector2i, target_dist_t:int, atlas_coords:Vector2i):
	#print("initialize shift")
	assert(not move_controller);
	assert(is_aligned);
	move_transit_id = GV.TransitId.SHIFT;
	self.atlas_coords = atlas_coords;
	old_type_id = world.atlas_coords_to_type_id(atlas_coords);
	new_type_id = old_type_id;
	velocity = Vector2.ZERO;
	was_aligned = is_aligned;
	move_controller = TileForTilemapShiftController.new(self, dir, target_dist_t);
	
	# add NAV wall for pathfinder
	world.add_nav_id(pos_t, GV.NAV_UNITS[dir]);
	world.add_nav_id(pos_t + dir, GV.NavId.ALL);
	
	# sprites
	if conversion_transit_id == GV.TransitId.NONE:
		curr_sprite = TileForTilemapSprite.new(self, tile_sheet, atlas_coords, GV.ZId.DEFAULT, 1, [], null);
		add_child(curr_sprite);
	elif conversion_transit_id == GV.TransitId.MERGE:
		prev_sprite.z_index = GV.ZId.COMBINING_OLD_MOVING;
		curr_sprite.z_index = GV.ZId.COMBINING_NEW_MOVING;
	
	# collision layers and masks
	# don't set MEMBRANE mask if src_back_id is MEMBRANE (REGULAR can get inside MEMBRANE via player splitting)
	clear_collision_values();
	set_collision_layer_value(GV.CollisionId.DEFAULT, true);
	
	set_collision_mask_value(GV.CollisionId.DEFAULT, true);
	if old_type_id != GV.TypeId.PLAYER and not (is_aligned and world.get_back_id(pos_t) == GV.BackId.MEMBRANE):
		set_collision_mask_value(GV.CollisionId.MEMBRANE, true);
	if old_type_id in GV.T_ENEMY:
		set_collision_mask_value(GV.CollisionId.SAVE_OR_GOAL, true);
	
	is_aligned = false;

func initialize_split(old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, governor_tile:TileForTilemap):
	#print("initialize split")
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
	
	# sprites
	if prev_sprite:
		prev_sprite.queue_free();
		prev_sprite = null;
	if curr_sprite:
		curr_sprite.queue_free();
		curr_sprite = null;
	prev_sprite = TileForTilemapSprite.new(self, tile_sheet, old_atlas_coords, GV.ZId.SPLITTING_OLD, 1, [GV.ConversionAnimatorId.DWING_FADE_OUT, GV.ConversionAnimatorId.DWING], governor_tile);
	curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.SPLITTING_NEW, 0, [GV.ConversionAnimatorId.DWING_FADE_IN, GV.ConversionAnimatorId.DWING], governor_tile);
	add_child(prev_sprite);
	add_child(curr_sprite);
	
	# collision layers and masks
	clear_collision_values();
	set_collision_layer_value(GV.CollisionId.DEFAULT, true);

func initialize_merge(old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, governor_tile:TileForTilemap):
	#print("initialize merge")
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
	
	# sprites
	if prev_sprite:
		prev_sprite.queue_free();
		prev_sprite = null;
	if curr_sprite:
		curr_sprite.queue_free();
		curr_sprite = null;
	prev_sprite = TileForTilemapSprite.new(self, tile_sheet, old_atlas_coords, GV.ZId.COMBINING_OLD, 1, [GV.ConversionAnimatorId.DUANG_FADE_OUT, GV.ConversionAnimatorId.DUANG], governor_tile);
	curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.COMBINING_NEW, 0, [GV.ConversionAnimatorId.DUANG_FADE_IN, GV.ConversionAnimatorId.DUANG], governor_tile);
	add_child(prev_sprite);
	add_child(curr_sprite);
	
	# collision layers and masks
	clear_collision_values();
	set_collision_layer_value(GV.CollisionId.DEFAULT, true);

func _ready() -> void:
	collision_shape.scale = GV.PLAYER_COLLIDER_SCALE * Vector2.ONE;

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
# NOTE when merger/splitter finalizes depends on framerate, so they should only be responsible for entity key (switch to pos_t), atlas_coords, tiles_in_transient, and return to pool
# Type and Entity Key/Busy/Removal and TileMap and tiles_in_transient and tile_pool Changes
# MERGE Case 1: m: b->b, g: a->a
#	not reversed
#		on g.finalize,
#			m.entity.key does not change
#			m.entity.busy becomes false
#			g.entity is removed
#			tilemap does not change
#			add m to tiles_in_transient
#			return to pool if conversion animators finished
#		on m.finalize,
#			change m.entity.key to pos_t if not moving
#			set atlas_coords if not moving
#			remove m from tiles_in_transient if not moving (else already removed)
#			return to pool if not moving
#	reversed
#		on g.finalize,
#			set g.entity.key to pos_t
#			set g.entity.busy to false
#			set m.entity.busy to false
#			set atlas_coords
#			return to pool if conversion animators finished
#		on m.finalize,
#			set m.entity.key to pos_t
#			set atlas_coords
#			return to pool
# MERGE Case 2: m: b->a, g: a->a, b != a
#	not reversed
#		on g.finalize,
#			g.entity.key changes from g to m
#			m.entity is removed
#			g.entity.busy becomes false
#			tilemap does not change
#			add m to tiles_in_transient
#			return to pool if conversion animators finished
#		on m.finalize,
#			change m.entity.key to pos_t if not moving
#			set atlas_coords if not moving
#			remove m from tiles_in_transient if not moving
#			return to pool if not moving
#	reversed
#		""
# MERGE Case 3 (Death by Zeroing): m: b->REG, g: a->a, b != REG, a != REG
#	not reversed
#		on g.finalize,
#			remove g.entity
#			remove m.entity
#			tilemap doesn't change
#			add m to tiles_in_transient
#			return to pool if conversion animators finished
#		on m.finalize,
#			set atlas_coords if not moving
#			remove m from tiles_in_transient if not moving
#			return to pool if not moving
#	reversed
#		""
# SPLIT Case 1: s: a->a, g: a->a
#	not reversed
#		on g.finalize,
#			change g.entity.key from g to pos_t
#			set g.busy to false
#			set s.busy to false
#			set atlas_coords at pos_t
#			add s to tiles_in_transient
#			return to pool if conversion animators finished
#		on s.finalize,
#			change s.entity.key to pos_t if not moving
#			set atlas_coords if not moving
#			remove s from tiles_in_transient if not moving
#			return to pool if not moving
#	reversed
#		on g.finalize,
#			set g.entity.key to pos_t
#			set g.entity.busy to false
#			remove s.entity
#			set unsplit atlas_coords at pos_t
#			return to pool if conversion animators finished
#		on s.finalize,
#			return to pool
# SPLIT Case 2: s: a->REG, g: a->a, a != REG
#	not reversed
#		on g.finalize
#			change g.entity.key to pos_t
#			set g.busy to false
#			no need to remove s.entity since it was transferred to g
#			set atlas_coords at pos_t
#			add s to tiles_in_transient
#			return to pool if conversion animators finished
#		on s.finalize
#			set atlas_coords if not moving
#			remove s from tiles_in_transient if not moving
#			return to pool if not moving
#	reversed
#		on g.finalize
#			set g.entity.key to pos_t
#			set g.busy to false
#			set unsplit atlas_coords at pos_t
#			return to pool if conversion animators finished
#		on s.finalize
#			return to pool
# SHIFT:
#	set entity.key to pos_t
#	set entity.busy to false
#	set atlas_coords at pos_t
#	return to pool if conversion animators finished
func finalize_transit(prev_transit_id:int, is_aligned:bool, pos_t:Vector2i, is_reversed:bool):
	#print("finalize ", "reversed " if is_reversed else "", GV.TransitId.keys()[prev_transit_id], " at ", pos_t, position, " is_aligned: ", is_aligned);
	
	# snap position
	if is_aligned:
		position = GV.pos_t_to_world(pos_t);

	# update transit_ids
	if prev_transit_id == move_transit_id:
		move_transit_id = GV.TransitId.NONE;
	else:
		assert(conversion_transit_id == prev_transit_id);
		conversion_transit_id = GV.TransitId.NONE;
	
	# ================ START CRITICAL SECTION ================
	world.layer_mutexes[GV.LayerId.TILE].lock();
	# get tile entity
	var tile_entity_id:int = old_type_id if is_reversed else new_type_id;
	var tile_entity:Entity = world.get_entity(tile_entity_id, self);
	
	# remove self entity
	if is_merging and not is_reversed and merger_tile.new_type_id in [merger_tile.old_type_id, GV.TypeId.REGULAR]:
		world.remove_entity(tile_entity_id, self);
		tile_entity = null;

	# set self entity key
	# NOTE assume type did not change if not is_aligned
	if tile_entity and is_aligned and move_transit_id == GV.TransitId.NONE:
		if is_merging and not is_reversed and merger_tile.new_type_id == old_type_id and merger_tile.new_type_id != merger_tile.old_type_id:
			tile_entity.set_entity_id_and_body(old_type_id, merger_tile);
		else:
			tile_entity.set_entity_id_and_pos_t(new_type_id, pos_t);
	
	# remove merger/splitter entity
	# if governor and merger_tile have the same type, merger entity is kept
	if is_merging and not is_reversed and merger_tile.old_type_id != merger_tile.new_type_id:
		world.remove_entity(merger_tile.old_type_id, merger_tile);
	if is_splitted and is_reversed:
		world.remove_entity(splitter_tile.old_type_id, splitter_tile);
	
	# update tilemap TILE layer
	var is_poolable:bool = is_aligned and conversion_transit_id == GV.TransitId.NONE and move_transit_id == GV.TransitId.NONE;
	if is_poolable:
		if (prev_transit_id == GV.TransitId.SPLIT and not is_reversed) or (is_merging and is_reversed) or (not is_merging and prev_transit_id != GV.TransitId.SPLIT):
			var final_atlas_coords:Vector2i = world.get_doubled_tile_atlas_coords(atlas_coords) if is_splitted and is_reversed else atlas_coords;
			world.set_atlas_coords(GV.LayerId.TILE, pos_t, GV.TileSetSourceId.TILE, final_atlas_coords);
	
	# update tiles_in_transient and AltId TILE
	if not is_reversed:
		if prev_transit_id in [GV.TransitId.MERGE, GV.TransitId.SPLIT]:
			world.remove_tile_in_transient(self);
		else:
			if is_merging:
				world.add_tile_in_transient(merger_tile);
				assert(world.get_atlas_coords(GV.LayerId.TILE, merger_tile.pos_t) == -Vector2i.ONE);
				world.set_atlas_coords(GV.LayerId.TILE, merger_tile.pos_t, GV.TileSetSourceId.TILE, merger_tile.atlas_coords, 1, false);
			if is_splitted:
				world.add_tile_in_transient(splitter_tile);
				assert(world.get_atlas_coords(GV.LayerId.TILE, splitter_tile.pos_t) == -Vector2i.ONE);
				world.set_atlas_coords(GV.LayerId.TILE, splitter_tile.pos_t, GV.TileSetSourceId.TILE, splitter_tile.atlas_coords, 1, false);
	world.layer_mutexes[GV.LayerId.TILE].unlock();
	# ================ END CRITICAL SECTION ================
	
	# set self entity not busy
	if tile_entity and prev_transit_id in [GV.TransitId.SLIDE, GV.TransitId.SHIFT]:
		tile_entity.set_is_busy(false);
	
	# set splitter/merger entity not busy
	if is_merging:
		var merger_tile_entity:Entity = world.get_entity(merger_tile.new_type_id, merger_tile);
		if merger_tile_entity:
			merger_tile_entity.set_is_busy(false);
	if is_splitted and not is_reversed:
		var splitter_tile_entity:Entity = world.get_entity(splitter_tile.new_type_id, splitter_tile);
		if splitter_tile_entity:
			splitter_tile_entity.set_is_busy(false);
			
	# update tilemap NAV layer
	if is_aligned and move_transit_id == GV.TransitId.NONE:
		if prev_transit_id in [GV.TransitId.SLIDE, GV.TransitId.SHIFT] and was_aligned:
			if is_reversed:
				world.remove_nav_id(pos_t, GV.NAV_UNITS[-move_controller.dir]);
				world.remove_nav_id(pos_t - move_controller.dir, GV.NavId.ALL);
			else:
				world.remove_nav_id(pos_t, GV.NavId.ALL);
				world.remove_nav_id(pos_t - move_controller.dir, GV.NAV_UNITS[move_controller.dir]);
			if is_merging:
				world.remove_nav_id(merger_tile.pos_t, GV.NavId.ALL);
			if is_splitted:
				world.remove_nav_id(splitter_tile.pos_t, GV.NavId.ALL);
	
	# return to pool or update misc. properties to prepare for next transition
	if is_poolable:
		world.return_pooled_tile(self);
	else:
		self.is_aligned = is_aligned;
		self.pos_t = pos_t;
		
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
			if prev_sprite:
				prev_sprite.queue_free();
				prev_sprite = null;
			
			# update collision values
			# ALL DONE
			
			# update curr_sprite z_index
			curr_sprite.z_index = GV.ZId.DEFAULT;

func are_sprite_animators_finished() -> bool:
	return (not prev_sprite or prev_sprite.animators.is_empty()) and (not curr_sprite or curr_sprite.animators.is_empty());
