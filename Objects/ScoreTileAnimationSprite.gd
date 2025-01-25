class_name ScoreTileAnimationSprite
extends Sprite2D;

var animators:Array;


func _init(sprite_sheet:CompressedTexture2D, tile_atlas_coords:Vector2i, pos_t:Vector2i):
	#set position and offset
	position = pos_t * GV.TILE_WIDTH;
	centered = false;
	
	#set texture
	hframes = GV.TILE_SHEET_HFRAMES;
	vframes = GV.TILE_SHEET_VFRAMES;
	frame_coords = tile_atlas_coords;
	texture = sprite_sheet;

func _physics_process(delta:float) -> void:
	for animator in animators:
		if not animator.step(delta):
			animator.queue_free();
			animators.erase(animator);
	if animators.is_empty():
		#send signal to remove self from world.animat
		queue_free();

func add_animator(animator_id:int, dir:Vector2i):
	var animator:ScoreTileAnimator;
	
	match animator_id:
		GV.AnimatorId.SLIDE:
			animator = ScoreTileSlideAnimator.new();
		GV.AnimatorId.SHIFT:
			animator = ScoreTileShiftAnimator.new();
		GV.AnimatorId.DWING:
			animator = ScoreTileDwingAnimator.new();
		GV.AnimatorId.DUANG:
			animator = ScoreTileDuangAnimator.new();
		GV.AnimatorId.FADE_IN:
			animator = ScoreTileFadeAnimator.new();
		GV.AnimatorId.FADE_OUT:
			animator = ScoreTileFadeAnimator.new();
	
	animators.add(animator);
