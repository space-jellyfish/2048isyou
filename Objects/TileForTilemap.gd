class_name TileForTilemap
extends CharacterBody2D;

signal moved;
var src_pos_t:Vector2i; #correct for split/merge only
var atlas_coords:Vector2i;
var curr_sprite:TileForTilemapSprite;
var prev_sprite:TileForTilemapSprite;
var move_controller:TileForTilemapController;
var front_tile:TileForTilemap; #in direction of initial action
var back_tile:TileForTilemap; #in direction of initial action
var world:World;
var is_splitted:bool;
var is_merging:bool;
var old_type_id:int;
var new_type_id:int;
var merger_tile:TileForTilemap;
var splitter_tile:TileForTilemap;
var pusher_entity_id:int; #id of entity that initiated move, GV.EntityId.NONE if tile not moving
var transit_id:int;

@onready var collision_shape:CollisionPolygon2D = get_node("CollisionPolygon2D");


#must be empty so packed_tile instantiates with script attached
func _init():
	pass;
	
func initialize(world:World, pusher_entity_id:int, transit_id:int, pos_t:Vector2i, dir:Vector2i, target_dist_t:int, tile_sheet:CompressedTexture2D, old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, back_tile:TileForTilemap, is_splitted:bool, is_merging:bool, governor_tile:TileForTilemap):
	self.src_pos_t = pos_t;
	self.world = world;
	self.is_splitted = is_splitted;
	self.is_merging = is_merging;
	self.pusher_entity_id = pusher_entity_id;
	self.transit_id = transit_id;
	position = GV.pos_t_to_world(pos_t);
	atlas_coords = new_atlas_coords;
	self.back_tile = back_tile;
	old_type_id = world.atlas_coords_to_type_id(old_atlas_coords);
	new_type_id = world.atlas_coords_to_type_id(new_atlas_coords);
	velocity = Vector2.ZERO;
	
	# set move_controller, sprites, and collision layers
	match transit_id:
		GV.TransitId.SLIDE:
			move_controller = TileForTilemapSlideController.new(self, dir);
			curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.MOVING, 1, [], null);
			set_collision_layer_value(GV.CollisionId.DEFAULT, true);
		GV.TransitId.SHIFT:
			move_controller = TileForTilemapShiftController.new(self, dir, target_dist_t);
			curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.MOVING, 1, [], null);
			set_collision_layer_value(GV.CollisionId.DEFAULT, true);
		GV.TransitId.SPLIT:
			prev_sprite = TileForTilemapSprite.new(self, tile_sheet, old_atlas_coords, GV.ZId.SPLITTING_OLD, 1, [GV.ConversionAnimatorId.DWING_FADE_OUT, GV.ConversionAnimatorId.DWING], governor_tile);
			curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.SPLITTING_NEW, 0, [GV.ConversionAnimatorId.DWING_FADE_IN, GV.ConversionAnimatorId.DWING], governor_tile);
			set_collision_layer_value(GV.CollisionId.SPLITTING, true);
		GV.TransitId.MERGE:
			prev_sprite = TileForTilemapSprite.new(self, tile_sheet, old_atlas_coords, GV.ZId.COMBINING_OLD, 1, [GV.ConversionAnimatorId.DUANG_FADE_OUT, GV.ConversionAnimatorId.DUANG], governor_tile);
			curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.COMBINING_NEW, 0, [GV.ConversionAnimatorId.DUANG_FADE_IN, GV.ConversionAnimatorId.DUANG], governor_tile);
			set_collision_layer_value(GV.CollisionId.COMBINING, true);

	if move_controller and old_type_id == GV.TypeId.PLAYER:
		set_collision_layer_value(GV.CollisionId.TRACKING_CAM, true);
	
	# set collision masks if tile moves
	if move_controller:
		set_collision_mask_value(GV.CollisionId.DEFAULT, true);
		if not is_splitted:
			set_collision_mask_value(GV.CollisionId.SPLITTING, true);
		if not is_merging:
			set_collision_mask_value(GV.CollisionId.COMBINING, true);
		if old_type_id != GV.TypeId.PLAYER:
			set_collision_mask_value(GV.CollisionId.MEMBRANE, true);
		if old_type_id in GV.T_ENEMY:
			set_collision_mask_value(GV.CollisionId.SAVE_OR_GOAL, true);
	
	# add sprites
	for sprite in [prev_sprite, curr_sprite]:
		if sprite:
			add_child(sprite);

func set_merger_tile(tile:TileForTilemap):
	self.merger_tile = tile;

func set_splitter_tile(tile:TileForTilemap):
	self.splitter_tile = tile;

func _ready() -> void:
	collision_shape.scale = GV.PLAYER_COLLIDER_SCALE * Vector2.ONE;

#pooled tiles do not call _physics_process() since it's only called if the node is present in the scene tree
func _physics_process(delta: float) -> void:
	if move_controller:
		if not move_controller.step(delta):
			#check if aligned
			var pos_t:Vector2i = GV.world_to_pos_t(position);
			var offset:Vector2 = position - GV.pos_t_to_world(pos_t); #this is the vector from nearest grid center (not intersection) to tile position
			var is_aligned:bool = (move_controller.dir.x and abs(offset.y) <= GV.SNAP_TOLERANCE) or \
									(move_controller.dir.y and abs(offset.x) <= GV.SNAP_TOLERANCE);
			finalize_transit(is_aligned, pos_t, move_controller.is_reversed);

# if governor and its splitter are reversed, governor should be responsible for finalizing (since it is entity key (if entity exists))
# merge governor finalizes to merger, which then finalizes to pos_t
# Type and Entity Key/Busy/Creation/Removal and TileMap and tiles_in_transient and tile_pool Changes
# MERGE Case 1: m: b->b, g: a->a
#	not reversed
#		on g.finalize,
#			m.entity.key does not change
#			m.entity.busy becomes false
#			g.entity is removed
#			tilemap does not change
#			add m to tiles_in_transient
#			return to pool
#		on m.finalize,
#			change m.entity.key to pos_t if not moving
#			set atlas_coords if not moving
#			remove m from tiles_in_transient if not moving (else already removed)
#			return to pool if not moving
#	reversed
#		on g.finalize,
#			set g.entity.key to pos_t
#			set g.entity.busy to false
#			set atlas_coords
#			return to pool
#		on m.finalize (this should occur on the same frame as g.finalize),
#			set m.entity.key to pos_t
#			set m.entity.busy to false
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
#			return to pool
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
#			return to pool
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
#			return to pool
#		on s.finalize,
#			change s.entity.key to pos_t if not moving
#			set atlas_coords if not moving
#			remove s from tiles_in_transient if not moving
#			return to pool if not moving
#	reversed
#		on g.finalize,
#			set g.entity.key to pos_t
#			set g.entity.busy to false
#			set unsplit atlas_coords at pos_t
#			return to pool
#		on s.finalize,
#			remove s.entity
#			return to pool
# SPLIT Case 2: s: a->REG, g: a->a, a != REG
#	not reversed
#		on g.finalize
#			change g.entity.key to pos_t
#			set g.busy to false
#			set s.busy to false
#			no need to remove s.entity since it was transferred to g
#			set atlas_coords at pos_t
#			add s to tiles_in_transient
#			return to pool
#		on s.finalize
#			set atlas_coords if not moving
#			remove s from tiles_in_transient if not moving
#			return to pool if not moving
#	reversed
#		on g.finalize
#			set g.entity.key to pos_t
#			set g.busy to false
#			set unsplit atlas_coords at pos_t
#			return to pool
#		on s.finalize
#			return to pool
func finalize_transit(is_aligned:bool, pos_t:Vector2i, is_reversed:bool):
	var tile_entity:Entity = world.get_entity(old_type_id, self);
	
	if move_controller is TileForTilemapSlideController:
		
	elif move_controller is TileForTilemapShiftController:
		if is_aligned:
			world.set_atlas_coords(GV.LayerId.TILE, pos_t, atlas_coords);
		
	else:
	
	# get tile_entity
	var is_merging_and_merged:bool = merger_tile and pos_t == merger_tile.src_pos_t; # NOTE assumes merger is aligned
	var is_splitter_and_reversed:bool = (transit_id == GV.TransitId.SPLIT and is_reversed);
	var entity_type_id:int = new_type_id if transit_id == GV.TransitId.MERGE else old_type_id;
	
	
	if is_aligned and not is_splitter_and_reversed:
		# update tilemap
		if not is_merging_and_merged:
			var final_atlas_coords:Vector2i = world.get_doubled_tile_atlas_coords(atlas_coords) if (is_splitted and is_reversed) else atlas_coords;
			world.set_atlas_coords(GV.LayerId.TILE, pos_t, final_atlas_coords);
		
		# update entity.pos_t
		if tile_entity:
			if is_merging_and_merged:
				tile_entity.set_entity_id_and_body(merger_tile.new_type_id, merger_tile);
			else:
				tile_entity.set_entity_id_and_pos_t(new_type_id, pos_t);

	# update entity.is_busy so it can try new premoves
	if tile_entity and transit_id in [GV.TransitId.SLIDE, GV.TransitId.SHIFT]:
		tile_entity.set_is_busy(false);
		
	
	#return to pool or prepare for next transition (by resetting properties that _init() doesn't）
	#if not aligned, assume type does not change
	if is_aligned:
		world.return_pooled_tile(self);
	else:
		#necessary since _init() does not reset these
		if prev_sprite:
			prev_sprite.queue_free();
			prev_sprite = null;
		move_controller = null;
		front_tile = null;
		back_tile = null;
		merger_tile = null;
		
		#unnecessary since these aren't technically used until the next _init()
		is_splitted = false;
		is_merging = false;
		old_type_id = new_type_id;
		pusher_entity_id = GV.EntityId.NONE;
		#transit_id = ?

func are_sprite_animators_finished() -> bool:
	return (not prev_sprite or prev_sprite.animators.is_empty()) and (not curr_sprite or curr_sprite.animators.is_empty());
