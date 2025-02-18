# trigger pan when player exits central area
extends Camera2D
class_name TrackingCam

signal transition_started;
@onready var world:World = get_parent();


func _ready() -> void:
	#set initial position
	position = GV.pos_t_to_world(world.initial_player_pos_t);
	
	#set initial zoom
	var zoom_ratio:float = GV.VIEWPORT_RESOLUTION.x / GV.CAMERA_RESOLUTION.x;
	set_zoom_custom(Vector2(zoom_ratio, zoom_ratio));

func set_zoom_custom(zoom:Vector2):
	self.zoom = zoom;
	$Area2D.scale = Vector2.ONE / zoom;

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_inside_tree(): #not snapped to tilemap
		assert(body is TileForTilemap and body.old_type_id == GV.TypeId.PLAYER);
		
		#start pan
		var player_offset:Vector2 = body.position - position;
		var target_pos:Vector2 = position + GV.TRACKING_CAM_LEAD_RATIO * player_offset
		
		var tween:Tween = create_tween();
		tween.set_ease(Tween.EASE_OUT);
		tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE);
		tween.tween_property(self, "position", target_pos, GV.TRACKING_CAM_TRANSITION_TIME).set_trans(Tween.TRANS_QUINT);
		transition_started.emit();
