# all tiles in chain call move_and_collide() every physics frame
# if a tile (at any position in chain) detects collision that cannot bounce, it traverses linked list to reverse tiles in chain behind itself
# calls to reverse() should be deferred so all move_and_collide()s in current frame go in right direction
# there is no need to snap tile.position to grid since alternative_id will be reset
class_name TileForTilemapSlideAnimator
extends TileForTilemapAnimator;

const speed:float = GV.TILE_SLIDE_SPEED;
var step_dist:float;
var remaining_dist:float;
var src_pos_t:Vector2i;
var dir:Vector2i;


func _init(tile:TileForTilemap, pos_t:Vector2i, dir:Vector2i):
	self.tile = tile;
	src_pos_t = pos_t;
	self.dir = dir;
	remaining_dist = GV.TILE_WIDTH - fposmod(Vector2(dir).dot(tile.position), GV.TILE_WIDTH);

#update step_dist, position, ShiftAnimator.is_pushed_by_slide, and avg collision position between head-on slides
func move(delta:float):
	step_dist = min(speed * delta, remaining_dist);
	var collision:KinematicCollision2D = tile.move_and_collide(step_dist * dir);
	if collision:
		var collider:Node2D = collision.get_collider();
		if collider is TileForTilemap:
			if collider.move_animator is TileForTilemapShiftAnimator:
				

func step():
	#update remaining_dist
	remaining_dist -= step_dist;
	
	#check for collision
	if collision:
		var collider:Node2D = collision.get_collider();
	
		#check if collision requires handling
		if collider != tile.front_tile and is_collision_before_snap(collision):
			var bounce_self:bool = true;
			
			#try to bounce collider
			if collider is TileForTilemap:
				var collider_mover:TileForTilemapAnimator = collider.move_animator;
				if collider_mover:
					if collider_mover.dir == -dir:
						if collider_mover is TileForTilemapShiftAnimator:
							collider_mover.bounce();
							return true;
						elif collider_mover is TileForTilemapSlideAnimator:
							
					elif collider_mover.dir == dir:
						if collider_mover is TileForTilemapShiftAnimator:
							
						elif collider_mover is TileForTilemapSlideAnimator:
							
						
			
			#bounce self if collider can't bounce
			return true;
	
	if not remaining_dist:
		#update TileMap (emit signal or call world.update_tilemap(); don't update tilemap directly)
		if not reversed:
			tile.world.finalize_move(src_pos_t, dir, tile.atlas_coords, tile.is_splitted, tile.is_merging);
		return false;
	return true;

func bounce():
	detach_from_front_chain();
	queue_reverse();

#upon self reverse
func detach_from_front_chain():
	if tile.front_tile:
		tile.front_tile.back_tile = null;
		tile.front_tile = null;

func queue_reverse():
	if not is_reverse_queued:
		is_reverse_queued = true;
		call_deferred("perform_reverse");
	if tile.back_tile:
		tile.back_tile.move_animator.queue_reverse();

func perform_reverse():
	reversed = not reversed;
	dir *= -1;
	remaining_dist = GV.TILE_WIDTH - remaining_dist;
	is_reverse_queued = false;

#returns whether bounce was successful
func try_bounce():
	pass;

# assume position (via move_and_collide()) and remaining_dist are updated
# use collision.get_position() to handle different collider types
func is_collision_before_snap(collision:KinematicCollision2D) -> bool:
	return remaining_dist + 0.5 * GV.TILE_WIDTH - (collision.get_position() - tile.position).length() > GV.SNAP_TOLERANCE;
