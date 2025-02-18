class_name TileForTilemapSpriteDuangAnimator
extends TileForTilemapSpriteAnimator;

var angle_rad:float = GV.DUANG_START_ANGLE;


#should sync to slide progress in case tile bounces
func step(delta:float):
	print("duang step");
	#if governor finished or governor past trigger threshold, Duang += duang_speed
	#else wait
	if not is_governor_tile_finished:
		var separation:float = Vector2(governor_tile.move_controller.dir).dot(sprite.tile.position - governor_tile.position);
		if separation >= GV.DUANG_TRIGGER_SEPARATION:
			return true;
			
	#progress scale animation
	angle_rad += anim_dir * GV.DUANG_SPEED;
	angle_rad = clamp(angle_rad, GV.DUANG_START_ANGLE, GV.DUANG_END_ANGLE);
	sprite.scale = GV.DUANG_FACTOR * sin(angle_rad) * Vector2.ONE;
	
	if is_governor_tile_finished and \
		((angle_rad == GV.DUANG_END_ANGLE and not is_reversed) or \
		(angle_rad == GV.DUANG_START_ANGLE and is_reversed)):
		finished.emit();
		return false;
	#if is_governor_tile_finished:
		#print("yay, duang slower");
	#if 	((angle_rad == GV.DUANG_END_ANGLE and not is_reversed) or \
		#(angle_rad == GV.DUANG_START_ANGLE and is_reversed)):
		#print("aww, waiting for governor");
	return true;
