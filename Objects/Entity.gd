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
signal moved;

var world:World;
var body:Node2D; # if null, refer to pos_t (entity is in TileMap)
var entity_id:int;
var pos_t:Vector2i;
var premoves:Array[Premove];
var is_busy:bool = false; #true if premoves are unable to be consumed


func _init(world:World, body:Node2D, entity_id:int, pos_t:Vector2i):
	self.world = world;
	self.body = body;
	self.entity_id = entity_id;
	self.pos_t = pos_t;

func has_premove():
	return not premoves.is_empty();

func add_premove(premove:Premove):
	premoves.push_back(premove);
	
	#if premove added or last move finished
	if not is_busy:
		world.add_curr_frame_premove_entity(self);

func clear_premoves():
	premoves.clear();
	
func is_roaming():
	return entity_id == GV.EntityId.SQUID_CLUB or (entity_id == GV.EntityId.PLAYER and not GV.snap_mode);

func try_curr_frame_premoves():
	if is_roaming():
		#roaming, consume all premoves
		while premoves:
			var premove:Premove = premoves.pop_front();
			try_premove(premove);
	else:
		#aligned, consume first premove
		if premoves:
			var premove:Premove = premoves.pop_front();
			try_premove(premove);

func try_premove(premove:Premove):
	var initiated:bool = false;
	if premove.action_id == GV.ActionId.SLIDE:
		initiated = world.try_slide(self, premove.tile_entity, premove.dir);
	elif premove.action_id == GV.ActionId.SPLIT:
		initiated = world.try_split(self, premove.tile_entity, premove.dir);
	elif premove.action_id == GV.ActionId.SHIFT:
		initiated = world.try_shift(self, premove.tile_entity, premove.dir);
	
	if initiated:
		# animation should be started from action_func
		# same for sound effects
		# same for $Cells update

		# update player-position-related stats from action_func since player can be pushed (bc push priority adjustable from game settings)
		# these include player_pos_t, is_player_alive
		
		# update player_last_dir; this is used by enemies to predict player movement, so only player-initiated actions count
		if not is_roaming():
			set_is_busy(true);
		
		match entity_id:
			GV.EntityId.PLAYER:
				world.get_node("Pathfinder").set_player_last_dir(premove.dir);
	else:
		print("premoves cleared")
		clear_premoves();

func is_tile() -> bool:
	return not body or body is TileForTilemap;

func set_entity_id_and_body(entity_id:int, body:Node2D):
	#check if no action required
	if self.entity_id == entity_id and self.body == body:
		return;
	
	#find parameters for change_keys() function
	var old_key:Variant = self.body if self.body else pos_t;
	var new_key:Variant = body if body else pos_t;
	
	#update dictionary keys
	change_keys(self.entity_id, entity_id, old_key, new_key);
	
	#emit moved signal
	var old_pos:Vector2 = get_position();
	var new_pos:Vector2 = body.position if body else GV.pos_t_to_world(pos_t);
	if new_pos != old_pos:
		moved.emit();
	
	#connect/disconnect body.moved signal
	if self.body and self.body != body:
		self.body.moved.disconnect(_on_body_moved);
	if body and body != self.body:
		body.moved.connect(_on_body_moved);
	
	#update properties
	self.entity_id = entity_id;
	self.body = body;

# NOTE body is set to null
func set_entity_id_and_pos_t(entity_id:int, pos_t:Vector2i):
	#check if no action required
	if self.entity_id == entity_id and self.pos_t == pos_t and not body:
		return;
	
	#find parameters for change_keys() function
	var old_key:Variant = body if body else self.pos_t;
	
	#update dictionary keys
	change_keys(self.entity_id, entity_id, old_key, pos_t);

	#update Pathfinder.player_pos_t
	if entity_id == GV.EntityId.PLAYER:
		if self.pos_t != pos_t:
			world.get_node("Pathfinder").rrd_clear_iad();
		world.get_node("Pathfinder").set_player_pos(pos_t);
	
	#emit moved signal
	var old_pos:Vector2 = get_position();
	var new_pos:Vector2 = GV.pos_t_to_world(pos_t);
	if new_pos != old_pos or (GV.tracking_cam_trigger_mode == GV.TrackingCamTriggerMode.FINISH_ACTION and pos_t != self.pos_t):
		moved.emit();
	
	#connect/disconnect body.moved signal
	if body:
		body.moved.disconnect(_on_body_moved);
	
	#update properties
	self.entity_id = entity_id;
	self.pos_t = pos_t;
	self.body = null;

func change_keys(old_entity_id:int, new_entity_id:int, old_key:Variant, new_key:Variant):
	world.remove_entity(old_entity_id, old_key);
	world.add_entity(new_entity_id, new_key, self);

func set_is_busy(is_busy:bool):
	self.is_busy = is_busy;
	if not is_busy and premoves:
		world.add_curr_frame_premove_entity(self);
		
func _on_body_moved():
	moved.emit();

func get_position() -> Vector2:
	return body.position if body else GV.pos_t_to_world(pos_t);

func get_pos_t() -> Variant:
	if body:
		if body is TileForTilemap and body.is_aligned:
				return body.pos_t;
		return null;
	else:
		return pos_t;
