extends World

var curr_goal_pos:Vector2i; #for testing


func _ready():
	super._ready();
	
	#init pathfinder
	$Pathfinder.set_player_pos(initial_player_pos_t);
	$Pathfinder.set_player_last_dir(Vector2i.ZERO);
	$Pathfinder.set_tilemap($Cells);
	$Pathfinder.set_tile_push_limits(GV.tile_push_limits);
	$Pathfinder.generate_hash_keys();

	#randomize();
	#tile_noise.set_seed(2);
	#wall_noise.set_seed(2);
	tile_noise.set_seed(randi());
	wall_noise.set_seed(randi());
	tile_noise.set_frequency(0.07); #default 0.01
	wall_noise.set_frequency(0.03);
	tile_noise.set_fractal_octaves(3); #number of layers, default 5
	wall_noise.set_fractal_octaves(3);
	tile_noise.set_fractal_lacunarity(2); #frequency multiplier for subsequent layers, default 2.0
	wall_noise.set_fractal_lacunarity(2);
	tile_noise.set_fractal_gain(0.5); #strength of subsequent layers, default 0.5
	wall_noise.set_fractal_gain(0.3);

	# init procgen
	_on_tracking_cam_moved($TrackingCam.position);

	#print($Cells.get_cell_source_id(0, Vector2i.ZERO)) #layer, coord; unnecessary since layer is same as source id
	#print($Cells.get_cell_source_id(0, Vector2i(1, 0)))
	#print($Cells.get_cell_atlas_coords(0, Vector2i.ZERO))
	#print($Cells.get_cell_atlas_coords(0, Vector2i(1, 0)))

func _input(event):
	super._input(event);
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			curr_goal_pos = viewport_to_tile_pos(event.position);
			print("set curr_goal_pos to ", curr_goal_pos);
			return;
