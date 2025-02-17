#should not queue_free() when done since 
class_name TileForTilemapSpriteAnimator

signal finished;
var sprite:TileForTilemapSprite;
var anim_dir:int = 1;
var is_reversed:bool = false;
var is_governor_tile_finished:bool = false;


func _init(sprite:TileForTilemapSprite, governor_tile:TileForTilemap):
	self.sprite = sprite;

#called by TileForTilemapSprite every physics frame to progress the animation
func step(delta:float) -> bool:
	return false;
	
#reverses animation direction (start and end keyframes get swapped)
#does not change current animation parameter(s)
func reverse():
	anim_dir *= -1;
	is_reversed = not is_reversed;
