# trigger pan when player exits central area
extends Camera2D
class_name TrackingCam

signal transition_started;
signal transition_finished;
signal moved(pos:Vector2);
var target_entity:Entity;
var pos_tween:Tween;

@onready var world:World = get_parent();
@onready var area_width:float = $Area2D/CollisionRect.shape.size.x;
@onready var area_height:float = $Area2D/CollisionRect.shape.size.y;


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
			set_position(target_entity.get_position());

# transition if target_entity leaves area from zooming
func set_zoom_and_area_scale(zoom_ratio:float):
	set_zoom(zoom_ratio * Vector2.ONE);
	$Area2D.scale = Vector2.ONE / get_zoom(); #this performs element-wise division
	area_width = $Area2D/CollisionRect.shape.size.x / zoom_ratio;
	area_height = $Area2D/CollisionRect.shape.size.y / zoom_ratio;
	
	if target_entity:
		_on_target_entity_moved();

# transition if target_entity is outside area
func _on_target_entity_moved():
	print("TE Moved");
	var target_entity_pos:Vector2 = target_entity.get_position();
	
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.collide_with_areas = true;
	params.collide_with_bodies = false;
	params.collision_mask = (1 << (GV.CollisionId.TRACKING_CAM - 1));
	params.position = target_entity_pos;
	var colliders_info:Array[Dictionary] = space_state.intersect_point(params);
	
	for collider_info in colliders_info:
		if collider_info["collider"] == $Area2D:
			return;
	print("transitioned")
	transition(target_entity_pos, not target_entity.is_roaming());

# assume transition has been triggered (target_entity_pos is outside area)
func transition(target_entity_pos:Vector2, cardinal_only:bool):
	var target_entity_offset:Vector2 = target_entity_pos - position;
	var target_pos:Vector2;
	
	if cardinal_only:
		# only track the axes on which target_entity is outside area
		var tracked_axes:Vector2i = Vector2i(abs(target_entity_offset.x) > area_width / 2, abs(target_entity_offset.y) > area_height / 2);
		target_pos = position + GV.TRACKING_CAM_LEAD_RATIO * target_entity_offset * Vector2(tracked_axes);
	else:
		# track both axes (diagonally)
		target_pos = position + GV.TRACKING_CAM_LEAD_RATIO * target_entity_offset;
	
	if pos_tween:
		pos_tween.kill();
	pos_tween = create_tween();
	pos_tween.set_ease(Tween.EASE_OUT);
	pos_tween.set_trans(Tween.TRANS_QUINT);
	pos_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE);
	pos_tween.tween_method(set_position_with_signal, position, target_pos, GV.TRACKING_CAM_TRANSITION_TIME);
	transition_started.emit(target_pos);
	pos_tween.finished.connect(_on_pos_tween_finished);

func set_position_with_signal(pos:Vector2):
	if pos != position:
		moved.emit(pos);
	set_position(pos);

func _on_pos_tween_finished():
	transition_finished.emit();
	_on_target_entity_moved(); #to ensure target stays inside area
