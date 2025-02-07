#is_pushed_by_slide is used by sliding tiles to determine whether to bounce or not
#remember to clear it at the end of each frame
#when shifting, tile should decelerate upon bounce and accelerate otherwise
class_name TileForTilemapShiftAnimator
extends TileForTilemapAnimator;

var src_pos_t:Vector2i;
var dir:Vector2i;
var remaining_dist_px:int;
var is_pushed_by_slide:Dictionary = {
	Vector2i(1, 0) : false,
	Vector2i(-1, 0) : false,
	Vector2i(0, 1) : false,
	Vector2i(0, -1) : false,
};


func _init(tile:TileForTilemap, pos_t:Vector2i, dir:Vector2i, target_dist_t:int):
	self.tile = tile;
	
	src_pos_t = pos_t;
	self.dir = dir;
	remaining_dist_px = GV.TILE_WIDTH * target_dist_t;

func move(delta:float):
	pass;

func step():
	pass;

#returns true if bounce succeeds (not blocked by sliding tile)
#when bouncing, snap to nearest cell
func reverse():
	pass;
