# premove system
# how does consume_premove know tile_pos_t?
# how to clear premoves from a specific instance of entity if it dies?
# ensure if an entity dies or its move fails, only that entity's premoves are cleared
# let squid club have multiple premoves consumed per frame
# update entity stats (is_player_alive, player_pos_t, ...)
# call (deferred) if premove added or action finished

# manages premoves for an entity instance
# clear premoves if entity dies or last premove failed
# roaming entities can try new premoves before the old ones finish
class_name Entity

# emitted when body emits moved or set_body_as_key/set_pos_t_as_key changes entity position
# assumes body has a moved signal
signal moved_for_tracking_cam;
signal moved_for_path_controller(pos_t:Vector2i, is_reversed:bool, resulting_entity:Entity);
signal died(killer_entity:Entity);

var world:World;
var body:Node2D; # if null, refer to pos_t (entity is in TileMap)
var entity_id:int; # should not change after init
# represents nearest pos_t = world_to_pos_t(get_position())
# NOTE if STP, represents top left corner
var pos_t:Vector2i;
var size:Vector2i; # (k, k) if STP else (1, 1)
var premoves:Array[Premove];

# add a top-level FSM for escape/hunt/wander maybe
# NOTE every state has precedence over the ones below it
enum State {
	DEAD, # necessary bc due to potential key change, entity cannot be removed from entities_with_curr_frame_premoves with certainty
	BUSY,
	INACTIVE,
	COOLDOWN,
	PREMOVING,
	PATHFINDING, # wait till premoving/cooldown ends before starting pathfind so the most recent world info is used
	IDLE, # assume premoves empty; if not, go to PREMOVING instead
}
var curr_state:int = State.IDLE;
var is_task_active:bool = false;

# controls entity movement/behavior
# path_controller functions should be multithreaded for performance
var path_controller:RefCounted; # null if entity doesn't have pathfinding
var action_timer:Timer; # null if entity doesn't have pathfinding
var task_id:int;
var task_src_pos_t:Vector2i;
var task_actions:Array[Vector3i];


func get_new_state(is_busy:bool, is_active:Variant) -> int:
	if curr_state == State.DEAD:
		return State.DEAD;
	elif is_busy:
		return State.BUSY;
	elif (is_active is bool and not is_active) or (is_active == null and not is_active()):
		return State.INACTIVE;
	elif action_timer and not action_timer.is_stopped():
		return State.COOLDOWN;
	elif not premoves.is_empty():
		return State.PREMOVING;
	elif path_controller and is_aligned():
		return State.PATHFINDING;
	else:
		return State.IDLE;

func change_state(state:int, reenter:bool):
	if curr_state != state or reenter:
		exit_state(curr_state);
		curr_state = state;
		enter_state(state);
		#if entity_id == GV.EntityId.DUPLICATOR:
			#print(GV.EntityId.keys()[entity_id], " changed state to ", State.keys()[curr_state]);

func enter_state(state:int):
	match state:
		State.DEAD:
			pass;
		State.BUSY:
			pass;
		State.INACTIVE:
			if action_timer:
				action_timer.stop();
			clear_premoves();
		State.COOLDOWN:
			assert(action_timer and not action_timer.is_stopped());
		State.PREMOVING:
			assert(not action_timer or action_timer.is_stopped());
			assert(not premoves.is_empty());
			world.add_curr_frame_premove_entity(self);
		State.PATHFINDING:
			# cannot assert(not is_task_active) bc pathfinder can finish whenever
			assert(path_controller);
			assert(is_aligned());
			assert(not action_timer or action_timer.is_stopped());
			assert(premoves.is_empty());
			
			# start pathfinding in new thread
			if not is_task_active:
				task_src_pos_t = get_pos_t();
				task_id = WorkerThreadPool.add_task(path_controller.get_actions, false, "pathfinding");
				is_task_active = true;
			
			# debug pathfinding in main thread
			#task_src_pos_t = get_pos_t();
			#path_controller.get_actions();
			#for task_action in task_actions:
				#var premove := Premove.new(self, Vector2i(task_action.x, task_action.y), task_action.z);
				#add_premove(premove, false);
			#task_actions.clear();
		State.IDLE:
			pass;

func exit_state(state:int):
	match state:
		State.DEAD:
			pass;
		State.BUSY:
			pass;
		State.INACTIVE:
			pass;
		State.COOLDOWN:
			pass;
		State.PREMOVING:
			pass;
		State.PATHFINDING:
			pass;
		State.IDLE:
			pass;

func _init(world:World, body:Node2D, entity_id:int, pos_t:Vector2i, size:Vector2i, is_split_spawned:bool):
	assert(entity_id not in GV.T_NONE_OR_REGULAR);
	self.world = world;
	self.body = body;
	self.entity_id = entity_id;
	self.pos_t = pos_t;
	self.size = size;
	
	# connections
	if body:
		body.moved.connect(_on_body_moved);
	
	# path controller stuff
	match entity_id:
		GV.EntityId.DUPLICATOR:
			path_controller = DuplicatorPathController.new();
	
	if path_controller:
		path_controller.set_gv(GV);
		path_controller.set_world(world);
		path_controller.set_cells(world.get_node("Cells"));
		path_controller.set_entity(self);
		moved_for_path_controller.connect(path_controller.on_entity_move_finalized);
	
	# action timer stuff
	if path_controller:
		if GV.global_action_timers[entity_id]:
			action_timer = GV.global_action_timers[entity_id];
		else:
			action_timer = Timer.new();
		
		action_timer.one_shot = true;
		action_timer.timeout.connect(_on_action_timer_timeout);
		world.get_node("ActionTimers").add_child(action_timer); # assume Entity isn't init until world ready
		assert(action_timer.is_inside_tree());
		
		if is_active():
			var cd:float = get_action_cooldown(true) if is_split_spawned else get_initial_action_cooldown();
			action_timer.start(cd);
	
	# initialize state
	change_state(get_new_state(false, null), true);

func is_tile() -> bool:
	return not body or body is TileForTilemap;

func is_aligned() -> bool:
	return not body or (body is TileForTilemap and body.is_aligned);

# NOTE return not is_aligned() is incorrect; snap mode entity isn't aligned when moving
func is_roaming():
	return entity_id == GV.EntityId.SQUID_CLUB or (entity_id == GV.EntityId.PLAYER and not GV.snap_mode);

func is_busy() -> bool:
	return curr_state == State.BUSY;

func is_dead() -> bool:
	return curr_state == State.DEAD;

func is_active() -> bool:
	if body:
		return Rect2(world.active_rect_t.position * GV.TILE_WIDTH, world.active_rect_t.size * GV.TILE_WIDTH).has_point(get_position());
	return world.active_rect_t.intersects(Rect2i(pos_t, size));

func get_position() -> Vector2:
	if body:
		return body.position;
	return 0.5 * (GV.pos_t_to_world(pos_t) + GV.pos_t_to_world(pos_t + size - Vector2i.ONE));

# returns pos_t if is_aligned else null
func get_pos_t() -> Variant:
	if is_aligned():
		return pos_t;
	return null;

func _process():
	if is_task_active and WorkerThreadPool.is_task_completed(task_id):
		WorkerThreadPool.wait_for_task_completion(task_id);
		
		# populate premoves
		if curr_state == State.PATHFINDING:
			for task_action in task_actions:
				var premove := Premove.new(self, Vector2i(task_action.x, task_action.y), task_action.z);
				add_premove(premove, false);
		
		# reset stuff
		task_actions.clear();
		is_task_active = false;
		
		# change state
		if curr_state == State.PATHFINDING:
			# reenter to allow PATHFINDING -> PATHFINDING transition to restart pathfinding
			# since current state is PATHFINDING, no other state can get reentered
			change_state(get_new_state(false, null), true);

func die(killer_entity:Entity) -> void:
	#print(GV.EntityId.keys()[entity_id], " at ", pos_t, " died")
	if action_timer:
		action_timer.queue_free();
	
	assert(world.get_entity(entity_id, pos_t, body if body else pos_t) == self);
	world.remove_entity(entity_id, pos_t, body if body else pos_t);
	if world.player == self:
		world.player = null;
	died.emit(killer_entity);
	change_state(State.DEAD, false);

# min wait time until initial action
func get_initial_action_cooldown() -> float:
	return randf_range(0, GV.action_cooldowns[entity_id]);

# min wait time between consecutive initiated actions
func get_action_cooldown(last_premove_initiated:bool) -> float:
	var cd:float = GV.action_cooldowns[entity_id] + randf_range(0, GV.action_cooldown_deviations[entity_id]);
	if not last_premove_initiated:
		cd *= GV.UNINITIATED_PREMOVE_COOLDOWN_DISCOUNT;
	return cd;

func _on_action_timer_timeout():
	# change state
	# don't do anything if DEAD
	if curr_state == State.COOLDOWN:
		change_state(get_new_state(false, null), false);
	
	if curr_state != State.BUSY and is_aligned():
		assert(world.is_tile(get_pos_t()));

func set_is_busy(is_busy:bool):
	# change state
	change_state(get_new_state(is_busy, null), false);
	
	if curr_state != State.BUSY and is_aligned():
		assert(world.is_tile(get_pos_t()));

func add_premove(premove:Premove, change_state:bool = true):
	premoves.push_back(premove);
	
	# change state
	if change_state:
		change_state(get_new_state(curr_state == State.BUSY, null), false);

func clear_premoves():
	premoves.clear();

# NOTE roaming entity can push multiple tiles (consume multiple premoves) in a single frame
# NOTE cannot assert is_aligned() bc might've been pushed (and squid club isn't aligned)
# NOTE cannot assert is_premove_possible() bc might've been pushed
func try_curr_frame_premoves():
	# might've been pushed or deactivated
	if curr_state != State.PREMOVING:
		return;
	
	assert(premoves);
	consume_premove();
	
	# change state
	change_state(get_new_state(curr_state == State.BUSY, null), curr_state == State.PREMOVING);

func consume_premove():
	var premove:Premove = premoves.pop_front();
	var initiated:bool = false;
	#print("consume premove ", premove.dir, premove.action_id, "from ", get_pos_t());
	
	if curr_state != State.BUSY and is_aligned():
		assert(world.is_tile(get_pos_t()));
	assert(not action_timer or action_timer.is_stopped());
	
	if premove.action_id == GV.ActionId.SLIDE:
		initiated = world.try_slide(self, premove.tile_entity, premove.dir, false);
	elif premove.action_id == GV.ActionId.SPLIT:
		initiated = world.try_split(self, premove.tile_entity, premove.dir, false);
	elif premove.action_id == GV.ActionId.SHIFT:
		initiated = world.try_shift(self, premove.tile_entity, premove.dir, false);
	elif premove.action_id == GV.ActionId.NONE:
		pass;
	
	# start timer
	assert(is_active());
	if path_controller:
		action_timer.start(get_action_cooldown(initiated));
	
	# clear premoves
	if not initiated:
		clear_premoves();

func set_body_as_key(body:Node2D):
	# check if no action required
	if self.body == body:
		return;
	
	# assert position does not change
	# if position should change, remove this assertion and emit moved_for_tracking_cam if applicable
	var old_pos:Vector2 = get_position();
	var new_pos:Vector2 = body.position if body else GV.pos_t_to_world(pos_t);
	assert(old_pos == new_pos);
	
	# connect/disconnect body.moved signal
	if self.body and self.body != body:
		self.body.moved.disconnect(_on_body_moved);
	if body and body != self.body:
		body.moved.connect(_on_body_moved);
	
	# change keys
	var new_pos_t:Vector2i = GV.world_to_pos_t(body.position) if body else pos_t;
	change_keys(pos_t, new_pos_t, self.body if self.body else pos_t, body if body else new_pos_t);
	
	# update properties
	self.body = body;
	self.pos_t = new_pos_t;

	if curr_state != State.BUSY and is_aligned():
		assert(world.is_tile(get_pos_t()));

# NOTE body is set to null
func set_pos_t_as_key(pos_t:Vector2i):
	# check if no action required
	if self.pos_t == pos_t and not body:
		return;
	
	# assert position does not change
	# if position should change, remove this assertion and emit moved_for_tracking_cam if applicable
	var old_pos:Vector2 = get_position();
	var new_pos:Vector2 = body.position if body else GV.pos_t_to_world(pos_t);
	assert(old_pos == new_pos);
	
	# connect/disconnect body.moved signal
	if body:
		body.moved.disconnect(_on_body_moved);
	
	# change keys
	change_keys(self.pos_t, pos_t, body if body else self.pos_t, pos_t);
	
	# update properties
	self.body = null;
	self.pos_t = pos_t;
	
	if curr_state != State.BUSY and is_aligned():
		assert(world.is_tile(get_pos_t()));

func change_keys(old_pos_t:Vector2i, new_pos_t:Vector2i, old_key:Variant, new_key:Variant):
	world.remove_entity(entity_id, old_pos_t, old_key);
	world.add_entity(entity_id, new_pos_t, new_key, self);

func set_pos_t(new_pos_t:Vector2i):
	if new_pos_t != pos_t:
		change_keys(pos_t, new_pos_t, body if body else pos_t, body if body else new_pos_t);
		pos_t = new_pos_t;

func _on_body_moved():
	if is_dead():
		return;
	
	set_pos_t(GV.world_to_pos_t(body.position));
	
	if GV.tracking_cam_trigger_mode == GV.TrackingCamTriggerMode.LEAVE_AREA:
		moved_for_tracking_cam.emit();

func activate():
	assert(is_active());
	change_state(get_new_state(curr_state == State.BUSY, true), false);

func deactivate():
	assert(not is_active());
	change_state(get_new_state(curr_state == State.BUSY, false), false);
