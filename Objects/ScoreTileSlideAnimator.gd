class_name ScoreTileSlideAnimator
extends ScoreTileAnimator;


var dir:Vector2i;
var remaining_dist:float;

func _init(sprite_sheet:CompressedTexture2D, tile_atlas_coords:Vector2i, pos_t:Vector2i, dir:Vector2i):
	super._init(sprite_sheet, tile_atlas_coords, pos_t);
	
	self.dir = dir;
	remaining_dist = GV.TILE_WIDTH;

func step(delta:float):
	var step_dist:float = min(GV.TILE_SLIDE_SPEED * delta, remaining_dist);
	position += step_dist * dir;
	remaining_dist -= step_dist;
	return bool(remaining_dist);
	
	#TODO check for bounce
	
	#TODO upon COMBINING_MERGE_RATIO, add merge animators if merge_pos_t has tile
