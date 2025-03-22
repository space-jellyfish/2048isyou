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

		if is_immediate_collision(dir, get_collision_id(curr_pos_t)) or \
			(push_count > 0 and src_type_id in GV.T_ENEMY and curr_type_id == GV.TypeId.PLAYER):
			return nearest_merge_push_count;

	while distance < max_distance and not is_immediate_collision(dir, get_collision_id(next_pos_t)) and is_compatible(src_type_id, get_back_id(next_pos_t)) and not is_tile(next_pos_t):
		distance += 1;
		next_pos_t += dir;
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
	
	#TODO upon DUANG_SEPARATION_RATIO, add merge animators if merge_pos_t has tile
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

'''
#player tile_push_limit does not change when roaming
var tile_push_limits:Dictionary = {
	TypeId.PLAYER : 2,
	TypeId.DUPLICATOR : 1,
	TypeId.HOSTILE : 1,
	TypeId.VOID : 1,
	TypeId.REGULAR : 0,
	TypeId.SQUID : 0,
};
'''

'''
enum AlternativeId {
	EMPTY = -1, #no tile at cell
	STABLE,
	ANIMATING,
}

func get_alternative_id(pos_t:Vector2i):
	return $Cells.get_cell_alternative_tile(GV.LayerId.TILE, pos_t);

func is_stable(pos_t:Vector2i):
	return get_alternative_id(pos_t) == GV.AlternativeId.STABLE;

#return EMPTY if unstable
func get_stable_tile_id(pos_t:Vector2i):
	if is_stable(pos_t):
		return get_tile_id(pos_t);
	return GV.TileId.EMPTY;

func get_stable_tile_atlas_coords(pos_t:Vector2i):
	if is_stable(pos_t):
		return get_atlas_coords(GV.LayerId.TILE, pos_t);
	return -Vector2i.ONE;

# update tile_id at src_pos_t iff alternative_id is 1 (splitted or back_tile hasn't finalized yet)
# atlas_coord required because tile_id at src_pos_t might've been modified by back_tile
# is_merging required because if TileId.ZERO at target_pos_t, either push or pop possible
# slide does not update Tilemap immediately bc success is not guaranteed (might bounce off squid club)
func finalize_slide(src_pos_t:Vector2i, dir:Vector2i, tile_atlas_coords:Vector2i, is_splitted:bool, is_merging:bool):
	#set atlas_coords at target_pos_t
	var target_pos_t:Vector2i = src_pos_t + dir;
	if is_merging:
		var target_atlas_coords:Vector2i = get_atlas_coords(GV.LayerId.TILE, target_pos_t);
		assert(is_ids_mergeable(tile_atlas_coords.x + 1, target_atlas_coords.x + 1));
		var result_atlas_coords:Vector2i = get_merged_atlas_coords(tile_atlas_coords, target_atlas_coords);
		set_atlas_coords(GV.LayerId.TILE, target_pos_t, result_atlas_coords, 1); #alternative_id resets when merge animation finishes
	else:
		set_atlas_coords(GV.LayerId.TILE, target_pos_t, tile_atlas_coords, 0);
	
	#update atlas_coords at src_pos_t
	if is_splitted:
		var parent_coords:Vector2i = Vector2i(tile_atlas_coords.x, GV.TypeId.REGULAR);
		set_atlas_coords(GV.LayerId.TILE, src_pos_t, parent_coords, 1);
	elif get_alternative_id(src_pos_t) == 1:
		set_atlas_coords(GV.LayerId.TILE, src_pos_t, -Vector2i.ONE, 0);

	if new_remaining_dist <= GV.SNAP_TOLERANCE:
		#update TileMap (emit signal or call world.update_tilemap(); don't update tilemap directly)
		if not reversed:
			tile.world.finalize_slide(src_pos_t, dir, tile.atlas_coords, tile.is_splitted, tile.is_merging);
		return false;

# there is no need to snap tile.position to grid since alternative_id will be reset
'''

''' from try_split()
# halve tile, try_slide, then (re)set tile at pos_t
'''

'''
#var premove_dirs:Array[Vector2i];
#var premoves:Array[String]; #slide, shift, split
var last_input_premove:Vector3i;

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

func _input(event):	
	var modifier:String = get_event_modifier(event);
	if modifier:
		last_input_action = modifier;
		#if modifier != "slide" and Input.is_action_pressed(last_input_move):
			#add_premove(last_input_modifier, GV.directions[last_input_move]);
		return;
	
	var move:String = get_event_move(event);
	if move:
		last_input_move = move;
		add_premove(last_input_modifier, GV.directions[last_input_move]);

func add_premove(entity_id:int, premove:Vector3i):
	premoves[entity_id].push_back(premove);
	premove_added.emit();

#signals
premove_added.connect(_on_premove_added);

func _on_animator_finished(successful:bool):
	#for consistency, update tilemap and player stats from animator
	
	#update premoves
	if not successful: #bounced
		#clear premoves
		pass;
	elif premoves:
		consume_premove();

func _physics_process(delta:float):

	for entity_id in GV.ENTITY_IDS_DECREASING_PREMOVE_PRIORITY:
		for entity in entities[entity_id]:
			entity.try_curr_frame_premoves();
'''

'''
var player_shift_dir:Vector2i = Vector2i.ZERO;
var player_shift_remaining_t:int = 0;
'''

'''
#from GV
const RESOLUTION_T:Vector2i = Vector2i(RESOLUTION/TILE_WIDTH);
const SHIFT_RAY_LENGTH:float = RESOLUTION.x;

#from World
@export var resolution_t:Vector2i = GV.RESOLUTION_T;
@export var min_pos:Vector2 = Vector2.ZERO;
@export var max_pos:Vector2 = GV.RESOLUTION;

func _enter_tree():
	#set resolution (before tracking cam _ready())
	resolution = Vector2(resolution_t * GV.TILE_WIDTH);
	half_resolution = resolution / 2;

	#set position bounds (before tracking cam _ready())
	min_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MIN, GV.INT64_MIN);
	max_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MAX, GV.INT64_MAX);
'''

'''
#const PHYSICS_ENABLER_SHAPE:RectangleShape2D = preload("res://Objects/PhysicsEnablerShape.tres");
const PHYSICS_ENABLER_BASE_SIZE:Vector2 = Vector2(144, 144); #px, px; at tile_push_limit = 0
'''

''' shift.target_dist_t stuff?

'''

'''
self.governor_tile = governor_tile; # if null/queued_for_deletion() => slide finished => finish sprite animations immediately

	#if governor distance greater than threshold, set scale to 1
	#otherwise calculate scale with sin()
	#separation should be opposite sign for DWING
	var separation:float = Vector2(sprite.governor_tile.move_controller.dir).dot(sprite.tile.position - sprite.governor_tile.position);
	if separation >= GV.DUANG_TRIGGER_SEPARATION:
		sprite.scale = Vector2.ONE;
	else:
		var angle_rad:float = 
	pass;
'''

'''
func get_tile_entity_by_body(tile:TileForTilemap):
	assert(entities[tile.old_type_id].has(tile));
	return entities[tile.old_type_id][tile];
	
func get_tile_entity_by_pos_t(type_id:int, pos_t:Vector2i):
	assert(entities[type_id].has(pos_t));
	return entities[type_id][pos_t];
'''

'''
func set_tile_entity_body(tile:TileForTilemap, pos_t:Vector2i):
	if tile.type_id == GV.EntityId.NONE:
		return;
	
	var entity:Entity = get_tile_entity_by_pos_t(tile.type_id, pos_t);
	#update properties
	entity.body = tile;
	#update key
	entities[tile.type_id].erase(pos_t);
	entities[tile.type_id][tile] = entity;
	
func set_tile_entity_pos_t(tile:TileForTilemap, pos_t:Vector2i):
	if tile.type_id == GV.EntityId.NONE:
		return;
	
	var entity:Entity = get_tile_entity_by_body(tile);
	#update properties
	entity.body = null;
	entity.set_pos_t(pos_t);
	#update key
	entities[tile.type_id].erase(tile);
	entities[tile.type_id][pos_t] = entity;

func set_tile_entity_not_busy(tile:TileForTilemap):
	if tile.type_id == GV.EntityId.NONE:
		return;
	
	var entity:Entity = get_tile_entity_by_body(tile);
	entity.set_is_busy(false);
'''

'''
const DUANG_START_MODULATE:float = 0; #0.2;
const DUANG_FADE_SPEED:float = 0.07;

const FADE_START_ANGLE:float = 1;
const DWING_FADE_SPEED:float = 0.07;

'''

''' from Level 14
	#if event is InputEventMouseButton and event.is_pressed():
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#var click_pos:Vector2i = viewport_to_tile_pos(event.position);
			#$Pathfinder.rrd_init_iad(click_pos);
			#curr_goal_pos = click_pos;
			#print("curr_goal_pos: ", click_pos);
			##print($Cells.local_to_map(get_local_mouse_position())); #more offset error
		#elif event.button_index == MOUSE_BUTTON_RIGHT:
			#var click_pos:Vector2i = viewport_to_tile_pos(event.position);
			#print("rrd_resume_iad: ", curr_goal_pos, click_pos, $Pathfinder.rrd_resume_iad(curr_goal_pos, click_pos, GV.TypeId.PLAYER));
	for search_id in GV.SASearchId.IWDMDA+1:
		if event.is_action_pressed("debug"+str(search_id+1)):
			#print search_type, time, and path found
			var min:Vector2i = Vector2i(min(player.pos_t.x, curr_goal_pos.x), min(player.pos_t.y, curr_goal_pos.y)) - Vector2i(2, 2);
			var max:Vector2i = Vector2i(max(player.pos_t.x, curr_goal_pos.x), max(player.pos_t.y, curr_goal_pos.y)) + Vector2i(3, 3);
			var path:Array = $Pathfinder.pathfind_sa(search_id, 24, false, min, max, player.pos_t, curr_goal_pos);
			print(GV.SASearchId.keys()[search_id], "\t", $Pathfinder.get_sa_cumulative_search_time(search_id), "\t", path);
			$Pathfinder.rrd_clear_iad();
			$Pathfinder.reset_sa_cumulative_search_times();
			return;
	#if event.is_action_pressed("debug1"):
		#for i in 1000:
			#print("epoch: ", i);
			##generate random start pos
			#var start_pos:Vector2i = Vector2i(randi_range(-20, 19), randi_range(-15, 14));
			#while get_tile_id(start_pos) == GV.TileId.EMPTY:
				#start_pos = Vector2i(randi_range(-20, 19), randi_range(-15, 14));
			#
			##set type at start_pos to PLAYER
			#var start_atlas_coords:Vector2i = $Cells.get_cell_atlas_coords(GV.LayerId.TILE, start_pos);
			#$Cells.set_cell(GV.LayerId.TILE, start_pos, GV.LayerId.TILE, Vector2i(start_atlas_coords.x, GV.TypeId.PLAYER));
			##generate random end pos
			#var end_pos:Vector2i = start_pos + Vector2i(randi_range(-5, 5), randi_range(-5, 5));
			#while (!is_compatible(GV.TypeId.PLAYER, get_back_id(end_pos)) or end_pos.x < -20 or end_pos.x > 19 or end_pos.y < -15 or end_pos.y > 14):
				#end_pos = start_pos + Vector2i(randi_range(-5, 5), randi_range(-5, 5));
			#
			##get min, max
			#var min:Vector2i = Vector2i(min(start_pos.x, end_pos.x), min(start_pos.y, end_pos.y)) - Vector2i(2, 2);
			#var max:Vector2i = Vector2i(max(start_pos.x, end_pos.x), max(start_pos.y, end_pos.y)) + Vector2i(3, 3);
			##pathfind
			#for search_id in range(2, 7):
				#print(GV.SASearchId.keys()[search_id]);
				#$Pathfinder.pathfind_sa(search_id, 24, false, min, max, start_pos, end_pos);
				#$Pathfinder.rrd_clear_iad();
		#
		##print cumulative times
		#for search_id in range(2, 7):
			#print(GV.SASearchId.keys()[search_id], "\t\t", $Pathfinder.get_sa_cumulative_search_time(search_id));
		#
		##reset cumulative times
		#$Pathfinder.reset_sa_cumulative_search_times();

'''

'''
var is_tilemap_cleared:bool = false;
	# wait for TileMap cell removal to take effect
	#if is_tilemap_cleared:
'''

'''
var unsplit_atlas_coords:Vector2i; #used if tile is_splitted and is_reversed when finalizing
'''

'''
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

func _ready() -> void:
	#set initial position
	position = GV.pos_t_to_world(world.initial_player_pos_t);
	
	#set initial zoom
	var zoom_ratio:float = GV.VIEWPORT_RESOLUTION.x / GV.tracking_cam_resolution.x;
	set_zoom_custom(Vector2(zoom_ratio, zoom_ratio));

# transition if target_entity is outside area
func _on_target_entity_moved():
	var target_entity_pos:Vector2 = target_entity.get_position();
	
	var polygon:PackedVector2Array = $Area2D/CollisionShape2D.polygon;
	var global_polygon:PackedVector2Array;
	for point in polygon:
		global_polygon.push_back($Area2D/CollisionShape2D.to_global(point));
	
	if not Geometry2D.is_point_in_polygon(target_entity_pos, global_polygon):
		transition(target_entity_pos);
'''

'''
#pathfinder-related stuff
#var level_hash_numbers:Array = [];
#var x_hash_numbers:Array = [];
#var y_hash_numbers:Array = [];
'''

'''
func set_splitter_tile(tile:TileForTilemap):
	self.splitter_tile = tile;
'''

'''
@onready var combine_sound = $"Audio/Combine";
@onready var slide_sound = $"Audio/Slide";
@onready var split_sound = $"Audio/Split";
@onready var shift_sound = $"Audio/Shift";
'''

'''
	# force a collision shape update
	# alternatively, await get_tree().physics_frame
	tile.collision_shape.disabled = true;
	tile.collision_shape.disabled = false;
'''

''' fast_combine
		# update entity.pos_t
		if tile_entity:
			if is_merging_and_merged:
				tile_entity.set_entity_id_and_body(merger_tile.old_type_id, merger_tile);
			else:
				tile_entity.set_entity_id_and_pos_t(new_type_id, pos_t);

	# update entity.is_busy so it can try new premoves
	if tile_entity and not is_merging_and_merged:
		tile_entity.set_is_busy(false);

func is_tile_including_transient(pos_t:Vector2i):
	var tile:TileForTilemap = tiles_in_transient.get(pos_t);
	if tile:
		return true;
	return is_tile(pos_t);

func get_tile_id_including_transient(pos_t:Vector2i):
	var tile:TileForTilemap = tiles_in_transient.get(pos_t);
	if tile:
		return atlas_coords_to_tile_id(tile.atlas_coords);
	return get_tile_id(pos_t);

func get_type_id_including_transient(pos_t:Vector2i):
	var tile:TileForTilemap = tiles_in_transient.get(pos_t);
	if tile:
		return atlas_coords_to_type_id(tile.atlas_coords);
	return get_type_id(pos_t);

func finalize_transit(...)
	# get tile_entity
	var is_merging_and_merged:bool = merger_tile and pos_t == merger_tile.src_pos_t; # NOTE assumes merger is aligned
	var is_splitter_and_reversed:bool = (transit_id == GV.TransitId.SPLIT and is_reversed);
	var entity_type_id:int = new_type_id if transit_id == GV.TransitId.MERGE else old_type_id;
	
	
	if is_aligned and not is_splitter_and_reversed:
		# update tilemap
		if not is_merging_and_merged:
			var final_atlas_coords:Vector2i = world.get_doubled_tile_atlas_coords(atlas_coords) if (is_splitted and is_reversed) else atlas_coords;
			world.set_atlas_coords(GV.LayerId.TILE, pos_t, final_atlas_coords);
		
		# update entity.pos_t
		if tile_entity:
			if is_merging_and_merged:
				tile_entity.set_entity_id_and_body(merger_tile.new_type_id, merger_tile);
			else:
				tile_entity.set_entity_id_and_pos_t(new_type_id, pos_t);

	# update entity.is_busy so it can try new premoves
	if tile_entity and transit_id in [GV.TransitId.SLIDE, GV.TransitId.SHIFT]:
		tile_entity.set_is_busy(false);
		
	
	#return to pool or prepare for next transition (by resetting properties that _init() doesn't）
	#if not aligned, assume type does not change
	if is_aligned:
		world.return_pooled_tile(self);
	else:
		#necessary since _init() does not reset these
		if prev_sprite:
			prev_sprite.queue_free();
			prev_sprite = null;
		move_controller = null;
		front_tile = null;
		back_tile = null;
		merger_tile = null;
		
		#unnecessary since these aren't technically used until the next _init()
		is_splitted = false;
		is_merging = false;
		old_type_id = new_type_id;
		pusher_entity_id = GV.EntityId.NONE;
		#transit_id = ?
'''

'''
	if move_controller and old_type_id == GV.TypeId.PLAYER:
		set_collision_layer_value(GV.CollisionId.TRACKING_CAM, true);
'''

'''
func initialize(world:World, pusher_entity_id:int, transit_id:int, pos_t:Vector2i, dir:Vector2i, target_dist_t:int, tile_sheet:CompressedTexture2D, old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, back_tile:TileForTilemap, is_splitted:bool, is_merging:bool, governor_tile:TileForTilemap):
	self.src_pos_t = pos_t;
	self.world = world;
	self.is_splitted = is_splitted;
	self.is_merging = is_merging;
	self.pusher_entity_id = pusher_entity_id;
	self.transit_id = transit_id;
	position = GV.pos_t_to_world(pos_t);
	atlas_coords = new_atlas_coords;
	self.back_tile = back_tile;
	old_type_id = world.atlas_coords_to_type_id(old_atlas_coords);
	new_type_id = world.atlas_coords_to_type_id(new_atlas_coords);
	velocity = Vector2.ZERO;
	
	# set move_controller, sprites, and collision layers
	match transit_id:
		GV.TransitId.SLIDE:
			move_controller = TileForTilemapSlideController.new(self, dir);
			curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.MOVING, 1, [], null);
			set_collision_layer_value(GV.CollisionId.DEFAULT, true);
		GV.TransitId.SHIFT:
			move_controller = TileForTilemapShiftController.new(self, dir, target_dist_t);
			curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.MOVING, 1, [], null);
			set_collision_layer_value(GV.CollisionId.DEFAULT, true);
		GV.TransitId.SPLIT:
			prev_sprite = TileForTilemapSprite.new(self, tile_sheet, old_atlas_coords, GV.ZId.SPLITTING_OLD, 1, [GV.ConversionAnimatorId.DWING_FADE_OUT, GV.ConversionAnimatorId.DWING], governor_tile);
			curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.SPLITTING_NEW, 0, [GV.ConversionAnimatorId.DWING_FADE_IN, GV.ConversionAnimatorId.DWING], governor_tile);
			set_collision_layer_value(GV.CollisionId.SPLITTING, true);
		GV.TransitId.MERGE:
			prev_sprite = TileForTilemapSprite.new(self, tile_sheet, old_atlas_coords, GV.ZId.COMBINING_OLD, 1, [GV.ConversionAnimatorId.DUANG_FADE_OUT, GV.ConversionAnimatorId.DUANG], governor_tile);
			curr_sprite = TileForTilemapSprite.new(self, tile_sheet, new_atlas_coords, GV.ZId.COMBINING_NEW, 0, [GV.ConversionAnimatorId.DUANG_FADE_IN, GV.ConversionAnimatorId.DUANG], governor_tile);
			set_collision_layer_value(GV.CollisionId.COMBINING, true);
	
	# set collision masks if tile moves
	if move_controller:
		set_collision_mask_value(GV.CollisionId.DEFAULT, true);
		if not is_splitted:
			set_collision_mask_value(GV.CollisionId.SPLITTING, true);
		if not is_merging:
			set_collision_mask_value(GV.CollisionId.COMBINING, true);
		if old_type_id != GV.TypeId.PLAYER:
			set_collision_mask_value(GV.CollisionId.MEMBRANE, true);
		if old_type_id in GV.T_ENEMY:
			set_collision_mask_value(GV.CollisionId.SAVE_OR_GOAL, true);
	
	# add sprites
	for sprite in [prev_sprite, curr_sprite]:
		if sprite:
			add_child(sprite);

func get_pooled_tile(pusher_entity_id:int, transit_id:int, pos_t:Vector2i, dir:Vector2i, target_dist_t:int, old_atlas_coords:Vector2i, new_atlas_coords:Vector2i, back_tile:TileForTilemap, is_splitted:bool, is_merging:bool, governor_tile:TileForTilemap) -> TileForTilemap:
	var tile:TileForTilemap;
	if not tile_pool.is_empty():
		tile = tile_pool.pop_back();
		tile.collision_shape.disabled = false;
	else:
		tile = packed_tile.instantiate();
	
	tile.initialize(self, pusher_entity_id, transit_id, pos_t, dir, target_dist_t, tile_sheet, old_atlas_coords, new_atlas_coords, back_tile, is_splitted, is_merging, governor_tile);
	return tile;
'''

'''
	SPLITTING, # splitting tiles, (non-splitted tiles, squid)
	COMBINING, # combining tiles, (non-merging tiles, squid)

	if not is_splitted:
		set_collision_mask_value(GV.CollisionId.SPLITTING, true);
	if not is_merging:
		set_collision_mask_value(GV.CollisionId.COMBINING, true);

	set_collision_mask_value(GV.CollisionId.SPLITTING, true);
	set_collision_mask_value(GV.CollisionId.COMBINING, true);
	
	set_collision_layer_value(GV.CollisionId.SPLITTING, true);

	set_collision_layer_value(GV.CollisionId.COMBINING, true);
'''

'''
const TRACKING_CAM_LEAD_MIN:float = 0.3; #target = track_pos + ratio * pow(track_pos - pos, offset_pow)
const TRACKING_CAM_OFFSET_POWER:float = 0.4;

	#var target_pos:Vector2 = target_entity_pos + GV.TRACKING_CAM_LEAD_RATIO * pow(target_entity_offset.length(), GV.TRACKING_CAM_OFFSET_POWER) * target_entity_offset_dir;

	var semi_minor_axis:float = $Area2D/CollisionShape2D.shape.radius * $Area2D.scale.y;
	var target_entity_offset:Vector2 = target_entity_pos - position;
	print("unclamped offset ratio:", target_entity_offset.length() / semi_minor_axis);
	var target_entity_offset_ratio:float = max(1, target_entity_offset.length() / semi_minor_axis);
	var target_pos:Vector2 = position + (pow(target_entity_offset_ratio, GV.TRACKING_CAM_OFFSET_POWER) + GV.TRACKING_CAM_LEAD_MIN) * target_entity_offset;

func get_last_cardinal_dir() -> Variant:
	
'''

''' only used by Goal/Savepoint/Level/PlayerSnapshot
enum ColorId {
	ALL = 4,
	RED = 29,
	BLUE = 30,
	BLACK = 31,
	GRAY = 32,
};
'''

'''
func sin_approx(angle_rad:float):
	pass;

func set_tile_push_limit(_tile_push_limit):
	abilities["tile_push_limit"] = _tile_push_limit;

	#change physicsEnabler size
	var size:Vector2 = PHYSICS_ENABLER_BASE_SIZE + abilities["tile_push_limit"] * 2 * GV.TILE_WIDTH * Vector2.ONE;
	PHYSICS_ENABLER_SHAPE.set_size(size);
'''

''' deprecated bc each directional barrier of NavId should be refcounted
func dir_id_to_nav_id(dir_id:int) -> int:
	return 1 << dir_id;

func dir_to_nav_id(dir:Vector2i) -> int:
	return dir_id_to_nav_id(dir_to_dir_id(dir));

func is_navigable(dir:Vector2i, nav_id:int) -> bool:
	var dir_id:int = GV.dir_to_dir_id(dir);
	assert(dir_id in GV.DirectionId.values());
	
	# check the bit at position dir_id
	return not (nav_id & (1 << dir_id));
'''

'''
	#assume tile is aligned
	assert(fposmod(tile.position.x, GV.TILE_WIDTH) == 0.5 * GV.TILE_WIDTH);
	assert(fposmod(tile.position.y, GV.TILE_WIDTH) == 0.5 * GV.TILE_WIDTH);
'''

''' incremental NavId update doesn't work bc Shift can theoretically travel more than one TILE_WIDTH per step
	# update latest_pos_t and NAV layer
	if not is_reversed and remaining_dist > GV.SNAP_TOLERANCE and Vector2(dir).dot(tile.position - GV.pos_t_to_world(latest_pos_t)) >= GV.TILE_WIDTH:
		tile.world.remove_nav_id(latest_pos_t, GV.NAV_UNITS[dir]);
		latest_pos_t += dir;
		tile.world.remove_nav_id(latest_pos_t, GV.NAV_TERMS[-dir]);
		tile.world.add_nav_id(latest_pos_t + dir, GV.NavId.ALL);
'''

'''
var resolution:Vector2;
var half_resolution:Vector2;

#use tilemap, don't unload manually
func _on_camera_transition_started(target:Vector2, track_dir:Vector2i):
	if procgen:
		var temp_pos_t_min:Vector2i = loaded_pos_t_min;
		var temp_pos_t_max:Vector2i = loaded_pos_t_max;
		if track_dir.x:
			var load_min_x:float = target.x - half_resolution.x - (GV.TILE_LOAD_BUFFER if track_dir.x < 0 else GV.TILE_UNLOAD_BUFFER);
			var load_max_x:float = target.x + half_resolution.x + (GV.TILE_LOAD_BUFFER if track_dir.x > 0 else GV.TILE_UNLOAD_BUFFER);
			temp_pos_t_min.x = GV.world_to_xt(load_min_x);
			temp_pos_t_max.x = GV.world_to_xt(load_max_x);
		if track_dir.y:
			var load_min_y:float = target.y - half_resolution.y - (GV.TILE_LOAD_BUFFER if track_dir.y < 0 else GV.TILE_UNLOAD_BUFFER);
			var load_max_y:float = target.y + half_resolution.y + (GV.TILE_LOAD_BUFFER if track_dir.y > 0 else GV.TILE_UNLOAD_BUFFER);
			temp_pos_t_min.y = GV.world_to_xt(load_min_y);
			temp_pos_t_max.y = GV.world_to_xt(load_max_y);
		update_map(loaded_pos_t_min, loaded_pos_t_max, temp_pos_t_min, temp_pos_t_max);
		loaded_pos_t_min = temp_pos_t_min;
		loaded_pos_t_max = temp_pos_t_max;

# NOTE there will be gap in generation if target_pos is too far from loaded rect
func _on_camera_transition_started(target_pos:Vector2):
	if procgen:
		var temp_pos_t_min:Vector2i = loaded_pos_t_min;
		var temp_pos_t_max:Vector2i = loaded_pos_t_max;
		if track_dir.x:
			var load_min_x:float = target_pos.x - GV.tracking_cam_resolution.x / 2 - GV.TILE_LOAD_BUFFER;
			var load_max_x:float = target_pos.x + GV.tracking_cam_resolution.x / 2 + GV.TILE_LOAD_BUFFER;
			temp_pos_t_min.x = GV.world_to_xt(load_min_x);
			temp_pos_t_max.x = GV.world_to_xt(load_max_x);
		if track_dir.y:
			var load_min_y:float = target_pos.y - GV.tracking_cam_resolution.y / 2 - GV.TILE_LOAD_BUFFER;
			var load_max_y:float = target_pos.y + GV.tracking_cam_resolution.y / 2 + GV.TILE_LOAD_BUFFER;
			temp_pos_t_min.y = GV.world_to_xt(load_min_y);
			temp_pos_t_max.y = GV.world_to_xt(load_max_y);
		update_map(loaded_pos_t_min, loaded_pos_t_max, temp_pos_t_min, temp_pos_t_max);
		loaded_pos_t_min = temp_pos_t_min;
		loaded_pos_t_max = temp_pos_t_max;
'''

'''
	#load cells
	loaded_pos_t_min = GV.world_to_pos_t($TrackingCam.position - half_resolution - Vector2(GV.TILE_LOAD_BUFFER, GV.TILE_LOAD_BUFFER));
	loaded_pos_t_max = GV.world_to_pos_t($TrackingCam.position + half_resolution + Vector2(GV.TILE_LOAD_BUFFER, GV.TILE_LOAD_BUFFER));
	load_rect(loaded_pos_t_min, loaded_pos_t_max);
'''

'''
	_on_target_entity_moved(); #to ensure target stays inside area

# deprecated bc transition_step() requires return value to update immediately upon position change
func is_in_area(pos:Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.collide_with_areas = true;
	params.collide_with_bodies = false;
	params.collision_mask = (1 << (GV.CollisionId.TRACKING_CAM - 1));
	params.position = pos;
	var colliders_info:Array[Dictionary] = space_state.intersect_point(params);
	
	for collider_info in colliders_info:
		if collider_info["collider"] == $Area2D:
			return true;
	return false;
'''

'''
	#init pathfinder
	$Pathfinder.set_player_pos(initial_player_pos_t);
	$Pathfinder.set_player_last_dir(Vector2i.ZERO);
	$Pathfinder.set_tilemap($Cells);
	$Pathfinder.set_tile_push_limits(GV.tile_push_limits);
	$Pathfinder.generate_hash_keys();

	#init pathfinder
	$Pathfinder.set_player_pos(initial_player_pos_t);
	$Pathfinder.set_player_last_dir(Vector2i.ZERO);
	$Pathfinder.set_tilemap($Cells);
	$Pathfinder.set_tile_push_limits(GV.tile_push_limits);
	$Pathfinder.generate_hash_keys();
	$Pathfinder.init_sa_pool(2000);

	#init pathfinder
	$Pathfinder.set_player_pos(initial_player_pos_t);
	$Pathfinder.set_player_last_dir(Vector2i.ZERO);
	$Pathfinder.set_tilemap($Cells);
	$Pathfinder.set_tile_push_limits(GV.tile_push_limits);
	$Pathfinder.generate_hash_keys();
	$Pathfinder.init_sa_pool(2000);

	#print($Cells.get_cell_source_id(0, Vector2i.ZERO)) #layer, coord; unnecessary since layer is same as source id
	#print($Cells.get_cell_source_id(0, Vector2i(1, 0)))
	#print($Cells.get_cell_atlas_coords(0, Vector2i.ZERO))
	#print($Cells.get_cell_atlas_coords(0, Vector2i(1, 0)))
'''

'''
		match entity_id:
			GV.EntityId.PLAYER:
				world.get_node("Pathfinder").set_player_last_dir(premove.dir);

	#update Pathfinder.player_pos_t
	if entity_id == GV.EntityId.PLAYER:
		if self.pos_t != pos_t:
			world.get_node("Pathfinder").rrd_clear_iad();
		world.get_node("Pathfinder").set_player_pos(pos_t);
'''

'''
const TILE_POW_MAX:int = 14;
const TILE_GEN_POW_MAX:int = 11;

#assume at most one is -Vector2i.ONE
func get_merged_atlas_coords(coords1:Vector2i, coords2:Vector2i):
	var atlas_y:int = coords1.y if get_merge_priority(coords1.y) > get_merge_priority(coords2.y) else coords2.y;
	var atlas_x:int = get_merged_tile_id(coords1.x + 1, coords2.x + 1) - 1;
	#hostile death
	if atlas_x == GV.TileId.ZERO - 1 and atlas_y in GV.T_KILLABLE_BY_ZEROING:
		atlas_y = GV.TypeId.REGULAR;
	assert(atlas_y != -1 && atlas_x != -1);
	return Vector2i(atlas_x, atlas_y);
'''

'''
	if new_pos != old_pos or (GV.tracking_cam_trigger_mode == GV.TrackingCamTriggerMode.FINISH_ACTION and pos_t != self.pos_t):
		moved_for_tracking_cam.emit();
'''

'''
	# test duplicator world
	$DuplicatorPathController.set_gv(GV);
	$DuplicatorPathController.set_world(self);
	var test:float = $DuplicatorPathController.test_gv();
	print(test);
'''

'''
const T_ENEMY:Array = [TypeId.DUPLICATOR, TypeId.HOSTILE, TypeId.VOID, TypeId.SQUID];
'''

'''
func pc_placeholder():
	print("PLACEHOLDER")
	actions.push_back(Vector3i.ZERO);
'''

'''
	# delay movement by one frame to wait for tilemap collider update
	# TODO if tile is both converting and sliding, and one of them finalizes while await is happening, world will be reset to null
	await world.get_tree().physics_frame;
'''

'''
		player.add_premove(Premove.new(player, Vector2i(-1, 0), GV.ActionId.SPLIT))
		player.add_premove(Premove.new(player, Vector2i(1, 0), GV.ActionId.SPLIT))
		print(get_atlas_coords(GV.LayerId.TILE, Vector2i(-47, -8)));
		print($Cells.get_cell_atlas_coords(GV.LayerId.TILE, Vector2i(-47, -8)))


'''

'''
	#callback
	if not premove_callback_upcoming:
		call_deferred("try_curr_frame_premoves");
		premove_callback_upcoming = true;
'''

'''
		# try to catch the ultra rare bug
		if remaining_dist == 40 and collider is TileMap:
			print(collision.get_position());
			print(collision.get_normal());
			print(tile.world.get_atlas_coords(GV.LayerId.TILE, tile.pos_t));
			assert(false);
'''

'''
		# animation should be started from action_func
		# same for sound effects
		# same for $Cells update

		# update player-position-related stats from action_func since player can be pushed (bc push/slide weights adjustable from game settings)
		# these include player_pos_t, is_player_alive
		
		# update player_last_dir; this is used by enemies to predict player movement, so only player-initiated actions count
'''

'''
	if initiated:
		# squid club not busy after pushing a tile
		if not is_roaming():
			set_is_busy(true);
'''

'''
	# update tiles_in_transient and AltId TILE
	# if is_initializing_transit, transient tile would've already been removed
	if not is_initializing_transit and not is_reversed:

var debug_entity:Entity;

	debug_entity = world.get_aligned_tile_entity(world.atlas_coords_to_type_id(atlas_coords), pos_t);
	assert(not debug_entity or debug_entity.is_busy);

# NOTE if is_aligned assert(world.is_tile(pos_t)) is invalid bc animate_*() might've erased cell already
'''

'''
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if action_timer:
			action_timer.queue_free();
'''

'''
const PLAYER_COLLIDER_SCALE:float = 0.98;

#	#init physics enabler size
#	set_tile_push_limit(abilities["tile_push_limit"]);
#
#	#scale shapecasts (bc inspector can't handle precise floats)
#	var shape_LR:RectangleShape2D = preload("res://Objects/ShapeCastShapeLR.tres");
#	var shape_UD:RectangleShape2D = preload("res://Objects/ShapeCastShapeUD.tres");
#	shape_LR.size.y *= GV.PLAYER_COLLIDER_SCALE;
#	shape_UD.size.x *= GV.PLAYER_COLLIDER_SCALE;


func _ready() -> void:
	collision_shape.scale = GV.PLAYER_COLLIDER_SCALE * Vector2.ONE;
'''

'''
		# try to catch the ultra rare bug
		if remaining_dist == 40 and collider is TileMap:
			print(collision.get_position());
			print(collision.get_normal());
			print(tile.world.get_atlas_coords(GV.LayerId.TILE, tile.pos_t));
			assert(false);
		if remaining_dist == 40 and collider is TileForTilemap:
			print("collider tile: ", collider);
			print(collision.get_normal());
			print(tile.pos_t, collider.pos_t);
			print(tile.position, collider.position);
'''

'''
func get_transit_tile(pos_t:Vector2i, include_transient:bool, remove_transient:bool = true) -> TileForTilemap:
	assert(not is_tile(pos_t))
	
	if include_transient:
		var tile:TileForTilemap = get_aligned_tile_in_transient(pos_t);
		if tile:
			if remove_transient:
				remove_aligned_tile_in_transient(tile);
			return tile;
	
	for tile in $TransitTiles.get_children():
		assert(not (include_transient and tile.is_aligned and tile.pos_t == pos_t));
	
	return get_pooled_tile(pos_t);
'''

# Type and Entity Key/Busy/Removal and TileMap and aligned_tiles_in_transient and tile_pool Changes
# MERGE Case 1: m: b->b, g: a->a
#	not reversed
#		on g.finalize,
#			m.entity.key does not change
#			m.entity.busy becomes false
#			g.entity is removed
#			tilemap does not change
#			add m to aligned_tiles_in_transient
#			return to pool if conversion animators finished
#		on m.finalize,
#			change m.entity.key to pos_t if not moving
#			set atlas_coords if not moving
#			remove m from aligned_tiles_in_transient if not moving (else already removed)
#			return to pool if not moving
#	reversed
#		on g.finalize,
#			set g.entity.key to pos_t
#			set g.entity.busy to false
#			set m.entity.busy to false
#			set atlas_coords
#			return to pool if conversion animators finished
#		on m.finalize,
#			set m.entity.key to pos_t
#			set atlas_coords
#			return to pool
# MERGE Case 2: m: b->a, g: a->a, b != a
#	not reversed
#		on g.finalize,
#			g.entity.key changes from g to m
#			m.entity is removed
#			g.entity.busy becomes false
#			tilemap does not change
#			add m to aligned_tiles_in_transient
#			return to pool if conversion animators finished
#		on m.finalize,
#			change m.entity.key to pos_t if not moving
#			set atlas_coords if not moving
#			remove m from aligned_tiles_in_transient if not moving
#			return to pool if not moving
#	reversed
#		""
# MERGE Case 3 (Death by Zeroing): m: b->REG, g: a->a, b != REG, a != REG
#	not reversed
#		on g.finalize,
#			remove g.entity
#			remove m.entity
#			tilemap doesn't change
#			add m to aligned_tiles_in_transient
#			return to pool if conversion animators finished
#		on m.finalize,
#			set atlas_coords if not moving
#			remove m from aligned_tiles_in_transient if not moving
#			return to pool if not moving
#	reversed
#		""
# SPLIT Case 1: s: a->a, g: a->a
#	not reversed
#		on g.finalize,
#			change g.entity.key from g to pos_t
#			set g.busy to false
#			set s.busy to false
#			set atlas_coords at pos_t
#			add s to aligned_tiles_in_transient
#			return to pool if conversion animators finished
#		on s.finalize,
#			change s.entity.key to pos_t if not moving
#			set atlas_coords if not moving
#			remove s from aligned_tiles_in_transient if not moving
#			return to pool if not moving
#	reversed
#		on g.finalize,
#			set g.entity.key to pos_t
#			set g.entity.busy to false
#			remove s.entity
#			set unsplit atlas_coords at pos_t
#			return to pool if conversion animators finished
#		on s.finalize,
#			return to pool
# SPLIT Case 2: s: a->REG, g: a->a, a != REG
#	not reversed
#		on g.finalize
#			change g.entity.key to pos_t
#			set g.busy to false
#			no need to remove s.entity since it was transferred to g
#			set atlas_coords at pos_t
#			add s to aligned_tiles_in_transient
#			return to pool if conversion animators finished
#		on s.finalize
#			set atlas_coords if not moving
#			remove s from aligned_tiles_in_transient if not moving
#			return to pool if not moving
#	reversed
#		on g.finalize
#			set g.entity.key to pos_t
#			set g.busy to false
#			set unsplit atlas_coords at pos_t
#			return to pool if conversion animators finished
#		on s.finalize
#			return to pool
# SHIFT:
#	set entity.key to pos_t
#	set entity.busy to false
#	set atlas_coords at pos_t
#	return to pool if conversion animators finished

''' not needed bc front/back/merger/splitter tiles are always null when initialize_*() is called, and body of finalize_transit() is never entered when is_initializing_transit

var temp_front_tile:TileForTilemap;
var temp_back_tile:TileForTilemap;
var temp_merger_tile:TileForTilemap;
var temp_splitter_tile:TileForTilemap;

	front_tile = temp_front_tile;
	back_tile = temp_back_tile;
	set_merger_tile(temp_merger_tile);
	set_splitter_tile(temp_splitter_tile);
	temp_front_tile = null;
	temp_back_tile = null;
	temp_merger_tile = null;
	temp_splitter_tile = null;

	assert(tile.temp_front_tile == null);
	assert(tile.temp_back_tile == null);
	assert(tile.temp_merger_tile == null);
	assert(tile.temp_splitter_tile == null);
'''

'''
	get_viewport().set_as_audio_listener_2d(true);
'''

'''
const P_GEN_DUPLICATOR:float = 0.0005;
const P_GEN_HOSTILE:float = 0.005;

	# tile type
	var type_id:int = GV.TypeId.REGULAR;
	var n_type:float = randf();
	if n_type < 0.2:#GV.P_GEN_DUPLICATOR:
		type_id = GV.TypeId.DUPLICATOR;
		print("DUP GEN")
	elif n_type < GV.P_GEN_HOSTILE:
		type_id = GV.TypeId.HOSTILE;
'''

'''
			print("finalize ", GV.TransitId.keys()[move_transit_id], "is_aligned: ", is_aligned, " move_controller.dir: ", move_controller.dir, "position: ", position);

		# check for perp collision causing unalignment
		if collider is TileForTilemap and collider.move_controller and not Vector2(collider.move_controller.dir).dot(dir):
			print(dir, collider.move_controller.dir, prev_position, tile.position);

	var curr_pos_t:Vector2i = GV.world_to_pos_t(tile.position);
	var offset:Vector2 = tile.position - GV.pos_t_to_world(curr_pos_t); #this is the vector from nearest grid center (not intersection) to tile position
	if (dir.x and abs(offset.y) > GV.SNAP_TOLERANCE) or \
	(dir.y and abs(offset.x) > GV.SNAP_TOLERANCE):
		print("START UNALIGNED from ", tile.position, " in dir ", dir);
'''

'''
var is_busy:bool = false; # true if premoves are unable to be consumed
var is_premove_queued:bool = false;
var is_inactive:bool = false;
var is_task_active:bool = false;
'''

'''
#func is_premove_possible() -> bool:
	#return not is_busy and (not action_timer or action_timer.is_stopped()) and premoves and is_active();
#
#func is_pathfind_warranted() -> bool:
	#if not path_controller or is_task_active or is_busy or not is_aligned():
		#return false;
	#return action_timer.is_stopped() and not premoves and is_active();

#func try_premove():
	#if is_premove_possible():
		#if curr_state != State.BUSY and is_aligned():
			#assert(world.is_tile(get_pos_t()));
		#world.add_curr_frame_premove_entity(self);
		#curr_state = State.PREMOVING;


	if is_active():
		if curr_state == State.INACTIVE:
			# start timer
			if action_timer:
				assert(action_timer.is_stopped());
				action_timer.start(get_initial_action_cooldown());
			
			# change state
			assert(premoves.is_empty());
			if action_timer and not action_timer.is_stopped():
				change_state(State.COOLDOWN);
			elif path_controller and is_aligned():
				change_state(State.PATHFINDING);
			else:
				change_state(State.IDLE);
	
	elif curr_state not in [State.BUSY, State.INACTIVE]:
		change_state(State.INACTIVE);
'''

'''
# if is_aligned(), this should represent the aligned pos_t
# if not aligned and not busy, this should represent world_to_pos_t(get_position())
# so that active rect can update the entity's active status
# NOTE if not null and busy, forcing pos_t == world_to_pos_t(get_position()) is unnecessary
# bc lots of updates will be required if tile is bouncing back and forth
# and active status will be updated anyways when set_busy(false) is called.
# A small number of redundant calls for updating active status (due to outdated pos_t) is acceptable.

func get_pos_t() -> Variant:
	if body:
		if body is TileForTilemap and body.is_aligned:
			return body.pos_t;
		return null;
	else:
		return pos_t;

func get_pos_t(use_approx:bool) -> Variant:
	if is_aligned() or use_approx:
		return pos_t;
	return null;
'''
