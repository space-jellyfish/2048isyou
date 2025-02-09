# all tiles in chain call move_and_collide() every physics frame
# if a tile (at any position in chain) detects collision that cannot bounce, it traverses linked list to reverse tiles in chain behind itself
# calls to reverse() should be deferred since step() depends on dir of collider
# recursion should occur in perform_reverse() so back tiles don't get duplicate reverse() calls
# there is no need to snap tile.position to grid since alternative_id will be reset
class_name TileForTilemapSlideController
extends TileForTilemapController;

# this flag is necessary to prevent duplicate reverse() calls for sliding tile
#	e.g. chain leader calls bounce() => first deferred reverse()
# 		(but not if recursion happens in end-of-frame idle time, so is_queued_for_reverse isn't necessary after all)
# 	self collided against squid feeder club => second deferred reverse()
#var is_queued_for_reverse:bool = false;
var remaining_dist:float;
var src_pos_t:Vector2i;
var dir:Vector2i;


func _init(tile:TileForTilemap, pos_t:Vector2i, dir:Vector2i):
	self.tile = tile;
	src_pos_t = pos_t;
	self.dir = dir;
	remaining_dist = GV.TILE_WIDTH - fposmod(Vector2(dir).dot(tile.position), GV.TILE_WIDTH);

#update position, remaining_dist
func move(delta:float):
	#update position
	var prev_position:Vector2 = tile.position;
	var target_step_dist:float = min(GV.TILE_SLIDE_SPEED * delta, remaining_dist);
	collision = tile.move_and_collide(target_step_dist * dir);
	
	#update remaining_dist
	var true_step_dist:float = Vector2(dir).dot(tile.position - prev_position);
	remaining_dist -= true_step_dist;
	
	#bounce if true_step_dist ~< target_step_dist? NAH, older slide should continue
	#bounce if ^ for 2+ frames in a row? NAH, allows two well-timed shifts to bounce a slide

#bounce, finalize_move (if applicable)
#returns false if movement has finished
func step():
	if remaining_dist <= GV.SNAP_TOLERANCE:
		#update TileMap (emit signal or call world.update_tilemap(); don't update tilemap directly)
		if not reversed:
			tile.world.finalize_move(src_pos_t, dir, tile.atlas_coords, tile.is_splitted, tile.is_merging);
		return false;
		
	elif collision:
		var collider:Node2D = collision.get_collider();
	
		#check if collision requires handling (front tile handles self reverse logic)
		if collider != tile.front_tile:
			#bounce self if collider can't bounce; collider should call its own bounce
			if collider is TileForTilemap:
				var collider_mover:TileForTilemapController = collider.move_controller;
				
				if collider_mover:
					if collider_mover is TileForTilemapShiftController:
						if collider_mover.dir.dot(dir):
							#parallel, do recursive move_and_collide() with test_only to decide bounce
							#continue if first non-shift collider is younger slide? yes, otherwise shift and slide can team up to bully self
							
						else:
							#perp
							bounce();
					elif collider_mover is TileForTilemapSlideController:
						if collider_mover.dir == -dir:
							#opposing slide
							if remaining_dist > collider_mover.remaining_dist:
								bounce();
							elif remaining_dist == collider_mover.remaining_dist and GV.tiebreak_priorities[tile.pusher_entity_id] <= GV.tiebreak_priorities[collider.pusher_entity_id]:
								bounce();
						elif not collider_mover.dir.dot(dir):
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
	detach_from_front_chain();
	call_deferred("reverse");

#upon self reverse
func detach_from_front_chain():
	if tile.front_tile:
		tile.front_tile.back_tile = null;
		tile.front_tile = null;

func reverse():
	reversed = not reversed;
	dir *= -1;
	remaining_dist = GV.TILE_WIDTH - remaining_dist;
	
	if tile.back_tile:
		tile.back_tile.move_controller.reverse();
