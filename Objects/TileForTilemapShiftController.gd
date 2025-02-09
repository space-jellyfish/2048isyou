#remember to clear it at the end of each frame
#when shifting, tile should decelerate upon bounce and accelerate otherwise
#upon bounce, snap to nearest cell (even if not reversed)
class_name TileForTilemapShiftController
extends TileForTilemapController;

var max_speed:float;
var src_pos_t:Vector2i;
var dir:Vector2i;
var remaining_dist:float;

# used by sliding tiles to determine whether to bounce or not
# slides approaching from ~ side should bounce if priority_frames non-zero
# decremented each frame
var front_slide_priority_frames:int = 0;
var back_slide_priority_frames:int = 0;


func _init(tile:TileForTilemap, pos_t:Vector2i, dir:Vector2i, target_dist_t:int):
	self.tile = tile;
	src_pos_t = pos_t;
	self.dir = dir;
	remaining_dist = GV.TILE_WIDTH * target_dist_t;
	max_speed = target_dist_t * GV.TILE_WIDTH * GV.SHIFT_DISTANCE_TO_MAX_SPEED;

#update position, remaining_dist
#update priority_frames (decrement if nonzero and set if collider has move_priority over slide or colliding_shift.priority_frames)
#update velocity (decelerate if bounce else accelerate)
func move(delta:float):
	#update priority_frames
	if front_slide_priority_frames > 0:
		front_slide_priority_frames -= 1;
	if back_slide_priority_frames > 0:
		back_slide_priority_frames -= 1;
	
	#update position
	var prev_position:Vector2 = tile.position;
	tile.velocity = tile.velocity.lerp(max_speed * dir, GV.SHIFT_LERP_WEIGHT);
	tile.move_and_collide(tile.velocity * delta);
	
	#update remaining_dist
	var true_step_dist:float = Vector2(dir).dot(tile.position - prev_position);
	remaining_dist -= true_step_dist;
	
	if collision:
		var collider:Node2D = collision.get_collider();
		if collider is TileForTilemap:
			var collider_mover:TileForTilemapController = collider.move_controller;
			if collider_mover:
				if collider_mover is TileForTilemapSlideController:
					front_slide_priority_frames = GV.SHIFT_PRIORITY_DURATION;
				elif collider_mover is TileForTilemapShiftController:
					
		else:
			front_slide_priority_frames = GV.SHIFT_PRIORITY_DURATION;
	
func step():
	pass;

#returns true if bounce succeeds (not blocked by sliding tile)
#when bouncing, snap to nearest cell
func reverse():
	reversed = not reversed;
	dir *= -1;
	tile.velocity *= -1;
	remaining_dist = GV.TILE_WIDTH - fposmod(remaining_dist, GV.TILE_WIDTH);
	swap_priority_frames();

func swap_priority_frames():
	var temp:int = front_slide_priority_frames;
	front_slide_priority_frames = back_slide_priority_frames;
	back_slide_priority_frames = temp;
