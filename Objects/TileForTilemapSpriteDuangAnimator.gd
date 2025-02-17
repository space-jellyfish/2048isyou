class_name TileForTilemapSpriteDuangAnimator
extends TileForTilemapSpriteAnimator;

var angle_rad:float = GV.DUANG_START_ANGLE;


func _init(sprite:TileForTilemapSprite, governor_tile:TileForTilemap):
	self.sprite = sprite;
	
	#connect governor tile signals
	assert(governor_tile);
	assert(governor_tile.move_controller);
	governor_tile.move_controller.reversed.connect(_on_governor_tile_reversed);
	governor_tile.move_controller.finished.connect(_on_governor_tile_finished);

#should sync to slide progress in case tile bounces
func step(delta:float):
	#if governor finished or governor past trigger threshold, Duang += duang_speed
	#else wait
	if not is_governor_tile_finished:
		var separation:float = Vector2(sprite.governor_tile.move_controller.dir).dot(sprite.tile.position - sprite.governor_tile.position);
		if separation >= GV.DUANG_TRIGGER_SEPARATION:
			return true;
			
	#progress scale animation
	angle_rad += anim_dir * GV.DUANG_SPEED;
	angle_rad = clamp(angle_rad, GV.DUANG_START_ANGLE, GV.DUANG_END_ANGLE);
	sprite.scale = GV.DUANG_FACTOR * sin(angle_rad) * Vector2.ONE;
	
	if angle_rad == GV.DUANG_END_ANGLE and not is_reversed:
		return true;
	if angle_rad == GV.DUANG_START_ANGLE and is_reversed:
		return true;
	return false;

func _on_governor_tile_reversed():
	reverse();

func _on_governor_tile_finished():
	is_governor_tile_finished = true;
