# trigger pan when player exits central area
extends Camera2D
class_name TrackingCam

signal transition_started;
var target_entity:Entity;

@onready var world:World = get_parent();


# if transition true, transition iff position of new target_entity is outside area
# otherwise jump to position of new target_entity
func set_target_entity(target_entity:Entity, transition:bool):
	#connect/disconnect target_entity.moved
	if self.target_entity:
		self.target_entity.moved.disconnect(_on_target_entity_moved);
	if target_entity:
		target_entity.moved.connect(_on_target_entity_moved);
	
	#set
	self.target_entity = target_entity;
	
	#update position
	if target_entity:
		if transition:
			_on_target_entity_moved();
		else:
			position = target_entity.get_position();

# transition if target_entity leaves area from zooming
func set_zoom_and_area_scale(zoom_ratio:float):
	set_zoom(zoom_ratio * Vector2.ONE);
	$Area2D.scale = Vector2.ONE / get_zoom();
	
	if target_entity:
		_on_target_entity_moved();

# transition if target_entity is outside area
func _on_target_entity_moved():
	var target_entity_pos:Vector2 = target_entity.get_position();
	
	var polygon:PackedVector2Array = $Area2D/CollisionShape2D.polygon;
	var global_polygon:PackedVector2Array;
	for point in polygon:
		global_polygon.push_back($Area2D/CollisionShape2D.to_global(point));
	
	if not Geometry2D.is_point_in_polygon(target_entity_pos, global_polygon):
		transition(target_entity_pos);

# assume transition has been triggered (target_entity_pos is outside area)
func transition(target_entity_pos:Vector2):
	var target_entity_offset:Vector2 = target_entity_pos - position;
	var target_pos:Vector2 = position + GV.TRACKING_CAM_LEAD_RATIO * target_entity_offset;
	
	var tween:Tween = create_tween();
	tween.set_ease(Tween.EASE_OUT);
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE);
	tween.tween_property(self, "position", target_pos, GV.TRACKING_CAM_TRANSITION_TIME).set_trans(Tween.TRANS_QUINT);
	transition_started.emit();
