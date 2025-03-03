# initiated by entity
# affects one or more tiles (need not be aligned)
class_name Premove

var tile_entity:Entity;
var dir:Vector2i;
var action_id:int;


func _init(tile_entity:Entity, dir:Vector2i, action_id:int):
	assert(tile_entity.is_tile());
	self.tile_entity = tile_entity;
	self.dir = dir;
	self.action_id = action_id;
