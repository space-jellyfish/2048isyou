class_name TileForTilemapSpriteAnimator

signal finished;
var sprite:TileForTilemapSprite;
var governor_tile:TileForTilemap;
var anim_dir:int = 1;
var is_reversed:bool = false;
var is_governor_tile_finished:bool = false;


func _init(sprite:TileForTilemapSprite, governor_tile:TileForTilemap):
	self.sprite = sprite;
	self.governor_tile = governor_tile;
	
	#connect governor tile signals
	assert(governor_tile);
	assert(governor_tile.move_controller);
	governor_tile.move_controller.reversed.connect(_on_governor_tile_reversed);
	governor_tile.move_controller.finished.connect(_on_governor_tile_finished);

#called by TileForTilemapSprite every physics frame to progress the animation
func step(delta:float) -> bool:
	return false;
	
#reverses animation direction (start and end keyframes get swapped)
#does not change current animation parameter(s)
func reverse():
	anim_dir *= -1;
	is_reversed = not is_reversed;

func _on_governor_tile_reversed():
	reverse();

func _on_governor_tile_finished():
	is_governor_tile_finished = true;
