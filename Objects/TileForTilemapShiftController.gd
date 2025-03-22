#when shifting, tile should decelerate upon bounce and accelerate otherwise
class_name TileForTilemapShiftController
extends TileForTilemapController;

var max_speed:float;
var dir:Vector2i;
var remaining_dist:float;
var latest_pos_t:Vector2i;


func _init(tile:TileForTilemap, dir:Vector2i, target_dist_t:int):
	assert(tile.is_aligned);
	
	self.tile = tile;
	self.dir = dir;
	latest_pos_t = tile.pos_t;
	remaining_dist = GV.TILE_WIDTH * target_dist_t;
	max_speed = target_dist_t * GV.TILE_WIDTH * GV.SHIFT_DISTANCE_TO_MAX_SPEED;
	assert(max_speed >= GV.TILE_SLIDE_SPEED);

func step(delta:float):
	# accelerate, update position
	var prev_position:Vector2 = tile.position;
	tile.velocity = tile.velocity.lerp(max_speed * dir, GV.SHIFT_LERP_WEIGHT);
	tile.velocity = clamp(Vector2(dir).dot(tile.velocity), GV.TILE_SLIDE_SPEED, max_speed) * dir;
	var collision:KinematicCollision2D = tile.move_and_collide(tile.velocity * delta);
	# reset non-movement-axis coordinate bc perp collision can cause unalignment
	tile.position = Vector2(dir.abs()) * tile.position + (Vector2.ONE - Vector2(dir.abs())) * prev_position;
	
	# update remaining_dist
	var true_step_dist:float = Vector2(dir).dot(tile.position - prev_position);
	remaining_dist -= true_step_dist;
	
	# update latest_pos_t and NAV layer
	if not is_reversed and remaining_dist > GV.SNAP_TOLERANCE:
		var new_latest_pos_t:Vector2i = GV.world_to_pos_t(tile.position - 0.5 * GV.TILE_WIDTH * dir);
		if new_latest_pos_t != latest_pos_t:
			tile.world.remove_nav_id(latest_pos_t, GV.NAV_UNITS[-dir]);
			tile.world.remove_nav_id(latest_pos_t + dir, GV.NavId.ALL);
			tile.world.add_nav_id(new_latest_pos_t, GV.NAV_UNITS[-dir]);
			tile.world.add_nav_id(new_latest_pos_t + dir, GV.NavId.ALL);
			latest_pos_t = new_latest_pos_t;
	
	#emit moved signal
	if true_step_dist:
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
	# update NAV cells
	if tile.was_aligned:
		if is_reversed:
			tile.world.remove_nav_id(latest_pos_t, GV.NAV_TERMS[dir]);
			tile.world.add_nav_id(latest_pos_t - dir, GV.NAV_TERMS[-dir]);
		else:
			tile.world.remove_nav_id(latest_pos_t + dir, GV.NAV_TERMS[dir]);
			tile.world.add_nav_id(latest_pos_t, GV.NAV_TERMS[-dir]);
	
	dir *= -1;
	tile.velocity *= -1;
	remaining_dist = GV.TILE_WIDTH - fposmod(remaining_dist, GV.TILE_WIDTH);
	is_reversed = not is_reversed;
	reversed.emit();
