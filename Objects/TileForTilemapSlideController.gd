# all tiles in chain call move_and_collide() every physics frame
# leading tiles are added to tree first to make use of tree order,
# so all tiles in the same chain are touching between physics frames

# if a tile (at any position in chain) detects collision that cannot bounce, it traverses linked list to reverse tiles in chain behind itself
# calls to reverse() should be deferred since step() depends on dir of collider
# recursion should occur in perform_reverse() so back tiles don't get duplicate reverse() calls

# step() was previously split into two separate functions (move(delta) and step()) to find
# opposing slides' avg collision position (for tiebreaking) and ShiftAnimator.is_pushed_by_slide
# since both vars are deprecated, move()/step() were recombined
# remaining_dist is currently used for tiebreaking (remaining_dist updates should be deferred)
class_name TileForTilemapSlideController
extends TileForTilemapController;

# this flag is necessary to prevent duplicate reverse() calls for sliding tile
#	e.g. chain leader calls bounce() => first deferred reverse()
# 		(but not if recursion happens in end-of-frame idle time, so is_queued_for_reverse isn't necessary after all)
# 	self collided against squid feeder club => second deferred reverse()
#var is_queued_for_reverse:bool = false;
var remaining_dist:float;
var dir:Vector2i;


func _init(tile:TileForTilemap, dir:Vector2i):
	self.tile = tile;
	self.dir = dir;
	remaining_dist = GV.TILE_WIDTH - fposmod(Vector2(dir).dot(tile.position - Vector2(GV.TILE_WIDTH, GV.TILE_WIDTH) / 2), GV.TILE_WIDTH);

#returns false if movement has finished
func step(delta:float):
	#update position
	var prev_position:Vector2 = tile.position;
	var target_step_dist:float = min(GV.TILE_SLIDE_SPEED * delta, remaining_dist);
	var collision:KinematicCollision2D = tile.move_and_collide(target_step_dist * dir);

	#update remaining_dist
	var true_step_dist:float = Vector2(dir).dot(tile.position - prev_position);
	var new_remaining_dist:float = remaining_dist - true_step_dist;
	call_deferred("set_remaining_dist", new_remaining_dist);
	
	#emit moved signal
	if GV.tracking_cam_trigger_mode == GV.TrackingCamTriggerMode.LEAVE_AREA and true_step_dist:
		tile.moved.emit();
	
	#bounce, finalize slide (if applicable)
	#bounce if true_step_dist ~< target_step_dist? NAH, older slide should continue
	#bounce if ^ for 2+ frames in a row? NAH, allows two well-timed shifts to bounce a slide
	if new_remaining_dist <= GV.SNAP_TOLERANCE:
		finished.emit();
		return false;
		
	elif collision:
		var collider:Node2D = collision.get_collider();
	
		#check if collision requires handling (front tile handles self reverse logic)
		if collider != tile.front_tile and Vector2(dir).dot(collision.get_normal()):
			#bounce self if collider can't bounce; collider should call its own bounce
			if collider is TileForTilemap:
				var collider_mover:TileForTilemapController = collider.move_controller;
				
				if collider_mover:
					if collider_mover is TileForTilemapShiftController:
						if collider_mover.dir.dot(dir):
							#parallel, do recursive move_and_collide() with test_only to decide bounce
							#continue if first non parallel-and-shifting collider is younger opposing slide? yes, otherwise shift and slide can team up to bully self
							
							#find first non parallel-and-shifting collider
							var virtual_collider:Node2D = collider;
							while virtual_collider is TileForTilemap and virtual_collider.move_controller is TileForTilemapShiftController and virtual_collider.move_controller.dir.dot(dir):
								var virtual_collision:KinematicCollision2D = virtual_collider.move_and_collide(dir * GV.COLLISION_TEST_DISTANCE, true);
								virtual_collider = virtual_collision.get_collider() if virtual_collision else null;
							
							if not virtual_collider:
								pass;
							elif virtual_collider is TileForTilemap and virtual_collider.move_controller is TileForTilemapSlideController and virtual_collider.move_controller.dir == -dir and not should_bounce(virtual_collider):
								pass;
							else:
								bounce();
						else:
							#perp
							bounce();
					elif collider_mover is TileForTilemapSlideController:
						if collider_mover.dir == -dir:
							#opposing slide
							if should_bounce(collider):
								bounce();
						elif not Vector2(collider_mover.dir).dot(Vector2(dir)):
							#perp
							bounce();
						#else tailing another slide; don't chain bc different chains should bounce independently
					elif collider_mover is TileForTilemapRoamController:
						bounce();
				else: #colliding tile isn't moving
					bounce();
			else: #collider isn't tile
				bounce();
	
	return true;

func bounce():
	detach_from_leader();
	call_deferred("reverse");

#upon self reverse
func detach_from_leader():
	if not is_reversed:
		if tile.front_tile:
			tile.front_tile.back_tile = null;
			tile.front_tile = null;
	else:
		if tile.back_tile:
			tile.back_tile.front_tile = null;
			tile.back_tile = null;

func reverse():
	dir *= -1;
	remaining_dist = GV.TILE_WIDTH - remaining_dist;
	
	if not is_reversed:
		if tile.back_tile and tile.back_tile.move_controller:
			tile.back_tile.move_controller.reverse();
	else:
		if tile.front_tile and tile.front_tile.move_controller:
			tile.front_tile.move_controller.reverse();
	
	is_reversed = not is_reversed;
	reversed.emit();

func set_remaining_dist(dist:float):
	remaining_dist = dist;

# assume collider is an opposing slide
# return true if self should bounce (slide has greater or equal move priority)
# and false if self should continue
# NOTE: may return true for both self and opposing slide
func should_bounce(collider:TileForTilemap):
	var collider_mover:TileForTilemapSlideController = collider.move_controller;
	assert(collider_mover.dir == -dir);
	
	if remaining_dist > collider_mover.remaining_dist:
		return true;
	elif remaining_dist == collider_mover.remaining_dist and GV.slide_priorities[tile.pusher_entity_id] <= GV.slide_priorities[collider.pusher_entity_id]:
		return true;
	return false;
