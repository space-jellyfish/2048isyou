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
extends Node #for _process()

# emitted when body emits moved or set_body/set_pos_t changes entity position
# assumes body has a moved signal
signal moved_for_tracking_cam;
signal moved_for_path_controller(pos_t:Vector2i, is_reversed:bool, resulting_entity:Entity);

var world:World;
var body:Node2D; #if null, refer to pos_t (entity is in TileMap)
var entity_id:int; #should not change after init
var pos_t:Vector2i;
var premoves:Array[Premove];
var is_busy:bool = false; #true if premoves are unable to be consumed
# controls entity movement/behavior
# path_controller functions should be multithreaded for performance
var path_controller:RefCounted;
var action_timer:Timer;
var task_id:int;
var is_task_active:bool = false;
var actions:Array[Vector3i];


func _init(world:World, body:Node2D, entity_id:int, pos_t:Vector2i):
	assert(entity_id not in GV.T_NONE_OR_REGULAR);
	self.world = world;
	self.body = body;
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
	if entity_id in GV.E_HAS_PATHFINDING:
		if GV.global_action_timers[entity_id]:
			action_timer = GV.global_action_timers[entity_id];
		else:
			action_timer = Timer.new();
		
		action_timer.timeout.connect(_on_action_timer_timeout);
		action_timer.start(get_initial_action_cooldown());

func get_initial_action_cooldown() -> float:
	return randf_range(0, GV.action_cooldowns[entity_id]);

func get_action_cooldown() -> float:
	return GV.action_cooldowns[entity_id] + randf_range(0, GV.action_cooldown_deviations[entity_id]);

func _on_action_timer_timeout():
	if is_premove_possible():
		world.add_curr_frame_premove_entity(self);

func is_premove_possible() -> bool:
	return not is_busy and (not action_timer or action_timer.is_stopped) and premoves;

func add_premove(premove:Premove):
	premoves.push_back(premove);
	
	if is_premove_possible():
		world.add_curr_frame_premove_entity(self);

func clear_premoves():
	premoves.clear();
	
func is_roaming():
	return entity_id == GV.EntityId.SQUID_CLUB or (entity_id == GV.EntityId.PLAYER and not GV.snap_mode);

func try_curr_frame_premoves():
	if is_roaming():
		clear_premoves();
	else:
		#aligned, consume first premove
		if premoves:
			try_premove(premoves.pop_front());

func try_premove(premove:Premove):
	var initiated:bool = false;
	if premove.action_id == GV.ActionId.SLIDE:
		initiated = world.try_slide(self, premove.tile_entity, premove.dir, false);
	elif premove.action_id == GV.ActionId.SPLIT:
		initiated = world.try_split(self, premove.tile_entity, premove.dir, false);
	elif premove.action_id == GV.ActionId.SHIFT:
		initiated = world.try_shift(self, premove.tile_entity, premove.dir, false);
	elif premove.action_id == GV.ActionId.NONE:
		return;
	
	if initiated:
		# animation should be started from action_func
		# same for sound effects
		# same for $Cells update

		# update player-position-related stats from action_func since player can be pushed (bc push priority adjustable from game settings)
		# these include player_pos_t, is_player_alive
		
		# update player_last_dir; this is used by enemies to predict player movement, so only player-initiated actions count
		if not is_roaming():
			set_is_busy(true);
		
	else:
		print("premoves cleared")
		clear_premoves();

func is_tile() -> bool:
	return not body or body is TileForTilemap;

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

func set_is_busy(is_busy:bool):
	self.is_busy = is_busy;
	
	if is_premove_possible():
		world.add_curr_frame_premove_entity(self);
	elif not is_busy and not premoves and entity_id in GV.E_HAS_PATHFINDING and get_pos_t() != null:
		# start pathfinding
		task_id = WorkerThreadPool.add_task(path_controller.get_actions, false, "pathfinding");
		is_task_active = true;

func _on_body_moved_for_tracking_cam():
	moved_for_tracking_cam.emit();

func get_position() -> Vector2:
	return body.position if body else GV.pos_t_to_world(pos_t);

func get_pos_t() -> Variant:
	if body:
		if body is TileForTilemap and body.is_aligned:
			return body.pos_t;
		return null;
	else:
		return pos_t;

func _process(delta: float) -> void:
	if is_task_active and WorkerThreadPool.is_task_completed(task_id):
		WorkerThreadPool.wait_for_task_completion(task_id);
		
		# populate premoves
		for action in actions:
			var premove := Premove.new(self, Vector2i(action.x, action.y), action.z);
			add_premove(premove);
		
		# reset stuff
		actions.clear();
		is_task_active = false;
	
