# premove system
# how does consume_premove know tile_pos_t?
# how to clear premoves from a specific instance of entity if it dies?
# ensure if an entity dies or its move fails, only that entity's premoves are cleared
# let squid club have multiple premoves consumed per frame
# update entity stats (is_player_alive, player_pos_t, ...)
# call (deferred) if premove added or action finished

#manages premoves for an entity instance
#clear premoves if entity dies or last premove failed
#roaming entities can try new premoves before the old ones finish
class_name Entity

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
		initiated = world.try_slide(entity_id, premove.tile_entity, premove.dir);
	elif premove.action_id == GV.ActionId.SPLIT:
		initiated = world.try_split(entity_id, premove.tile_entity, premove.dir);
	elif premove.action_id == GV.ActionId.SHIFT:
		initiated = world.try_shift(entity_id, premove.tile_entity, premove.dir);
	
	if initiated:
		# animation should be started from action_func since hostiles don't call consume_premove()
		# same for sound effects
		# same for $Cells update

		# update player-position-related stats from action_func since player can be pushed (bc push priority adjustable from game settings)
		# these include player_pos_t, is_player_alive
		
		# update player_last_dir; this is used by enemies to predict player movement, so only player-initiated actions count
		if not is_roaming():
			is_busy = true;
		
		match entity_id:
			GV.EntityId.PLAYER:
				world.get_node("Pathfinder").set_player_last_dir(premove.dir);
	else:
		clear_premoves();

func is_tile() -> bool:
	return not body or body is TileForTilemap;
