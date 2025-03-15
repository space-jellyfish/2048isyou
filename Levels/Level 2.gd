extends World

var curr_goal_pos:Vector2i = Vector2i(31, 28); #for testing
var curr_search_id:int;


func _ready():
	super._ready();
	
	add_entity(GV.EntityId.DUPLICATOR, Vector2i(12, 5), Entity.new(self, null, GV.EntityId.DUPLICATOR, Vector2i(12, 5), false))
	
	#connect sa_search_id_selector
	game.sa_search_id_selector.item_selected.connect(_on_option_button_item_selected);

func _unhandled_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			curr_goal_pos = viewport_to_tile_pos(event.position);
			print("set curr_goal_pos to ", curr_goal_pos);
			return;
	if event.is_action_pressed("debug"):
		var min:Vector2i = Vector2i(min(player.pos_t.x, curr_goal_pos.x), min(player.pos_t.y, curr_goal_pos.y)) - Vector2i(7, 7);
		var max:Vector2i = Vector2i(max(player.pos_t.x, curr_goal_pos.x), max(player.pos_t.y, curr_goal_pos.y)) + Vector2i(8, 8);
		var path:Array = $Pathfinder.pathfind_sa(curr_search_id, 200, false, min, max, player.pos_t, curr_goal_pos);
		print(GV.SASearchId.keys()[curr_search_id], "\t", $Pathfinder.get_sa_cumulative_search_time(curr_search_id), "\t", path);
		$Pathfinder.rrd_clear_iad();
		$Pathfinder.reset_sa_cumulative_search_times();
		return;

func _on_option_button_item_selected(index):
	curr_search_id = index;
