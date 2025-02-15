#when shifting, tile should decelerate upon bounce and accelerate otherwise
class_name TileForTilemapShiftController
extends TileForTilemapController;

var max_speed:float;
var dir:Vector2i;
var remaining_dist:float;


func _init(tile:TileForTilemap, dir:Vector2i, target_dist_t:int):
	#assume tile is aligned
	assert(not fmod(tile.position.x, GV.TILE_WIDTH) and not fmod(tile.position.y, GV.TILE_WIDTH));
	
	self.tile = tile;
	self.dir = dir;
	remaining_dist = GV.TILE_WIDTH * target_dist_t;
	max_speed = target_dist_t * GV.TILE_WIDTH * GV.SHIFT_DISTANCE_TO_MAX_SPEED;

func get_velocity(delta:float) -> Vector2:
	return tile.velocity.lerp(max_speed * dir, GV.SHIFT_LERP_WEIGHT);

func step(collision:KinematicCollision2D, true_step_dist:float) -> bool:
	#update remaining_dist
	remaining_dist -= true_step_dist;
	
	#bounce (with deceleration), update tilemap if shift finished
	if remaining_dist <= GV.SNAP_TOLERANCE:
		var pos_t:Vector2i = GV.world_to_pos_t(tile.position);
		var offset:Vector2 = tile.position - GV.pos_t_to_world(pos_t); #this is the vector from nearest grid center (not intersection) to tile position
		if (dir.x and abs(offset.y) <= GV.SNAP_TOLERANCE) or \
			(dir.y and abs(offset.x) <= GV.SNAP_TOLERANCE):
			tile.world.set_atlas_coords(GV.LayerId.TILE, pos_t, tile.atlas_coords);
		return false;
		
	elif collision:
		reverse();
	
	return true;

#returns true if bounce succeeds (not blocked by sliding tile)
#after reverse, snap to nearest cell, even if heading in original shift dir (not reversed)
func reverse():
	reversed = not reversed;
	dir *= -1;
	tile.velocity *= -1;
	remaining_dist = GV.TILE_WIDTH - fposmod(remaining_dist, GV.TILE_WIDTH);
