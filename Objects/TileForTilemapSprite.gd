class_name TileForTilemapSprite
extends Sprite2D


signal freed;
var tile:TileForTilemap;
var animators:Dictionary; #animator_type -> animator
var governor_tile:TileForTilemap;


func _init(tile:TileForTilemap, tile_sheet:CompressedTexture2D, tile_atlas_coords:Vector2i, z_index:int, conversion_anim_ids:Array[int], governor_tile:TileForTilemap):
	self.tile = tile;
	self.z_index = z_index;
	self.governor_tile = governor_tile;
	for anim_id in conversion_anim_ids:
		add_animator(anim_id, governor_tile);

	#set texture
	hframes = GV.TILE_SHEET_HFRAMES;
	vframes = GV.TILE_SHEET_VFRAMES;
	frame_coords = tile_atlas_coords;
	texture = tile_sheet;

func _physics_process(delta:float) -> void:
	for key in animators.keys():
		var animator:TileForTilemapSpriteAnimator = animators[key];
		
		if not animator.step(delta):
			animators.erase(key);

func add_animator(conversion_anim_id:int, governor_tile:TileForTilemap):
	var anim_type:int = GV.get_animator_type(conversion_anim_id);
	var animator:TileForTilemapSpriteAnimator;
	
	match conversion_anim_id:
		GV.ConversionAnimatorId.DWING:
			animator = TileForTilemapSpriteDwingAnimator.new(self, governor_tile);
		GV.ConversionAnimatorId.DUANG:
			animator = TileForTilemapSpriteDuangAnimator.new(self, governor_tile);
		GV.ConversionAnimatorId.FADE_IN:
			animator = TileForTilemapSpriteFadeAnimator.new(self, governor_tile);
		GV.ConversionAnimatorId.FADE_OUT:
			animator = TileForTilemapSpriteFadeAnimator.new(self, governor_tile);
	
	assert(animators.get(anim_type) == null);
	animators[anim_type] = animator;
