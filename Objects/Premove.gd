# initiated by entity
# affects one or more tiles (need not be aligned)
class_name Premove

var tile_entity:Entity; #required bc src tile might not be aligned
var dir:Vector2i;
var action_id:int;


func _init(p_tile_entity:Entity, p_dir:Vector2i, p_action_id:int):
	assert(p_tile_entity.is_tile());
	tile_entity = p_tile_entity;
	dir = p_dir;
	action_id = p_action_id;
