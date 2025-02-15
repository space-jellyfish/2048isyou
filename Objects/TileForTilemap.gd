class_name TileForTilemap
extends AnimatableBody2D;

var atlas_coords:Vector2i;
var curr_sprite:TileForTilemapSprite;
var prev_sprite:TileForTilemapSprite;
var move_controller:TileForTilemapController;
var front_tile:TileForTilemap; #in direction of initial action
var back_tile:TileForTilemap; #in direction of initial action
var world:World;
var is_splitted:bool;
var is_merging:bool;
var type_id:int;
var pusher_entity_id:int; #id of entity that initiated move, GV.EntityId.NONE if tile not moving

#var is_aligned:bool = true;


func _init(world:World, transit_id:int, pos_t:Vector2i, dir:Vector2i, target_dist_t:int, tile_sheet:CompressedTexture2D, old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, back_tile:TileForTilemap, is_splitted:bool, is_merging:bool, governor_tile:TileForTilemap, pusher_entity_id:int):
	self.world = world;
	self.is_splitted = is_splitted;
	self.is_merging = is_merging;
	self.pusher_entity_id = pusher_entity_id;
	position = GV.pos_t_to_world(pos_t);
	atlas_coords = new_atlas_coords;
	self.back_tile = back_tile;
	type_id = get_type_id(new_atlas_coords);
	
	# set move_controller, sprites, and collision layers
	if type_id == GV.TypeId.PLAYER:
		set_collision_layer_value(GV.CollisionId.TRACKING_CAM, true);
	
	match transit_id:
		GV.TransitId.SLIDE:
			move_controller = TileForTilemapSlideController.new(self, dir);
			curr_sprite = TileForTilemapSprite.new(tile_sheet, new_atlas_coords, GV.ZId.MOVING, [], true, null);
			set_collision_layer_value(GV.CollisionId.DEFAULT, true);
		GV.TransitId.SHIFT:
			move_controller = TileForTilemapShiftController.new(self, dir, target_dist_t);
			curr_sprite = TileForTilemapSprite.new(tile_sheet, new_atlas_coords, GV.ZId.MOVING, [], true, null);
			set_collision_layer_value(GV.CollisionId.DEFAULT, true);
		GV.TransitId.SPLIT:
			prev_sprite = TileForTilemapSprite.new(tile_sheet, old_atlas_coords, GV.ZId.SPLITTING_OLD, [GV.ConversionAnimatorId.FADE_OUT, GV.ConversionAnimatorId.DWING], false, governor_tile);
			curr_sprite = TileForTilemapSprite.new(tile_sheet, new_atlas_coords, GV.ZId.SPLITTING_NEW, [GV.ConversionAnimatorId.FADE_IN, GV.ConversionAnimatorId.DWING], false, governor_tile);
			set_collision_layer_value(GV.CollisionId.SPLITTING, true);
		GV.TransitId.MERGE:
			prev_sprite = TileForTilemapSprite.new(tile_sheet, old_atlas_coords, GV.ZId.COMBINING_OLD, [GV.ConversionAnimatorId.FADE_OUT, GV.ConversionAnimatorId.DUANG], true, governor_tile);
			curr_sprite = TileForTilemapSprite.new(tile_sheet, new_atlas_coords, GV.ZId.COMBINING_NEW, [GV.ConversionAnimatorId.FADE_IN, GV.ConversionAnimatorId.DUANG], true, governor_tile);
			set_collision_layer_value(GV.CollisionId.COMBINING, true);
	
	# set collision masks if tile moves
	if move_controller:
		set_collision_mask_value(GV.CollisionId.DEFAULT, true);
		if not is_splitted:
			set_collision_mask_value(GV.CollisionId.SPLITTING, true);
		if not is_merging:
			set_collision_mask_value(GV.CollisionId.COMBINING, true);
		if type_id != GV.TypeId.PLAYER:
			set_collision_mask_value(GV.CollisionId.MEMBRANE, true);
		if type_id in GV.T_ENEMY:
			set_collision_mask_value(GV.CollisionId.SAVE_OR_GOAL, true);
	
	# add sprites
	for sprite in [prev_sprite, curr_sprite]:
		if sprite:
			add_child(sprite);

func _physics_process(delta: float) -> void:
	if move_controller and not move_controller.step(delta):
		move_controller.queue_free();
		move_controller = null;

func get_type_id(atlas_coords:Vector2i):
	assert(atlas_coords.y != -1);
	return atlas_coords.y;
