# all tiles in chain call move_and_collide() every physics frame
# if a tile (at any position in chain) detects collision that cannot bounce, it traverses linked list to reverse tiles in chain behind itself
# calls to reverse() should be deferred since step() depends on dir of collider
# recursion should occur in perform_reverse() so back tiles don't get duplicate reverse() calls
# there is no need to snap tile.position to grid since alternative_id will be reset
class_name TileForTilemapSlideAnimator
extends TileForTilemapAnimator;

# this flag is necessary to prevent duplicate reverse() calls for sliding tile
#	e.g. chain leader calls bounce() => first deferred reverse()
# 		(but not if recursion happens in end-of-frame idle time, so is_queued_for_reverse isn't necessary after all)
# 	self collided against squid feeder club => second deferred reverse()
#var is_queued_for_reverse:bool = false;
const speed:float = GV.TILE_SLIDE_SPEED;
var remaining_dist:float;
var src_pos_t:Vector2i;
var dir:Vector2i;


func _init(tile:TileForTilemap, pos_t:Vector2i, dir:Vector2i):
	self.tile = tile;
	src_pos_t = pos_t;
	self.dir = dir;
	remaining_dist = GV.TILE_WIDTH - fposmod(Vector2(dir).dot(tile.position), GV.TILE_WIDTH);

#update step_dist, position, ShiftAnimator.is_pressed_by_slide
#instead of finding avg collision pos, let tile with lower remaining_dist continue
func move(delta:float):
	var prev_position:Vector2 = tile.position;
	var target_step_dist:float = min(speed * delta, remaining_dist);
	collision = tile.move_and_collide(target_step_dist * dir);
	
	#update remaining_dist
	var true_step_dist:float = Vector2(dir).dot(tile.position - prev_position);
	remaining_dist -= true_step_dist;
	
	if collision:
		var collider:Node2D = collision.get_collider();
		if collider is TileForTilemap:
			if collider.move_animator is TileForTilemapShiftAnimator:
				collider.move_animator.is_pressed_by_slide[dir] = true;

#bounce, finalize_move (if applicable)
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
				var collider_mover:TileForTilemapAnimator = collider.move_animator;
				if collider_mover:
					if collider_mover.dir == -dir:
						if collider_mover is TileForTilemapShiftAnimator:
							if collider_mover.is_pressed_by_slide[-dir]:
								bounce();
						elif collider_mover is TileForTilemapSlideAnimator:
							if remaining_dist > collider_mover.remaining_dist:
								bounce();
							elif remaining_dist == collider_mover.remaining_dist and GV.move_priorities[tile.pusher_entity_id] <= GV.move_priorities[collider.pusher_entity_id]:
								bounce();
					elif collider_mover.dir == dir:
						if collider_mover is TileForTilemapShiftAnimator:
							if collider_mover.is_pressed_by_slide[-dir]:
								bounce();
						elif collider_mover is TileForTilemapSlideAnimator:
							#don't (re)join chains bc different chains should bounce() independently
							pass;
			else:
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
	dir *= -1;
	remaining_dist = GV.TILE_WIDTH - remaining_dist;
	reversed = not reversed;
	
	if tile.back_tile:
		tile.back_tile.move_animator.reverse();
