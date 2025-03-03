class_name TileForTilemapSpriteFadeAnimator
extends TileForTilemapSpriteAnimator;

var trigger_separation:float;
var start_alpha:float;
var end_alpha:float;
var fade_speed:float;


func _init(sprite:TileForTilemapSprite, anim_dir:int, governor_tile:TileForTilemap, trigger_separation:float, fade_speed:float):
	super._init(sprite, governor_tile);
	
	self.anim_dir = anim_dir;
	self.trigger_separation = trigger_separation;
	self.fade_speed = fade_speed;
	start_alpha = sprite.modulate.a;
	end_alpha = 1 - start_alpha;
	
func step(delta:float):
	#wait if governor_tile (not finished) hasn't reached trigger threshold
	if not is_governor_tile_finished:
		var separation:float = Vector2(governor_tile.move_controller.dir).dot(sprite.tile.position - governor_tile.position);
		if separation >= trigger_separation:
			return true;
			
	#progress fade animation
	sprite.modulate.a += anim_dir * fade_speed;
	sprite.modulate.a = clamp(sprite.modulate.a, 0, 1);
	
	if is_governor_tile_finished and \
		((sprite.modulate.a == end_alpha and not is_reversed) or \
		(sprite.modulate.a == start_alpha and is_reversed)):
		finished.emit();
		return false;
	return true;
