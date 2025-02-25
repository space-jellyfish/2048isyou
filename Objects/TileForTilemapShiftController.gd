#when shifting, tile should decelerate upon bounce and accelerate otherwise
class_name TileForTilemapShiftController
extends TileForTilemapController;

var max_speed:float;
var dir:Vector2i;
var remaining_dist:float;


func _init(tile:TileForTilemap, dir:Vector2i, target_dist_t:int):
	#assume tile is aligned
	assert(fposmod(tile.position.x, GV.TILE_WIDTH) == 0.5 * GV.TILE_WIDTH);
	assert(fposmod(tile.position.y, GV.TILE_WIDTH) == 0.5 * GV.TILE_WIDTH);
	
	self.tile = tile;
	self.dir = dir;
	remaining_dist = GV.TILE_WIDTH * target_dist_t;
	max_speed = target_dist_t * GV.TILE_WIDTH * GV.SHIFT_DISTANCE_TO_MAX_SPEED;
	assert(max_speed >= GV.TILE_SLIDE_SPEED);

func step(delta:float):
	# accelerate, update position
	var prev_position:Vector2 = tile.position;
	tile.velocity = tile.velocity.lerp(max_speed * dir, GV.SHIFT_LERP_WEIGHT);
	tile.velocity = clamp(Vector2(dir).dot(tile.velocity), GV.TILE_SLIDE_SPEED, max_speed) * dir;
	var collision:KinematicCollision2D = tile.move_and_collide(tile.velocity * delta);
	
	#update remaining_dist
	var true_step_dist:float = Vector2(dir).dot(tile.position - prev_position);
	remaining_dist -= true_step_dist;
	
	#emit moved signal
	if GV.tracking_cam_trigger_mode == GV.TrackingCamTriggerMode.LEAVE_AREA and true_step_dist:
		tile.moved.emit();
	
	#bounce (with deceleration), update tilemap if shift finished
	if remaining_dist <= GV.SNAP_TOLERANCE:
		finished.emit();
		return false;
		
	elif collision:
		# decelerate, reverse
		tile.velocity *= GV.SHIFT_BOUNCE_DECELERATION;
		tile.velocity = clamp(Vector2(dir).dot(tile.velocity), GV.TILE_SLIDE_SPEED, max_speed) * dir;
		reverse();
	
	return true;

#returns true if bounce succeeds (not blocked by sliding tile)
#after reverse, snap to nearest cell, even if heading in original shift dir (not reversed)
func reverse():
	dir *= -1;
	tile.velocity *= -1;
	remaining_dist = GV.TILE_WIDTH - fposmod(remaining_dist, GV.TILE_WIDTH);
	is_reversed = not is_reversed;
	reversed.emit();
