class_name TileForTilemapController

signal finished;
var tile:TileForTilemap; #should be init in ChildClass._init()
var reversed:bool = false; #if shift reversed (bouncing), snap to nearest cell


#func _init(tile:TileForTilemap):
	#self.tile = tile;

# called by TileForTilemap every physics frame to progress the animation
# returns false if movement has finished
func step(delta:float) -> bool:
	return false;
	
#reverses animation direction (start and end keyframes get swapped)
#does not change current animation parameter(s)
func reverse():
	reversed = not reversed;
