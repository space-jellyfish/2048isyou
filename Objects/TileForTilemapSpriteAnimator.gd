#should not queue_free() when done since 
class_name TileForTilemapSpriteAnimator

signal finished;
var sprite:Sprite2D;
var reversed:bool = false;


func _init(sprite:Sprite2D):
	self.sprite = sprite;

#called by TileForTilemapSprite every physics frame to progress the animation
func step(delta:float) -> bool:
	return false;
	
#reverses animation direction (start and end keyframes get swapped)
#does not change current animation parameter(s)
func reverse():
	reversed = not reversed;
