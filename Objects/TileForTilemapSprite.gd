class_name TileForTilemapSprite
extends Sprite2D

var tile:TileForTilemap;
var animators:Dictionary; #animator_type -> animator


func _init(tile:TileForTilemap, tile_sheet:CompressedTexture2D, tile_atlas_coords:Vector2i, z_index:int, initial_alpha:float, conversion_anim_ids:Array[int], governor_tile:TileForTilemap):
	self.tile = tile;
	self.z_index = z_index;
	modulate.a = initial_alpha;
	
	for anim_id in conversion_anim_ids:
		add_animator(anim_id, governor_tile);

	#set texture
	hframes = GV.TILE_SHEET_HFRAMES;
	vframes = GV.TILE_SHEET_VFRAMES;
	frame_coords = tile_atlas_coords;
	texture = tile_sheet;

func _process(delta:float) -> void:
	for key in animators.keys():
		var animator:TileForTilemapSpriteAnimator = animators[key];
		
		if not animator.step(delta):
			animators.erase(key);
			
			if tile.are_sprite_animators_finished():
				tile.finalize_transit(true, tile.src_pos_t);

func add_animator(conversion_anim_id:int, governor_tile:TileForTilemap):
	var anim_type:int = GV.get_animator_type(conversion_anim_id);
	var animator:TileForTilemapSpriteAnimator;
	
	match conversion_anim_id:
		GV.ConversionAnimatorId.DWING:
			animator = TileForTilemapSpriteDwingAnimator.new(self, governor_tile);
		GV.ConversionAnimatorId.DUANG:
			animator = TileForTilemapSpriteDuangAnimator.new(self, governor_tile);
		GV.ConversionAnimatorId.DUANG_FADE_IN:
			animator = TileForTilemapSpriteFadeAnimator.new(self, 1, governor_tile, GV.DUANG_TRIGGER_SEPARATION);
		GV.ConversionAnimatorId.DUANG_FADE_OUT:
			animator = TileForTilemapSpriteFadeAnimator.new(self, -1, governor_tile, GV.DUANG_TRIGGER_SEPARATION);
		GV.ConversionAnimatorId.DWING_FADE_IN:
			animator = TileForTilemapSpriteFadeAnimator.new(self, 1, governor_tile, 0);
		GV.ConversionAnimatorId.DWING_FADE_OUT:
			animator = TileForTilemapSpriteFadeAnimator.new(self, -1, governor_tile, 0);
	
	assert(animators.get(anim_type) == null);
	animators[anim_type] = animator;
