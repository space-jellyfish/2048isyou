extends Node2D

var last_input_type:int; #see GV.InputType
var last_input_modifier:String = "slide";
var last_input_move:String = "left";


func get_event_modifier(event) -> String:
	for modifier in ["split", "shift"]:
		if event.is_action_pressed(modifier):
			return modifier;
	for modifier in ["split", "shift"]:
		if event.is_action_released(modifier):
			return "slide";
	return "";

func get_event_move(event) -> String:
	for move in GV.directions.keys():
		if event.is_action_pressed(move):
			return move;
	return "";

func is_last_move_held() -> bool:
	return Input.is_action_pressed(last_input_move);

func _input(event):
	var modifier:String = get_event_modifier(event);
	if modifier:
		last_input_modifier = modifier;
		if modifier != "slide" and is_last_move_held():
			print(last_input_modifier, " ", last_input_move)
		return;
	
	var move:String = get_event_move(event);
	if move:
		last_input_move = move;
		last_input_type = GV.InputType.MOVE;
		print(last_input_modifier, " ", last_input_move)
