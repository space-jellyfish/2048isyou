class_name TileForTilemap
extends CharacterBody2D;

var src_pos_t:Vector2i;
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
var pusher_entity_id:int; #id of entity that initiated move, GV.EntityId.NONE if tile not moving

#var is_aligned:bool = true;


func _init(world:World, pusher_entity_id:int, transit_id:int, pos_t:Vector2i, dir:Vector2i, target_dist_t:int, tile_sheet:CompressedTexture2D, old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, back_tile:TileForTilemap, is_splitted:bool, is_merging:bool, governor_tile:TileForTilemap):
	self.src_pos_t = pos_t;
	self.world = world;
	self.is_splitted = is_splitted;
	self.is_merging = is_merging;
	self.pusher_entity_id = pusher_entity_id;
	position = GV.pos_t_to_world(pos_t);
	atlas_coords = new_atlas_coords;
	self.back_tile = back_tile;
	old_type_id = world.atlas_coords_to_type_id(old_atlas_coords);
	new_type_id = world.atlas_coords_to_type_id(new_atlas_coords);
	velocity = Vector2.ZERO;
	
	# set move_controller, sprites, and collision layers
	if old_type_id == GV.TypeId.PLAYER:
		set_collision_layer_value(GV.CollisionId.TRACKING_CAM, true);
	
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

#pooled tiles do not call _physics_process() since it's only called if the node is present in the scene tree
func _physics_process(delta: float) -> void:
	if move_controller:
		if not move_controller.step(delta):
			#check if aligned
			var pos_t:Vector2i = GV.world_to_pos_t(position);
			var offset:Vector2 = position - GV.pos_t_to_world(pos_t); #this is the vector from nearest grid center (not intersection) to tile position
			var is_aligned:bool = (move_controller.dir.x and abs(offset.y) <= GV.SNAP_TOLERANCE) or \
									(move_controller.dir.y and abs(offset.x) <= GV.SNAP_TOLERANCE);
			finalize_transit(is_aligned, pos_t);

func finalize_transit(is_aligned:bool, pos_t:Vector2i):
	# update entity.is_busy so it can try new premoves
	var tile_entity:Entity = world.get_entity(old_type_id, self);
	if tile_entity:
		tile_entity.set_is_busy(false);
	
	if is_aligned:
		print("finalize is aligned, old_type_id: ", old_type_id);
		#update tilemap, entity.pos_t, and tile pool
		world.set_atlas_coords(GV.LayerId.TILE, pos_t, atlas_coords);
		if tile_entity:
			if merger_tile:
				print("finalize to merger type_id: ", new_type_id);
				tile_entity.set_entity_id_and_body(merger_tile.old_type_id, merger_tile);
			else:
				print("finalize at ", pos_t);
				tile_entity.set_entity_id_and_pos_t(new_type_id, pos_t);
	
		world.return_pooled_tile(self);

func are_sprite_animators_finished() -> bool:
	return (not prev_sprite or prev_sprite.animators.is_empty()) and (not curr_sprite or curr_sprite.animators.is_empty());
