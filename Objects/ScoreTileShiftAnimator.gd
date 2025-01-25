class_name ScoreTileShiftAnimator
extends ScoreTileAnimator;


var slide_dir:Vector2i;
var remaining_dist_px:int;

func _init(sprite_sheet:CompressedTexture2D, tile_atlas_coords:Vector2i, pos_t:Vector2i, dir:Vector2i):
	super._init(sprite_sheet, tile_atlas_coords, pos_t, dir);
	
	slide_dir = dir;
	remaining_dist_px = GV.TILE_WIDTH * anim_dist_t;

func step(s:ScoreTileAnimator, delta:float):
	s.position += GV.TILE_SLIDE_SPEED * delta * slide_dir;
	
	
