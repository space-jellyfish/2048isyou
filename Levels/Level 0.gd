extends World

var curr_goal_pos:Vector2i; #for testing


func _ready():
	super._ready();

	#randomize();
	#tile_noise.set_seed(2);
	#wall_noise.set_seed(2);
	var tile_seed:int = randi();
	var wall_seed:int = randi();
	print("tile seed: ", tile_seed);
	print("wall seed: ", wall_seed);
	tile_noise.set_seed(tile_seed);
	wall_noise.set_seed(wall_seed);
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

func _input(event):
	super._input(event);
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			curr_goal_pos = viewport_to_tile_pos(event.position);
			print("set curr_goal_pos to ", curr_goal_pos);
			return;

func _on_bgm_finished() -> void:
	$bgm.play();
