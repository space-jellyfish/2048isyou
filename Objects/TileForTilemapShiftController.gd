#when shifting, tile should decelerate upon bounce and accelerate otherwise
#upon bounce, snap to nearest cell, even if heading in original shift dir (not reversed)
class_name TileForTilemapShiftController
extends TileForTilemapController;

var max_speed:float;
var src_pos_t:Vector2i;
var dir:Vector2i;
var remaining_dist:float;


func _init(tile:TileForTilemap, pos_t:Vector2i, dir:Vector2i, target_dist_t:int):
	self.tile = tile;
	src_pos_t = pos_t;
	self.dir = dir;
	remaining_dist = GV.TILE_WIDTH * target_dist_t;
	max_speed = target_dist_t * GV.TILE_WIDTH * GV.SHIFT_DISTANCE_TO_MAX_SPEED;

#update velocity (decelerate if bounce else accelerate)
func step(delta:float):
	#update position
	var prev_position:Vector2 = tile.position;
	tile.velocity = tile.velocity.lerp(max_speed * dir, GV.SHIFT_LERP_WEIGHT);
	tile.move_and_collide(tile.velocity * delta);
	
	#update remaining_dist
	var true_step_dist:float = Vector2(dir).dot(tile.position - prev_position);
	remaining_dist -= true_step_dist;

#returns true if bounce succeeds (not blocked by sliding tile)
#when bouncing, snap to nearest cell
func reverse():
	reversed = not reversed;
	dir *= -1;
	tile.velocity *= -1;
	remaining_dist = GV.TILE_WIDTH - fposmod(remaining_dist, GV.TILE_WIDTH);
