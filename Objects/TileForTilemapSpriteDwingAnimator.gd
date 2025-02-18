class_name TileForTilemapSpriteDwingAnimator
extends TileForTilemapSpriteAnimator;

var angle_rad:float = GV.DWING_START_ANGLE;


#should sync to slide progress in case tile bounces
func step(delta:float):
	#progress scale animation
	angle_rad += anim_dir * GV.DWING_SPEED;
	angle_rad = clamp(angle_rad, GV.DWING_START_ANGLE, GV.DWING_END_ANGLE);
	sprite.scale = GV.DWING_FACTOR / sin(angle_rad) * Vector2.ONE;
	
	if is_governor_tile_finished and \
		((angle_rad == GV.DWING_END_ANGLE and not is_reversed) or \
		(angle_rad == GV.DWING_START_ANGLE and is_reversed)):
		finished.emit();
		return false;
	return true;
