class_name TileForTilemapSprite
extends Sprite2D


signal freed;
var animators:Dictionary; #animator_type -> animator
var animators_paused:bool;
var governor_tile:TileForTilemap;


func _init(tile_sheet:CompressedTexture2D, tile_atlas_coords:Vector2i, z_index:int, conversion_anim_ids:Array[int], animators_paused:bool, governor_tile:TileForTilemap):
	self.z_index = z_index;
	
	#set texture
	hframes = GV.TILE_SHEET_HFRAMES;
	vframes = GV.TILE_SHEET_VFRAMES;
	frame_coords = tile_atlas_coords;
	texture = tile_sheet;
	
	#add animators
	for anim_id in conversion_anim_ids:
		add_animator(anim_id);
	self.animators_paused = animators_paused;
	self.governor_tile = governor_tile; # if null/queued_for_deletion() => slide finished => finish sprite animations immediately

func _physics_process(delta:float) -> void:
	if not animators_paused:
		for key in animators.keys():
			var animator:TileForTilemapSpriteAnimator = animators[key];
			
			if not animator.step(delta):
				animator.queue_free();
				animators.erase(key);

func add_animator(conversion_anim_id:int):
	var anim_type:int = GV.get_animator_type(conversion_anim_id);
	var animator:TileForTilemapSpriteAnimator;
	
	match conversion_anim_id:
		GV.ConversionAnimatorId.DWING:
			animator = TileForTilemapSpriteDwingAnimator.new(self);
		GV.ConversionAnimatorId.DUANG:
			animator = TileForTilemapSpriteDuangAnimator.new(self);
		GV.ConversionAnimatorId.FADE_IN:
			animator = TileForTilemapSpriteFadeAnimator.new(self);
		GV.ConversionAnimatorId.FADE_OUT:
			animator = TileForTilemapSpriteFadeAnimator.new(self);
	
	assert(animators.get(anim_type) == null);
	animators[anim_type] = animator;
