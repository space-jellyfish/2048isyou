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

# emitted when body emits moved or set_body/set_pos_t changes entity position
# assumes body has a moved signal
signal moved_for_tracking_cam;
signal moved_for_path_controller(pos_t:Vector2i, is_reversed:bool, resulting_entity:Entity);

var world:World;
var body:Node2D; #if null, refer to pos_t (entity is in TileMap)
var entity_id:int; #should not change after init
var pos_t:Vector2i; #NOTE invalid if body not null
var premoves:Array[Premove];
var is_busy:bool = false; #true if premoves are unable to be consumed
# controls entity movement/behavior
# path_controller functions should be multithreaded for performance
var path_controller:RefCounted;
var action_timer:Timer; #null if entity doesn't have pathfinding
var task_id:int;
var is_task_active:bool = false;
var actions:Array[Vector3i];


func _init(world:World, body:Node2D, entity_id:int, pos_t:Vector2i):
	assert(entity_id not in GV.T_NONE_OR_REGULAR);
	self.world = world;
	self.body = body;
	if body:
		body.moved_for_tracking_cam.connect(_on_body_moved_for_tracking_cam);
	self.entity_id = entity_id;
	self.pos_t = pos_t;
	
	# add path controller
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
	# assume Entity isn't init until world ready
	if entity_id in GV.E_HAS_PATHFINDING:
		if GV.global_action_timers[entity_id]:
			action_timer = GV.global_action_timers[entity_id];
		else:
			action_timer = Timer.new();
		
		action_timer.one_shot = true;
		action_timer.timeout.connect(_on_action_timer_timeout);
		world.get_node("ActionTimers").add_child(action_timer);
		assert(action_timer.is_inside_tree());
		action_timer.start(get_initial_action_cooldown());

func _process():
	if is_task_active and WorkerThreadPool.is_task_completed(task_id):
		WorkerThreadPool.wait_for_task_completion(task_id);
		
		# populate premoves
		for action in actions:
			var premove := Premove.new(self, Vector2i(action.x, action.y), action.z);
			add_premove(premove);
		
		# reset stuff
		actions.clear();
		is_task_active = false;
		try_pathfind();
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if action_timer:
			action_timer.queue_free();

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
	try_premove();
	try_pathfind();

func set_is_busy(is_busy:bool):
	self.is_busy = is_busy;
	try_premove();
	try_pathfind();

func is_premove_possible() -> bool:
	return not is_busy and (not action_timer or action_timer.is_stopped()) and premoves;

func is_pathfind_warranted() -> bool:
	if entity_id not in GV.E_HAS_PATHFINDING or is_task_active or is_busy or not is_aligned():
		return false;
	return action_timer.is_stopped() and not premoves;

func try_premove():
	if is_premove_possible():
		world.add_curr_frame_premove_entity(self);

func try_pathfind():
	if is_pathfind_warranted():
		# start pathfinding in new thread
		#task_id = WorkerThreadPool.add_task(path_controller.get_actions, false, "pathfinding");
		#is_task_active = true;
		
		# debug pathfinding in main thread
		path_controller.get_actions(get_pos_t());
		for action in actions:
			var premove := Premove.new(self, Vector2i(action.x, action.y), action.z);
			add_premove(premove);
		actions.clear();

func add_premove(premove:Premove):
	premoves.push_back(premove);
	try_premove();

func clear_premoves():
	premoves.clear();

# NOTE roaming entity can push multiple tiles (consume multiple premoves) in a single frame
# NOTE cannot assert is_aligned() bc tile might've been pushed by another entity (and squid club isn't aligned)
func try_curr_frame_premoves():
	assert(not action_timer or action_timer.is_stopped());
	if premoves:
		consume_premove();

func consume_premove():
	var premove:Premove = premoves.pop_front();
	var initiated:bool = false;
	
	if premove.action_id == GV.ActionId.SLIDE:
		initiated = world.try_slide(self, premove.tile_entity, premove.dir, false);
	elif premove.action_id == GV.ActionId.SPLIT:
		initiated = world.try_split(self, premove.tile_entity, premove.dir, false);
	elif premove.action_id == GV.ActionId.SHIFT:
		initiated = world.try_shift(self, premove.tile_entity, premove.dir, false);
	elif premove.action_id == GV.ActionId.NONE:
		pass;
	
	if initiated:
		pass;
	else:
		clear_premoves();
	
	# start action timer
	if entity_id in GV.E_HAS_PATHFINDING:
		assert(action_timer.is_stopped());
		action_timer.start(get_action_cooldown(initiated));

func set_body(body:Node2D):
	#check if no action required
	if self.body == body:
		return;
	
	#find parameters for change_keys() function
	var old_key:Variant = self.body if self.body else pos_t;
	var new_key:Variant = body if body else pos_t;
	
	#update dictionary keys
	change_keys(old_key, new_key);
	
	#emit moved signal
	var old_pos:Vector2 = get_position();
	var new_pos:Vector2 = body.position if body else GV.pos_t_to_world(pos_t);
	if new_pos != old_pos:
		moved_for_tracking_cam.emit();
	
	#connect/disconnect body.moved signal
	if self.body and self.body != body:
		self.body.moved_for_tracking_cam.disconnect(_on_body_moved_for_tracking_cam);
	if body and body != self.body:
		body.moved_for_tracking_cam.connect(_on_body_moved_for_tracking_cam);
	
	#update properties
	self.body = body;

# NOTE body is set to null
func set_pos_t(pos_t:Vector2i):
	#check if no action required
	if self.pos_t == pos_t and not body:
		return;
	
	#find parameters for change_keys() function
	var old_key:Variant = body if body else self.pos_t;
	
	#update dictionary keys
	change_keys(old_key, pos_t);
	
	#emit moved signal
	var old_pos:Vector2 = get_position();
	var new_pos:Vector2 = GV.pos_t_to_world(pos_t);
	if new_pos != old_pos:
		moved_for_tracking_cam.emit();
	
	#connect/disconnect body.moved signal
	if body:
		body.moved_for_tracking_cam.disconnect(_on_body_moved_for_tracking_cam);
	
	#update properties
	self.pos_t = pos_t;
	self.body = null;

func change_keys(old_key:Variant, new_key:Variant):
	world.remove_entity(entity_id, old_key);
	world.add_entity(entity_id, new_key, self);

func _on_body_moved_for_tracking_cam():
	moved_for_tracking_cam.emit();

func get_position() -> Vector2:
	return body.position if body else GV.pos_t_to_world(pos_t);

func is_tile() -> bool:
	return not body or body is TileForTilemap;

func is_aligned() -> bool:
	return not body or (body is TileForTilemap and body.is_aligned);

func is_roaming():
	#return entity_id == GV.EntityId.SQUID_CLUB or (entity_id == GV.EntityId.PLAYER and not GV.snap_mode);
	return not is_aligned();

# returns pos_t if is_aligned else null
func get_pos_t() -> Variant:
	if body:
		if body is TileForTilemap and body.is_aligned:
			return body.pos_t;
		return null;
	else:
		return pos_t;
