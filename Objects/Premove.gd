#initiated by entity
#affects tile
class_name Premove

var tile_pos_t:Vector2i;
var dir:Vector2i;
var action_id:int;


func _init(tile_pos_t:Vector2i, dir:Vector2i, action_id:int):
	self.tile_pos_t = tile_pos_t;
	self.dir = dir;
	self.action_id = action_id;
