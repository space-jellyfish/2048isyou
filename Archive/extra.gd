extends Node

'''	move_and_slide()
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index);
		var collider := collision.get_collider();
		if collider.is_in_group("wall"):
			vx *= -1;
			vy *= -1;
			velocity.x = vx;
			velocity.y = vy;
		elif collider.is_in_group("player"):
			collider.die();'''

'''func _physics_process(delta):
	match state:
		States.SLIDING:
			#sliding into empty space
			slide_distance += slide_speed;
			if slide_distance >= GV.TILE_WIDTH:
				position = slide_target;
				state = States.IDLE;
				#re-enable collisions
				for i in range(1, 33):
					set_collision_layer_value(i, true);
			else:
				position += slide_step;
				
		States.MERGING:
			#sliding into partner
			slide_distance += slide_speed;
			if slide_distance >= GV.TILE_WIDTH:
				queue_free(); #done sliding
			else:
				if slide_distance >= GV.TILE_WIDTH/2 and not leveluped:
					partner.levelup();
					leveluped = true;
				position += slide_step;
			
		States.COMBINING:
			#fade out img, fade in new img, do scaling animation
			img.modulate.a -= fade_speed;
			new_img.modulate.a += fade_speed;
			
			if new_img.modulate.a >= duang_modulate: #do duang
				if duang_curr_angle >= duang_end_angle: #end of state
					#swap(img, new_img);
					img.scale = Vector2.ONE;
					state = States.IDLE;
				else:
					img.scale = Vector2.ONE * duang_factor * sin(duang_curr_angle);
					new_img.scale = img.scale;
					duang_curr_angle += duang_speed;
				
		States.IDLE:
			pass;'''

'''		if collider is TileForFSM:
			#slide if normal_dir and player_dir agree
			var slide_dir:Vector2 = collision.get_normal() * (-1);
			if abs(slide_dir.x) >= abs(slide_dir.y):
				#slide_dir.y = 0;
				if slide_dir.x > 0 and dir.x > 0:
					collider.slide(Vector2(1, 0));
				elif dir.x < 0:
					collider.slide(Vector2(-1, 0));
			else:
				#slide_dir.x = 0;
				if slide_dir.y > 0 and dir.y > 0:
					collider.slide(Vector2(0, 1));
				elif dir.y < 0:
					collider.slide(Vector2(0, -1));'''

'''
		if collider.is_in_group("wall"):
			if actor.is_player:
				var pos = collider.local_to_map(actor.position + ray.position + ray.target_position);
				var id = collider.get_cell_source_id(0, pos);
				obstructed = false if id == 1 else true;
			else:
				return true;
'''



'''
func slide(slide_dir:Vector2, collide_with_player:bool) -> bool:
	if get_state() != "tile" and get_state() != "snap":
		return false;
		
	#find ray in slide direction
	var ray:RayCast2D;
	if slide_dir == Vector2(1, 0):
		ray = $Ray1;
	elif slide_dir == Vector2(0, -1):
		ray = $Ray2;
	elif slide_dir == Vector2(-1, 0):
		ray = $Ray3;
	else:
		ray = $Ray4;
	
	#determine whether to slide or merge or, if obstructed, idle
	if ray.is_colliding():
		var collider := ray.get_collider();
		if collider.is_in_group("wall"): #obstructed
			return false;
		if collider is TileForFSM:
			if collider.power == power: #merge
				change_state("merging1");
				game.combine_sound.play();
				partner = collider;
				img.z_index -= 1;
			else:
				return false;
	else:
		change_state("sliding");
		game.slide_sound.play();
	
	#find slide parameters
	slide_distance = 0;
	velocity = slide_dir * slide_speed;
	slide_target = position + slide_dir * GV.TILE_WIDTH;
	
	#while sliding, disable collision with (non-player?) objects
	disable_collision(collide_with_player);
	
	return true;
'''

'''
func levelup():
	change_state("combining");
	power += 1;
	update_texture(new_img);
	new_img.modulate.a = 0;
	new_img.scale = Vector2.ONE;
	duang_curr_angle = duang_start_angle;
'''

'''
	if	focus_dir and (\
		Input.is_action_just_released("ui_left") or\
		Input.is_action_just_released("ui_right") or\
		Input.is_action_just_released("ui_up") or\
		Input.is_action_just_released("ui_down")):
			focus_dir = 0;
'''


'''
var focus_dir:int = 0; #-1 for x, 1 for y, 0 for neither
func _physics_process(_delta):
	#releasing direction key loses focus
	if focus_dir == -1 and (Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right")):
		focus_dir = 0;
	elif focus_dir == 1 and (Input.is_action_just_released("ui_up") or Input.is_action_just_released("ui_down")):
		focus_dir = 0;
	
	#pressing direction key sets focus
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		focus_dir = -1;
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		focus_dir = 1;
'''

'''
	if next_state == null and not Input.is_action_pressed("cc"): #slide/merge
		if GV.focus_dir == -1:
			actor.slide_dir = Vector2(Input.get_axis("ui_left", "ui_right"), 0);
		elif GV.focus_dir == 1:
			actor.slide_dir = Vector2(0, Input.get_axis("ui_up", "ui_down"));
		
		if actor.slide_dir != Vector2.ZERO:
			actor.slide(actor.slide_dir);
'''

'''
	#split
	if next_state == null:
		if event.is_action_pressed("split_left"):
			actor.split(Vector2(-1, 0));
		elif event.is_action_pressed("split_right"):
			actor.split(Vector2(1, 0));
		elif event.is_action_pressed("split_up"):
			actor.split(Vector2(0, -1));
		elif event.is_action_pressed("split_down"):
			actor.split(Vector2(0, 1));
	
	#shift
	if next_state == null:
		if event.is_action_pressed("shift_left"):
			actor.shift(Vector2(-1, 0));
		elif event.is_action_pressed("shift_right"):
			actor.shift(Vector2(1, 0));
		elif event.is_action_pressed("shift_up"):
			actor.shift(Vector2(0, -1));
		elif event.is_action_pressed("shift_down"):
			actor.shift(Vector2(0, 1));
		
	#slide/merge
	if next_state == null and not event.is_action_pressed("cc") and not event.is_action_pressed("shift"):
		if event.is_action_pressed("ui_left"):
			actor.slide(Vector2(-1, 0));
		elif event.is_action_pressed("ui_right"):
			actor.slide(Vector2(1, 0));
		elif event.is_action_pressed("ui_up"):
			actor.slide(Vector2(0, -1));
		elif event.is_action_pressed("ui_down"):
			actor.slide(Vector2(0, 1));
'''

''' in snap.gd enter(), presnap logic
	#check presnap
	if actor.presnapped: #this implies snap was entered, collider offset is already fixed
		actor.slide(actor.next_dir);
		actor.presnapped = false;
'''

''' sliding.gd handleInput() code for presnapping
	if not actor.presnapped and not Input.is_action_pressed("cc") and not Input.is_action_pressed("shift"):
		if event.is_action_pressed("ui_left"):
			actor.next_dir = Vector2(-1, 0);
			actor.presnapped = true;
		elif event.is_action_pressed("ui_right"):
			actor.next_dir = Vector2(1, 0);
			actor.presnapped = true;
		elif event.is_action_pressed("ui_up"):
			actor.next_dir = Vector2(0, -1);
			actor.presnapped = true;
		elif event.is_action_pressed("ui_down"):
			actor.next_dir = Vector2(0, 1);
			actor.presnapped = true;
'''

'''
	if actor.next_move.is_null(): #check for premove
		actor.add_premove();
		if actor.next_move.is_valid():
			duang_speed *= 6;
			fade_speed *= 6;
'''

''' old snap.gd code
func changeParentState():
	if actor.slide_dir == Vector2.ZERO:
		return null;
	return next_state(actor.slide_dir);


#assume dir is unit vector along x or y axis
func next_state(dir:Vector2) -> Node2D:
	#get ray
	var ray:RayCast2D;
	if dir.x == 1:
		ray = actor.get_node("Ray1");
	elif dir.y == -1:
		ray = actor.get_node("Ray2");
	elif dir.x == -1:
		ray = actor.get_node("Ray3");
	else:
		ray = actor.get_node("Ray4");
	
	#check collision
	if ray.is_colliding():
		var collider := ray.get_collider();
		
		if collider.is_in_group("wall"):
			return null;
		elif collider is TileForFSM:
			if collider.power == actor.power:
				return states.merging1;
			else: #try to slide tile
				return states.sliding if collider.slide(actor.slide_dir, false) else null;

	return states.sliding;
'''

''' slide with collider_receding
func slide(dir:Vector2) -> bool:
	if get_state() not in ["tile", "snap"]:
		return false;
	
	#determine whether to slide or merge or, if obstructed, idle
	var next_state:Node2D;
	var xaligned = is_xaligned();
	var yaligned = is_yaligned();
	if is_player: #ignore ray if not aligned with tile grid
		if (dir.x and not xaligned) or (dir.y and not yaligned):
			next_state = $FSM.states.sliding;
	
	if next_state == null:
		#find ray in slide direction
		var ray = get_ray(dir);
		if splitted or (pusher != null and pusher.splitted):
			ray.force_raycast_update();
		
		if ray.is_colliding():
			var collider := ray.get_collider();
			
			if collider.is_in_group("wall"): #obstructed
				return false;
				
			if collider is TileForFSM:
				if not xaligned or not yaligned: #in snap mode, must be aligned to do stuff
					return false;
				if collider.get_state() not in ["tile", "snap"]:
					return false;
				
				collider.pusher = self;
				var CFSM = collider.get_node("FSM");
				var collider_receding = CFSM.curState.next_state in [CFSM.states.sliding, CFSM.states.merging1];
				
				if power == 1 and not is_player:
					print(CFSM.curState.next_state);
					print("collider stable: ", not collider_receding);
				
				if power in [-1, collider.power] and not collider_receding: #merge as 0 or equal power
					partner = collider;
					collider.partner = self;
					next_state = $FSM.states.merging1;
				elif is_player and collider.slide(dir): #try to slide collider
					collider.snap_slid = true;
					next_state = $FSM.states.sliding;
				elif collider.is_player and collider_receding: #collider is making way
					next_state = $FSM.states.sliding;
				elif collider.power == -1 and not collider_receding: #merge with 0
					partner = collider;
					collider.partner = self;
					next_state = $FSM.states.merging1;
				else:
					collider.pusher = null;
					return false;
			else:
				next_state = $FSM.states.sliding;
		else:
			next_state = $FSM.states.sliding;
	
	slide_dir = dir;
	$FSM.curState.next_state = next_state;
	return true;
'''

''' using duplicate instead
#remember to update texture and settings too
func set_tile_params(tile, index):
	tile.is_player = tile_is_players[index];
	tile.position = tile_positions[index];
	tile.power = tile_powers[index];
	tile.ssign = tile_ssigns[index];
'''

'''
	#if a tile/baddie is null, instantiate a new one
	#otherwise it still exists, revert its parameters (NAH)
'''

''' in Level.gd
func _physics_process(_delta):
	#create and save snapshot
	if tiles_changed:
		if has_non_player(tiles_changed):
			print("NEW SNAPSHOT");
			var snapshot = PlayerSnapshot.new(self, tiles_changed, tiles_created);
			player_snapshots.push_back(snapshot);
			
		tiles_changed.clear();
'''

'''
func _init(level_, tiles_:Array[TileForFSM], new_tiles_:Array[TileForFSM]):
	level = level_;
	tiles = tiles_.duplicate();
	new_tiles = new_tiles_.duplicate();
	
	for tile_index in tiles.size():
		var tile = tiles[tile_index];
		
		#duplicate tile
		tile_duplicates.push_back(tile.duplicate_custom());
		
		#save snapshot location
		tile.snapshot_locations.push_back(Vector2i(level.player_snapshots.size(), tile_index));
	
		#save baddies
		if tile.is_player:
			save_nearby_baddies(tile.get_node("PhysicsEnabler2"), GV.PLAYER_SNAPSHOT_BADDIE_RANGE);

	#reset baddie flags
	for baddie in baddies:
		baddie.snapshotted = false;
'''

#var tile_is_players:Array[bool] = [];
#var tile_positions:Array[Vector2] = [];
#var tile_powers:Array[int] = [];
#var tile_ssigns:Array[int] = [];

'''
func has_non_player():
	for tile in tiles:
		if not tile.is_player:
			return true;
	return false;
'''

'''
		#update object reference in previous snapshot
		var dup = duplicates[object_index];
		var locations = dup.snapshot_locations;
		if locations:
			var location:Vector2i = locations[locations.size() - 1];
			if location.x == index - 1:
				var prev_snapshot = level.player_snapshots[location.x];
				prev_snapshot.get(objects_name)[location.y] = dup;
				print("UPDATED REF at ", location);
			elif location.x == index: #snapshot consumed, remove snapshot location
				locations.pop_back();
'''

'''
				#debug
				if player_snapshots:
					var s = player_snapshots[0];
					for t in s.tiles:
						print(t);
'''

'''
	var test = "save_%03d.tscn";
	print(test % 1);
'''

''' this overwrites test.tscn
	var test = PackedScene.new();
	test.pack(current_level);
	ResourceSaver.save(test, "res://test.tscn");
'''

''' previously at the end of add_level(n)
	#init player position
	if GV.spawn_point != Vector2.ZERO:
		level.get_node("Player").position = GV.spawn_point;
'''

''' from lv5.gd
func _ready():
	#init random tiles
	for tile in tiles.get_children():
		tile.power = GV.rng.randi_range(1, 11);
		tile.update_texture(tile.img, tile.power, tile.ssign, false);

'''

'''
	#if lv change through goal, prepare for and do save
	if GV.through_goal:
		if is_instance_valid(current_level.player_saved): #wasn't freed by freedom
			#free player so it doesn't trigger lv change when lv loads
			current_level.player_saved.remove_from_players();
			current_level.player_saved.free();
		
		#convert other players to tiles
		for player in current_level.players:
			player.is_player = false;
		current_level.players.clear();
		
		#clear snapshots
		current_level.player_snapshots.clear();
		
		#save level
		save_level();
'''

'''
	if GV.through_goal:
		#convert other players to tiles to prepare for save
		for player in current_level.players:
			player.is_player = false;
		
	#free player so it doesn't trigger lv change when lv loads
	#also to respawn at spawn point, not wherever it got saved
	if is_instance_valid(current_level.player_saved): #player saved and not freed by freedom
		#current_level.player_saved.remove_from_players(); #player array not saved
		#current_level.player_saved.free();
		
		#save level
		save_level();
'''

'''
#isn't freed, isn't null, and has non-player tile
func is_snapshot_valid(snapshot):
	if is_instance_valid(snapshot) and snapshot.has_non_player():
		return true;
	return false;
'''

''' in level.gd, upon undo
				#reset savepoint.saved to false, but don't perform save if player is on savepoint
				#so that a revert after this goes to previous savepoint
'''

''' under change_level, if GV.reverting
		#update all snapshot_location refs
		for tile in current_level.tiles.get_children():
			for location in tile.snapshot_locations:
				GV.temp_player_snapshots[location.x].tiles[location.y] = tile;
			for location_new in tile.snapshot_locations_new:
				GV.temp_player_snapshots[location_new.x].new_tiles[location_new.y] = tile;
		for baddie in current_level.baddies.get_children():
			for location in baddie.snapshot_locations:
				GV.temp_player_snapshots[location.x].baddies[location.y] = baddie;
'''

''' previously in savepoint.spawn_player()
	#update ref in last snapshot location(s)
	if player.snapshot_locations:
		var location = player.snapshot_locations.back();
		game.current_level.player_snapshots[location.x].tiles[location.y] = player;
	if player.snapshot_locations_new:
		var location_new = player.snapshot_locations_new.back();
		game.current_level.player_snapshots[location_new.x].new_tiles[location_new.y] = player;
'''

''' pack does not duplicate member arrays
	var packed_tile = load("res://Objects/TileForFSM.tscn");
	var test = packed_tile.instantiate();
	test.snapshot_locations.push_back(Vector2i(1,1));
	print(test.snapshot_locations);
	packed_tile.pack(test);
	test = packed_tile.instantiate();
	test.snapshot_locations.push_back(Vector2i(2,2));
	print(test.snapshot_locations);
	test.free();
	test = packed_tile.instantiate();
	print(test.snapshot_locations);
'''

'''
#if input, pushes to premoves and premove_dirs
func add_premove():
	var event_name:String = "";
	var action:Callable;
	var s_dir:String;
	
	#find movement type
	if Input.is_action_pressed("cc"):
		action = func_split;
		event_name += "split_";
	elif Input.is_action_pressed("shift"):
		action = func_shift;
		event_name += "shift_";
	else:
		action = func_slide;
		event_name += "move_";
	
	#find direction
	if Input.is_action_pressed("move_left"):
		s_dir = "left";
	elif Input.is_action_pressed("move_right"):
		s_dir = "right";
	elif Input.is_action_pressed("move_up"):
		s_dir = "up";
	elif Input.is_action_pressed("move_down"):
		s_dir = "down";
	
	#check if movement pressed
	if s_dir:
		#check if movement just pressed
		event_name += s_dir;
		if Input.is_action_just_pressed(event_name):
			premove_dirs.push_back(GV.directions[s_dir]);
			premoves.push_back(action);
'''

''' wall grains
	if n_wall < -0.98 or (n_wall > 0.2 and n_wall < 0.22):
		$Walls.set_cell(0, Vector2i(tx, ty), 0, Vector2i.ZERO);
	elif n_wall < -0.955 or (n_wall > 0 and n_wall < 0.025):
		$Walls.set_cell(0, Vector2i(tx, ty), 1, Vector2i.ZERO);
'''

''' trick for pusher updating
	#create and slide/merge player in slide_dir
	player = actor.packed_tile.instantiate();
	if actor.partner != null:
		actor.partner.pusher = player;
		actor.partner = null;
'''

'''
		var track_dir:Vector2i = ($TrackingCam.position - last_cam_pos).sign();
		var track_corner_dpos:Vector2 = Vector2(half_resolution.x * track_dir.x, half_resolution.y * track_dir.y);
		var load_dpos:Vector2 = track_corner_dpos + GV.CHUNK_LOAD_BUFFER * track_dir;
		var unload_dpos:Vector2 = -track_corner_dpos - GV.CHUNK_UNLOAD_BUFFER * track_dir;
		var load_pos_c:Vector2i = GV.world_to_pos_c($TrackingCam.position + load_dpos);
		var unload_pos_c:Vector2i = GV.world_to_pos_c($TrackingCam.position + unload_dpos);
		
		if track_dir.x > 0:
			loaded_pos_c_max.x = min(loaded_pos_c_max.x, load_pos_c.x);
'''

'''
	if global_tile_pos == Vector2i.ZERO: #player
		chunk.cells[local_tile_pos.y][local_tile_pos.x] = GV.StuffId.POS_ONE;
		
		var player = packed_tile.instantiate();
		#player.call_deferred("set_position", GV.pos_t_to_world(local_tile_pos)); #relative
		player.position = GV.pos_t_to_world(local_tile_pos);
		player.is_player = true;
		player.power = 0;
		player.ssign = 1;
		chunk.add_child(player);
		#chunk.call_deferred("add_child", player);
		#print("player instantiated");
		return;
'''

#const CM_TILE_GEN_POW_MAX:int = GV.TILE_GEN_POW_MAX; #for thread safety?

'''
		#unload chunks
		unload_mutex.lock();
		if not unload_queue.is_empty():
			var unload_pos:Vector2i = unload_queue.keys().front();
			unload_queue.erase(unload_pos);
			unload_mutex.unlock();
			#print("unload_positions: ", unload_positions);
			loaded_mutex.lock();
			loaded_chunks[unload_pos].queue_free();
			loaded_chunks.erase(unload_pos);
			loaded_mutex.unlock();
		else:
			unload_mutex.unlock();
'''

'''
	#queue_free an unloaded chunk from active tree
	elif not unloaded_chunks.is_empty():
		var unload_pos:Vector2i = unloaded_chunks.keys().back();
		unloaded_chunks.erase(unload_pos);
		loaded_mutex.lock();
		loaded_chunks[unload_pos].queue_free();
		loaded_chunks.erase(unload_pos);
		loaded_mutex.unlock();
'''

#mutex.lock(); exit_thread = true; mutex.unlock(); return; #debug

''' in slide(), after get_shape()
		#if splitted, tile was newly added, shapecast hasn't updated
		#if pusher splitted, physics was just toggled off then on, shapecast hasn't updated
		#if premoves nonempty, premoved, last shapecast update may have caught a tile corner
		if splitted or (pusher != null and pusher.splitted) or premoves:
			shape.force_shapecast_update();
'''

'''
	#scale physicsEnablers
	$PhysicsEnabler/CollisionShape2D.shape.set_size($PhysicsEnabler/CollisionShape2D.shape.get_size() + GV.PHYSICS_ENABLER_DSIZE);
	$PhysicsEnabler2.shape.set_size($PhysicsEnabler2.shape.get_size() + GV.PHYSICS_ENABLER_DSIZE);
'''

'''
func update_last_input(event) -> bool:
	var modifier_pressed:bool = false;
	var move_changed:bool = false;
	
	#last input modifier
	if event.is_action_pressed("cc"): #Cmd/Ctrl
		last_input_modifier = "split";
		modifier_pressed = true;
	elif event.is_action_pressed("shift"):
		last_input_modifier = "shift";
		modifier_pressed = true;
	elif event.is_action_released("cc") or event.is_action_released("shift"):
		last_input_modifier = "slide";
		#if move is still held, wait for timeout before starting move
		if Input.is_action_pressed("move_" + last_input_move):
			last_input_type = GV.InputType.MOVE;
			atimer.start(GV.MOVE_REPEAT_DELAY_F0, GV.MOVE_REPEAT_DELAY_DF, GV.MOVE_REPEAT_DELAY_DDF, GV.MOVE_REPEAT_DELAY_FMIN);
			return false;
	
	#last input move
	elif event.is_action_pressed("move_left"):
		last_input_move = "left";
		move_changed = true;
	elif event.is_action_pressed("move_right"):
		last_input_move = "right";
		move_changed = true;
	elif event.is_action_pressed("move_up"):
		last_input_move = "up";
		move_changed = true;
	elif event.is_action_pressed("move_down"):
		last_input_move = "down";
		move_changed = true;
	
	if modifier_pressed or move_changed: #stop repeat
		atimer.stop();
		print("last input move: ", last_input_move)
		if Input.is_action_pressed("move_"+last_input_move): #add premove
			last_input_type = GV.InputType.MOVE;
			print("added premove")
			return true;
	
	return false;
'''

'''
	#enter snap
	enter_snap.connect(game.current_level._on_player_enter_snap);
	
func _on_player_enter_snap(prev_state):
	if prev_state == null: #initial ready doesn't count
		return;
	
	last_action_finished = true;
	if atimer.is_timeouted(): #input hasn't changed, repeat last action
		#print("enter snap repeat")
		atimer.repeat();
		repeat_input.emit(last_input_type);
		last_action_finished = false;
'''

'''
signal enter_snap(prev_state); #may be connected to action; emit AFTER slide_dir has been reset
	#emit signal (after slide_dir reset)
	actor.enter_snap.emit(get_parent().prevState);
'''

''' in Level.gd:
	atimer.timeout.connect(_on_atimer_timeout);
	repeat_input.connect(_on_repeat_input);
	
func _on_atimer_timeout():
	if not last_action_finished:
		#don't trigger repeat, leave it to the callback function
		#callback function should check for timeout before triggering repeat
		return;
	if (last_input_type == GV.InputType.UNDO and Input.is_action_pressed("undo")) or \
		(last_input_type == GV.InputType.MOVE and is_last_action_held()):
		atimer.repeat();
		repeat_input.emit(last_input_type);
		last_action_finished = false;

func _on_repeat_input(input_type:int):
	if input_type != GV.InputType.UNDO:
		return;
	
	on_undo();
	if not player_snapshots: #no more history
		atimer.stop();
'''

'''
func can_shift(pos_t:Vector2i, dir:Vector2i):
	var next_pos_t:Vector2i = pos_t + dir;
	return not is_wall_or_border(next_pos_t) and not is_tile(next_pos_t);
'''

'''
	#for search_id in GV.SASearchId.CJPD+1:
		#if event.is_action_pressed("debug"+str(search_id+1)):
			##print search_type, time, and path found
			#var min:Vector2i = Vector2i(min(player_pos_t.x, curr_goal_pos.x), min(player_pos_t.y, curr_goal_pos.y)) - Vector2i(2, 2);
			#var max:Vector2i = Vector2i(max(player_pos_t.x, curr_goal_pos.x), max(player_pos_t.y, curr_goal_pos.y)) + Vector2i(3, 3);
			#var path:Array = $Pathfinder.pathfind_sa(search_id, 200, false, min, max, player_pos_t, curr_goal_pos);
			#print(GV.SASearchId.keys()[search_id], "\t", $Pathfinder.get_sa_cumulative_search_time(search_id), "\t", path);
			#$Pathfinder.rrd_clear_iad();
			#$Pathfinder.reset_sa_cumulative_search_times();
			#return;
'''

'''
var action_buffer:Dictionary; #pos_t, tile atlas_coords; stores true result of action
#use TileForTilemap frame coords instead? NAH, not "secure" enough, and awkward for handling interrupts
'''

'''
# base class for animated TileForFSM sprite
# inits texture based on tile_id
# child classes specialize to handle different animation types
# animation parameters: position, scale, modulate, z_index
class_name TileForFSMAnimator
'''

'''
enum ScaleAnim {
	DUANG=0,
	DWING
};
'''

'''
#create an AnimationSprite (if it doesn't exist) and add its animators for every tile affected by the action
func animate_action(action:String, pos_t:Vector2i, dir:Vector2i, target_dist:int = 1, tile_push_count:int = 0):
	match action:
		"slide":
			animate_slide(pos_t, dir, tile_push_count);
		"split":
			animate_slide(pos_t, dir, tile_push_count);
			animate_split(pos_t);
		"shift":
			animate_shift(pos_t, dir, target_dist);
'''

'''
		#check for head-on slide-slide
		var from_pos_t:Vector2i = pos_t + (push_count + 2) * dir;
		var animator:TileForTilemapController = transit_tiles.get(from_pos_t);
		if animator is TileForTilemapSlideController and animator.dir == -dir:
			#TODO start bounce animation
			#TODO if split, reverse parent splitting animation
			
			return false;
		
'''

''' deprecated, using TileForTilemap.CollisionShape instead (to handle collisions with squid)
enum CollisionId {
	STABLE, #unanimated, ready for action
	HORIZONTAL,
	VERTICAL,
	SOLID, #scaling animation
}

func dir_to_collision_id(dir:Vector2i) -> int:
	return 2 * abs(dir.y) + dir.x;

func collision_id_to_vec(collision_id:int) -> Vector2i:
	return Vector2i(collision_id & 0b01, collision_id & 0b10);
'''

'''
func get_collision_id(pos_t:Vector2i):
	return get_atlas_coords(GV.LayerId.COLLISION, pos_t).x + 1;

func get_collision_atlas_coords(collision_id:int):
	return Vector2i(-1, collision_id - 1);
	
func is_immediate_collision(dir:Vector2i, collision_id:int):
	return (collision_id | GV.dir_to_collision_id(dir)) == GV.CollisionId.SOLID;

func is_stable(pos_t:Vector2i):
	if get_collision_id(pos_t) == GV.CollisionId.STABLE:
		assert(get_alternative_id(pos_t) != GV.AlternativeId.ANIMATING);
	
	return get_collision_id(pos_t) == GV.CollisionId.STABLE;
'''

''' with collision_id updating
#TODO set target_collision_id to SOLID if there is tile at target
func initiate_slide(pos_t:Vector2i, dir:Vector2i, push_count:int, is_splitted:bool):
	#update collision_id; tile_id is updated after slide completes
	var collision_id:int = GV.dir_to_collision_id(dir);
	var source_collision_id:int = GV.CollisionId.SOLID if is_splitted else collision_id;
	var collision_atlas_coords:Vector2i = get_collision_atlas_coords(collision_id);
	var source_collision_atlas_coords:Vector2i = get_collision_atlas_coords(source_collision_id);
	set_atlas_coords(GV.LayerId.COLLISION, pos_t, source_collision_atlas_coords);
	
	for dist_to_src in range(1, push_count + 2):
		var curr_pos_t:Vector2i = pos_t + dist_to_src * dir;
		set_atlas_coords(GV.LayerId.COLLISION, curr_pos_t, collision_atlas_coords);
	
	#start audio and animation
	animate_slide(pos_t, dir, push_count);
	
	var merge_pos_t:Vector2i = pos_t + (push_count + 1) * dir;
	if get_stable_tile_id(merge_pos_t):
		game.get_node("Audio/Combine").play();
	if is_splitted:
		animate_split(pos_t);
		game.get_node("Audio/Split").play();
	else:
		game.get_node("Audio/Slide").play();

# update board, player_pos_t, is_player_alive
# if splitted, make sure to use splitted src coords
func finalize_slide(pos_t:Vector2i, dir:Vector2i, push_count:int, is_splitted:bool):
	var collision_id:int = GV.dir_to_collision_id(dir);
	var merge_pos_t:Vector2i = pos_t + (push_count + 1) * dir;
	for dist_to_merge_pos_t in range(0, push_count + 1):
		var curr_pos_t:Vector2i = merge_pos_t - dist_to_merge_pos_t * dir;
		var prev_pos_t:Vector2i = curr_pos_t - dir;
		assert(is_stable(prev_pos_t));
		var prev_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, prev_pos_t);
		var result_coords = prev_coords;
		
		#merge if curr_pos_t == merge_pos_t
		if dist_to_merge_pos_t == 0:
			var curr_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, curr_pos_t) if is_stable(curr_pos_t) else -Vector2i.ONE;
			result_coords = get_merged_atlas_coords(prev_coords, curr_coords); #this propagates tile type
		
		#update player_pos_t
		if prev_pos_t == player_pos_t:
			set_player_pos_t(curr_pos_t);
		
		#tile_id, alternative_id, collision_id
		set_atlas_coords(GV.LayerId.TILE, curr_pos_t, result_coords, 1); #TileMap updates are batched at end of frame, so tile will remain visible
		set_atlas_coords(GV.LayerId.COLLISION, curr_pos_t, get_collision_atlas_coords(collision_id));
	
	#tile_id, alternative_id, collision_id (remove source tile)
	set_atlas_coords(GV.LayerId.TILE, pos_t, -Vector2i.ONE);
	var source_collision_id:int = GV.CollisionId.SOLID if is_splitted else collision_id;
	set_atlas_coords(GV.LayerId.COLLISION, pos_t, get_collision_atlas_coords(source_collision_id));
	
	#update is_player_alive
	if get_type_id(player_pos_t) != GV.TypeId.PLAYER:
		is_player_alive = false;
'''

''' from TileForTilemapSlideController.step()
#collision_id at target_pos_t was set by current slide, not useful to check
'''

'''
var transit_tiles:Dictionary;

#fetch animation_sprite, or create one and add to dict if it doesn't exist
#check is necessary bc VOID tile always has it
func get_animation_sprite(key:Vector3i) -> TileForTilemap:
	var ans:TileForTilemap = transit_tiles.get(key);
	if not ans:
		var pos_t:Vector2i = Vector2i(key.x, key.y);
		ans = get_pooled_tile(tile_sheet, get_atlas_coords(GV.LayerId.TILE, pos_t), pos_t);
		transit_tiles[key] = ans;
	return ans;

#hides tiles (by setting alternative_id) and initializes transit_tiles
func animate_slide(pos_t:Vector2i, dir:Vector2i, tile_push_count:int):
	for dist_to_src in range(tile_push_count + 1):
		#get animation_sprite
		var curr_pos_t:Vector2i = pos_t + dist_to_src * dir;
		var key:Vector3i = Vector3i(curr_pos_t.x, curr_pos_t.y, GV.ZId.MOVING);
		var curr_sprite:TileForTilemap = get_animation_sprite(key);
		
		#add animator
		curr_sprite.add_animator(GV.AnimatorId.SLIDE).finished.connect(_on_animator_finished);
		
		#set alternative_id
		set_atlas_coords(GV.LayerId.TILE, curr_pos_t, get_atlas_coords(GV.LayerId.TILE, curr_pos_t), 1);

func animate_split(pos_t:Vector2i):
	#get transit_tiles
	var old_key:Vector3i = Vector3i(pos_t.x, pos_t.y, GV.ZId.SPLITTING_OLD);
	var new_key:Vector3i = Vector3i(pos_t.x, pos_t.y, GV.ZId.SPLITTING_NEW);
	var old_sprite:TileForTilemap = get_animation_sprite(old_key);
	var new_sprite:TileForTilemap = get_animation_sprite(new_key);
	
	#add animators
	old_sprite.add_animator(GV.AnimatorId.DWING).finished.connect(_on_animator_finished);
	old_sprite.add_animator(GV.AnimatorId.FADE_OUT).finished.connect(_on_animator_finished);
	new_sprite.add_animator(GV.AnimatorId.DWING).finished.connect(_on_animator_finished);
	new_sprite.add_animator(GV.AnimatorId.FADE_IN).finished.connect(_on_animator_finished);

	#set alternative_id
	set_atlas_coords(GV.LayerId.TILE, pos_t, get_atlas_coords(GV.LayerId.TILE, pos_t), 1);

func animate_shift(pos_t:Vector2i, dir:Vector2i, target_dist:int):
	#get animation_sprite
	var key:Vector3i = Vector3i(pos_t.x, pos_t.y, GV.ZId.MOVING);
	var sprite:TileForTilemap = get_animation_sprite(key);
	
	#add animator
	sprite.add_animator(GV.AnimatorId.SHIFT).finished.connect(_on_animator_finished);

	#set alternative_id
	set_atlas_coords(GV.LayerId.TILE, pos_t, get_atlas_coords(GV.LayerId.TILE, pos_t), 1);

func _on_animation_sprite_freed(key:Vector3i):
	#remove from transit_tiles
	transit_tiles.erase(key);
	
	#update TileMap and player stats (NAH, do it in Animator to stay consistent)
	

'''

'''
#step_id == GV.animator_stepped indicates animator step()ed in current frame
#determines where to move tile for collision (midpoint vs. touching)
var step_id:bool;


func _init():
	step_id = GV.animator_stepped;
'''

''' from TileFromTilemapSlideAnimator
func step(sprite:TileForTilemap, delta:float) -> bool:
	var step_dist:float = min(speed * delta, remaining_dist);
	
	#check for bounce (ignore touching tile if it's sliding in same dir)
	#remember sprite might not be first tile in the line (of sliding tiles)
	#immediate collision (PERP/SOLID) not possible
	for dt in range(1, 3):
		var collider_pos_t:Vector2i = src_pos_t + dt * dir;
		var key:Vector3i = Vector3i(collider_pos_t.x, collider_pos_t.y, GV.ZId.MOVING);
		var collider:TileForTilemap = world.transit_tiles.get(key);
		var d_pos:Vector2i = collider.position - sprite.position;
		if collider.position + collider.animators.get(GV.AnimatorType.MOVE).speed -
	
	#slide
	sprite.position += step_dist * dir;
	remaining_dist -= step_dist;
	
	if not remaining_dist:
		finished.emit();
	
	return remaining_dist;
	
	#TODO upon COMBINING_MERGE_RATIO, add merge animators if merge_pos_t has tile
'''


'''
# update board, player_pos_t, is_player_alive
# if splitted, make sure to use splitted src coords
func finalize_slide(pos_t:Vector2i, dir:Vector2i, push_count:int, is_splitted:bool):
	var merge_pos_t:Vector2i = pos_t + (push_count + 1) * dir;
	for dist_to_merge_pos_t in range(0, push_count + 1):
		var curr_pos_t:Vector2i = merge_pos_t - dist_to_merge_pos_t * dir;
		var prev_pos_t:Vector2i = curr_pos_t - dir;
		assert(is_stable(prev_pos_t));
		var prev_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, prev_pos_t);
		var result_coords = prev_coords;
		
		#merge if curr_pos_t == merge_pos_t
		if dist_to_merge_pos_t == 0:
			var curr_coords:Vector2i = get_stable_tile_atlas_coords(curr_pos_t);
			result_coords = get_merged_atlas_coords(prev_coords, curr_coords); #this propagates tile type
		
		#update player_pos_t
		if prev_pos_t == player_pos_t:
			set_player_pos_t(curr_pos_t);
		
		#tile_id, alternative_id
		set_atlas_coords(GV.LayerId.TILE, curr_pos_t, result_coords, 1); #TileMap updates are batched at end of frame, so tile will remain visible
	
	#tile_id, alternative_id (remove source tile)
	set_atlas_coords(GV.LayerId.TILE, pos_t, -Vector2i.ONE);
	
	#update is_player_alive
	if get_type_id(player_pos_t) != GV.TypeId.PLAYER:
		is_player_alive = false;

func finalize_split(pos_t:Vector2i):
	var parent_coords:Vector2i = get_splitted_tile_atlas_coords(get_atlas_coords(GV.LayerId.TILE, pos_t), false);
	set_atlas_coords(GV.LayerId.TILE, pos_t, parent_coords);
	#don't update player_pos_t since finalize_slide() already did it
'''

'''
					if collider_mover.dir == dir:
						if collider_mover is TileForTilemapShiftController and collider_mover.is_reverse_queued:
							bounce();
						if collider_mover is TileForTilemapSlideController 
					elif collider.mover.dir == -dir: 
						
					else: #perpendicular
						bounce();
'''

'''
# stores collider_mover that caused queued_reverse if is_reverse_queued and collider has one, else null
var reverser_mover:TileForTilemapController; #if SlideAnimator, assume it didn't bounce
var is_reverse_queued:bool = false;

					elif collider_mover.dir == dir:
						if collider_mover is TileForTilemapShiftController:
							if collider_mover.reverser and collider_mover.reverser is TileForTilemap and collider_mover.reverser.move_controller and collider_mover.reverser.move_controller is TileForTilemapSlideController:
								collider_mover.reverser.bounce();
'''

'''
func queue_reverse():
	if not is_reverse_queued:
		is_reverse_queued = true;
		call_deferred("perform_reverse");
	if tile.back_tile:
		tile.back_tile.move_controller.queue_reverse();

func perform_reverse():
	reversed = not reversed;
	dir *= -1;
	remaining_dist = GV.TILE_WIDTH - remaining_dist;
	is_reverse_queued = false;
'''

'''
# assume position (via move_and_collide()) and remaining_dist are updated
# use collision.get_position() to handle different collider types
func is_collision_before_snap(collision:KinematicCollision2D) -> bool:
	return remaining_dist + 0.5 * GV.TILE_WIDTH - (collision.get_position() - tile.position).length() > GV.SNAP_TOLERANCE;
'''

'''
const PLAYER_COLLIDER_SCALE:float = 0.98;
const PLAYER_SNAP_RANGE:float = TILE_WIDTH * (1 - PLAYER_COLLIDER_SCALE);
'''

'''
var move_priorities:Dictionary = {
	TransitId.SLIDE : 1,
	TransitId.SHIFT : 0,
	TransitId.SPLIT : -1,
	TransitId.MERGE : -1,
}
'''

'''
# [dir from obstruction to self, frames_left]
# obstruction should have equal or greater priority than slide (slide/squid_club or perpendicular non-aligned tile)
var is_pressed:Dictionary;
'''

'''
const SHIFT_PRIORITY_DURATION:int = 2; #in frames

	if collision:
		var collider:Node2D = collision.get_collider();
		if collider is TileForTilemap:
			var collider_mover:TileForTilemapController = collider.move_controller;
			if collider_mover is TileForTilemapShiftController:
				if collider_mover.dir == dir:
					collider_mover.front_slide_priority_frames = GV.SHIFT_PRIORITY_DURATION;
				elif collider_mover.dir == -dir:
					collider_mover.back_slide_priority_frames = GV.SHIFT_PRIORITY_DURATION;

# used by sliding tiles to determine whether to bounce or not
# slides approaching from ~ side should bounce if priority_frames non-zero
# decremented each frame
var front_slide_priority_frames:int = 0;
var back_slide_priority_frames:int = 0;

	#update priority_frames
	if front_slide_priority_frames > 0:
		front_slide_priority_frames -= 1;
	if back_slide_priority_frames > 0:
		back_slide_priority_frames -= 1;
		
#update priority_frames (decrement if nonzero and set if collider has move_priority over slide or colliding_shift.priority_frames)
	if collision:
		var collider:Node2D = collision.get_collider();
		if collider is TileForTilemap:
			var collider_mover:TileForTilemapController = collider.move_controller;
			if collider_mover:
				if collider_mover is TileForTilemapSlideController:
					front_slide_priority_frames = GV.SHIFT_PRIORITY_DURATION;
				elif collider_mover is TileForTilemapShiftController:
					
		else:
			front_slide_priority_frames = GV.SHIFT_PRIORITY_DURATION;

func swap_priority_frames():
	var temp:int = front_slide_priority_frames;
	front_slide_priority_frames = back_slide_priority_frames;
	back_slide_priority_frames = temp;
'''

'''
func _physics_process(delta:float):
	var transit_tiles:Array = $TransitTiles.get_children();
	
	#call all move_controller.move()
	#move slides before shifts if using step_dist-based bounce logic? NAH, slide-before-shift order is detrimental to move priority if slide is tailing a shift
	for tile in transit_tiles:
		if tile.move_controller:
			tile.move_controller.move(delta);
			
	#call all move_controller.step()
	for tile in transit_tiles:
		if tile.move_controller:
			tile.move_controller.step();
'''
