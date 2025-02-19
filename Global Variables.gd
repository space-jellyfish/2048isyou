extends Node

const UINT8_MAX  = (1 << 8)  - 1 # 255
const UINT16_MAX = (1 << 16) - 1 # 65535
const UINT32_MAX = (1 << 32) - 1 # 4294967295

const INT8_MIN  = -(1 << 7)  # -128
const INT16_MIN = -(1 << 15) # -32768
const INT32_MIN = -(1 << 31) # -2147483648
const INT64_MIN = -(1 << 63) # -9223372036854775808

const INT8_MAX  = (1 << 7)  - 1 # 127
const INT16_MAX = (1 << 15) - 1 # 32767
const INT32_MAX = (1 << 31) - 1 # 2147483647
const INT64_MAX = (1 << 63) - 1 # 9223372036854775807

var factorials:Array[int] = [1];
var combinations:Array[Array] = [[1]];

#size-related stuff
const TILE_WIDTH:float = 40; #px
const VIEWPORT_RESOLUTION:Vector2 = Vector2(1600, 1200);
const CAMERA_RESOLUTION:Vector2 = Vector2(800, 600);
const BORDER_DISTANCE_T:int = 120; #128; #2000000000;
const BORDER_MIN_POS_T:Vector2i = -Vector2i(BORDER_DISTANCE_T, BORDER_DISTANCE_T);
const BORDER_MAX_POS_T:Vector2i = Vector2i(BORDER_DISTANCE_T, BORDER_DISTANCE_T);
const WORLD_MIN_POS_T:Vector2i = BORDER_MIN_POS_T + Vector2i.ONE; #leave gap for border cell
const WORLD_MAX_POS_T:Vector2i = BORDER_MAX_POS_T - Vector2i.ONE;

#level-related stuff
const LEVEL_COUNT:int = 17;
var current_level_index:int = 14;
var current_level_from_save:bool = false;
var level_scores = [];
var changing_level:bool = false;
var reverting:bool = false; #if true, fade faster and don't show lv name
#var through_goal:bool = false; #changing level via goal

#procgen-related stuff
const TILE_POW_MAX:int = 14;
const TILE_GEN_POW_MAX:int = 11;
const TILE_VALUE_COUNT:int = 2 * TILE_POW_MAX + 3;
const TILE_LOAD_BUFFER:float = 8 * TILE_WIDTH;
const TILE_UNLOAD_BUFFER:float = 8 * TILE_WIDTH;
const P_GEN_INVINCIBLE:float = 0.0005;
const P_GEN_HOSTILE:float = 0.005;

#pathfinder-related stuff
#var level_hash_numbers:Array = [];
#var x_hash_numbers:Array = [];
#var y_hash_numbers:Array = [];

#save-related stuff
#note non-export variables are not saved in packed scene
const PLAYER_SNAPSHOT_BADDIE_RANGE:float = 448;
var savepoint_id:int = -1; #id of savepoint at which player will spawn (after lv change)
var player_power:int; #saved for instantiation at dest goal
var player_ssign:int;
var current_savepoint_ids = []; #ids of saved savepoints
var current_savepoint_saves = []; #packed scene of level (at saved savepoints)
var current_snapshot_sizes = []; #size of player_snapshots (at saved savepoints)
var temp_player_snapshots = []; #keep player snapshots when reverting
var current_savepoint_powers = [];
var current_savepoint_ssigns = [];
var temp_player_snapshot_locations = []; #to reinstate after player spawns
var temp_player_snapshot_locations_new = [];
var current_savepoint_tiles_snapshot_locations = []; #2d array of array refs
var current_savepoint_tiles_snapshot_locations_new = [];
var current_savepoint_baddies_snapshot_locations = [];

var level_last_savepoint_ids:Array[int] = []; #in lv0, for spawning player after "home"
var level_initial_savepoint_ids:Array[int] = []; #id of goal where player first enters level
var level_initial_player_powers:Array[int] = [];
var level_initial_player_ssigns:Array[int] = [];

const ERROR_MESSAGE_FADE_TIME:float = 2;
const FADER_SPEED_SCALE_MAJOR:float = 1;
const FADER_SPEED_SCALE_MINOR:float = 1.2;
const LEVEL_NAME_FADE_IN_TIME:float = 1.6;
const LEVEL_NAME_DISPLAY_TIME:float = 3;
const LEVEL_NAME_FADE_OUT_TIME:float = 1.2;

const TRACKING_CAM_LEAD_RATIO:float = 1.35; #target = pos + ratio * (track_pos - pos)
const TRACKING_CAM_SLACK_RATIO:float = 0.15; #0.25; #ratio applied to slack (tracking movement along the non-trigger axis)
const TRACKING_CAM_TRANSITION_TIME:float = 1.28;
const PLAYER_SPAWN_INVINCIBILITY_TIME:float = 0.25;

const SNAP_TOLERANCE:float = 0.1; #epsilon; in px
const COLLISION_TEST_DISTANCE:float = 0.4;
const PLAYER_COLLIDER_SCALE:float = 0.98;
const PLAYER_MU:float = 0.16; #coefficient of friction
const PLAYER_SLIDE_SPEED:float = 33;
const PLAYER_SLIDE_SPEED_MIN:float = 8;
#const PLAYER_SPEED_RATIO:float = 0.9; #must be less than 1 so tile solidifies before premove
const TILE_SLIDE_SPEED:float = 288; #320

const SNAP_FRAME_COUNT:int = 1;
const COMBINING_FRAME_COUNT:int = 6; #9; #1;
const SPLITTING_FRAME_COUNT:int = 6; #9; #1;

const MOVE_REPEAT_DELAY_F0:int = 16; #16
const MOVE_REPEAT_DELAY_DF:int = -3; #-3
const MOVE_REPEAT_DELAY_DDF:int = 1; #1
const MOVE_REPEAT_DELAY_FMIN:int = 10; #10

const UNDO_REPEAT_DELAY_F0:int = 20;
const UNDO_REPEAT_DELAY_DF:int = -1;
const UNDO_REPEAT_DELAY_DDF:int = -1;
const UNDO_REPEAT_DELAY_FMIN:int = 14;

const PREMOVE_STREAK_END_DELAY = 6; #must >= MOVE_REPEAT_DELAY_F0 - slide frame count

const TILE_SHEET_HFRAMES = 31;
const TILE_SHEET_VFRAMES = 6;

const DUANG_TRIGGER_RATIO:float = 1/2.7;
const DUANG_TRIGGER_SEPARATION:float = (1 - DUANG_TRIGGER_RATIO) * TILE_WIDTH;
const DUANG_START_ANGLE:float = 1;
const DUANG_FACTOR:float = 1/sin(DUANG_START_ANGLE);
const DUANG_END_ANGLE:float = PI - DUANG_START_ANGLE;
const DUANG_SPEED:float = 0.1;

const DWING_START_ANGLE:float = 1;
const DWING_FACTOR:float = sin(DWING_START_ANGLE);
const DWING_END_ANGLE:float = PI - DWING_START_ANGLE;
const DWING_SPEED:float = 0.1;

const FADE_SPEED:float = 0.07;

const SHIFT_TIME:float = 6; #in frames
const SHIFT_LERP_WEIGHT:float = 0.6;
const SHIFT_SPEED_MIN:float = TILE_SLIDE_SPEED;
var SHIFT_LERP_WEIGHT_TOTAL:float = 0;
var SHIFT_DISTANCE_TO_MAX_SPEED:float;

var snap_mode:bool = true; #move mode

enum InputType {
	MOVE,
	UNDO,
	MODE, #toggle move mode
}

#animation-related stuff
enum ConversionAnimatorType {
	SCALE, #dwing, duang
	DUANG_FADE, #in, out
	DWING_FADE, #in, out
}

enum ConversionAnimatorId {
	DWING = (ConversionAnimatorType.SCALE << 1), #temp shrink upon split
	DUANG = (ConversionAnimatorType.SCALE << 1) + 1, #temp expand upon merge
	DUANG_FADE_IN = (ConversionAnimatorType.DUANG_FADE << 1),
	DUANG_FADE_OUT = (ConversionAnimatorType.DUANG_FADE << 1) + 1,
	DWING_FADE_IN = (ConversionAnimatorType.DWING_FADE << 1),
	DWING_FADE_OUT = (ConversionAnimatorType.DWING_FADE << 1) + 1,
}

enum ActionId {
	SLIDE,
	SPLIT,
	SHIFT,
}

enum TransitId {
	SLIDE, # uniform speed
	SPLIT,
	SHIFT, # accelerates to cover shift dist in same time as a slide
	MERGE,
}

# z_index
enum ZId {
	BACKGROUND = -10,
	HIDDEN_LABEL = -9,
	SAVE_OR_GOAL = -2,
	MOVING = -1, # tiles merging into another (stationary) tile; for simplicity, all sliding/shifting tiles are grouped here
	DEFAULT = 0, # walls, stationary tiles
	SPLITTING_NEW = 1,
	SPLITTING_OLD = 2,
	COMBINING_NEW = 3,
	COMBINING_OLD = 4,
	LEVEL_NAME = 10,
}

# layer, (mask)
enum CollisionId {
	DEFAULT = 1, # walls, non-converting tiles, squid (tiles, squid)
	SPLITTING, # splitting tiles, (non-splitted tiles, squid)
	COMBINING, # combining tiles, (non-merging tiles, squid)
	MEMBRANE, # membrane, (non-player tiles, squid)
	SAVE_OR_GOAL, # savepoint/goal, (hostile tiles, squid)
	TRACKING_CAM, # player (tracking cam)
}

const directions = {
	"left" : Vector2i(-1, 0),
	"right" : Vector2i(1, 0),
	"up" : Vector2i(0, -1),
	"down" : Vector2i(0, 1),
};

var abilities = {
	"home" : true,
	"restart" : true,
	"move_mode" : true,
	"undo" : true,
	"revert" : true,
	#"merge" : true,
	"split" : true,
	"shift" : true,
	"copy" : true,
};

enum TileId { #5 bits
	EMPTY = 0,
	ZERO = 16,
};

enum TypeId { #3 bits
	PLAYER = 0,
	INVINCIBLE,
	HOSTILE,
	VOID,
	REGULAR,
	SQUID,
}

enum BackId { #8 bits
	EMPTY = 0,
	BORDER_ROUND,
	BORDER_SQUARE,
	MEMBRANE,
	BLACK_WALL,
	BLUE_WALL,
	RED_WALL,
	SAVEPOINT,
	GOAL,
	BOARD_FRAME,
}

const B_WALL_OR_BORDER:Array = [BackId.BORDER_ROUND, BackId.BORDER_SQUARE, BackId.BLACK_WALL, BackId.BLUE_WALL, BackId.RED_WALL];
const B_SAVE_OR_GOAL:Array = [BackId.SAVEPOINT, BackId.GOAL];
const B_EMPTY:Array = [BackId.EMPTY, BackId.BOARD_FRAME];
const T_ENEMY:Array = [TypeId.INVINCIBLE, TypeId.HOSTILE, TypeId.VOID, TypeId.SQUID];

# NOTE TypeId should be usable as EntityId without conversion
enum EntityId {
	PLAYER, #for simplicity, player priorities/push_weight/tpl are the same when roaming
	INVINCIBLE,
	HOSTILE,
	VOID,
	NONE, #TypeId.REGULAR
	SQUID_BODY,
	SQUID_CLUB,
	STP_SPAWNING,
	STP_SPAWNED,
}

enum LayerId {
	BACK,
	TILE,
}

enum ColorId {
	ALL = 4,
	RED = 29,
	BLUE = 30,
	BLACK = 31,
	GRAY = 32,
};

#player tile_push_limit does not change when roaming
var tile_push_limits:Dictionary = {
	EntityId.PLAYER : 1,
	EntityId.INVINCIBLE : 1,
	EntityId.HOSTILE : 1,
	EntityId.VOID : 3,
	EntityId.NONE : 0,
	EntityId.SQUID_BODY : 0,
	EntityId.SQUID_CLUB : 6,
	EntityId.STP_SPAWNING : 0,
	EntityId.STP_SPAWNED : 2,
};

var merge_priorities:Dictionary = {
	-1 : -1,
	TypeId.REGULAR : 0,
	TypeId.PLAYER : 1,
	TypeId.HOSTILE : 2,
	TypeId.INVINCIBLE : 3,
	TypeId.VOID : 4,
	TypeId.SQUID : 5,
}

#push is possible if pusher push_weight >= pushed slide_weight
var slide_weights:Dictionary = {
	EntityId.PLAYER : 3, #INT64_MAX when roaming, but doesn't matter since only SQUID_CLUB can push player
	EntityId.INVINCIBLE : 2,
	EntityId.HOSTILE : 1,
	EntityId.VOID : 0,
	EntityId.NONE : 0,
	EntityId.SQUID_BODY : 0,
	EntityId.SQUID_CLUB : INT64_MAX,
	EntityId.STP_SPAWNING : INT64_MAX,
	EntityId.STP_SPAWNED : INT64_MAX,
}

#-1 if entity cannot push anything
var push_weights:Dictionary = {
	EntityId.PLAYER : 2,
	EntityId.INVINCIBLE : 1,
	EntityId.HOSTILE : 1,
	EntityId.VOID : 2,
	EntityId.NONE : -1,
	EntityId.SQUID_BODY : -1,
	EntityId.SQUID_CLUB : 3,
	EntityId.STP_SPAWNING : -1,
	EntityId.STP_SPAWNED : 2,
}

# (slide collision) arbitration modes
# use MIDPOINT to prevent higher priority entities from bullying lower priority entities by camping a cell
enum SlideArbitrationMode {
	MIDPOINT, # lower remaining_dist continues, higher move_priority continues if remaining_dist equal, both bounce if move_priority equal
	ENTITY, # higher move_priority continues, lower remaining_dist continues if move_priority equal, both bounce if remaining_dist equal 
}

# for tiebreaking when two slides collide at midpoint
# id of entity that initiated move is used, not EntityId of moving tile
var slide_priorities:Dictionary = {
	EntityId.PLAYER : 7,
	EntityId.INVINCIBLE : 4,
	EntityId.HOSTILE : 3,
	EntityId.VOID : 5,
	EntityId.NONE : -1,
	EntityId.SQUID_BODY : 2,
	EntityId.SQUID_CLUB : 1,
	EntityId.STP_SPAWNING : 0,
	EntityId.STP_SPAWNED : 6,
}

# for tiebreaking if 2+ entities have premoves queued (represents 'reaction time' of entity)
# enemies have higher priority so player cannot use premoving to cross enemy-protected cells
# roaming entities should use the premove system instead of initiating moves in the middle of physics frame
var premove_priorities:Dictionary = {
	EntityId.PLAYER : 3,
	EntityId.INVINCIBLE : 5,
	EntityId.HOSTILE : 4,
	EntityId.VOID : 6,
	EntityId.NONE : -1,
	EntityId.SQUID_BODY : 2,
	EntityId.SQUID_CLUB : 1,
	EntityId.STP_SPAWNING : 0,
	EntityId.STP_SPAWNED : 7,
	#snake continuity at 90deg turns?
}
var entity_ids_decreasing_premove_priority:Array;

var max_shift_dists:Dictionary = {
	TypeId.PLAYER : 4,
	TypeId.INVINCIBLE : 4,
	TypeId.HOSTILE : 0,
	TypeId.VOID : 8,
	TypeId.REGULAR : 0,
	TypeId.SQUID : 8,
}

enum SASearchId {
	DIJKSTRA,
	MDA, #manhattan distance astar
	IADA, #inconsistent abstract distance astar
	IADANR, #* no re-expansion
	IWDMDA, #iterative widening diamond *
	IWSMDA, #iterative widening square *
	SAIWDMDA, #simulated annealing *
	SAIWSMDA,

	#jps
	JPD, #(horizontally biased) jump point dijkstra
	JPMDA,
	JPIADA,
	JPIADANR,
	IWDJPMDA,
	IWSJPMDA,
	SAIWDJPMDA,
	SAIWSJPMDA,

	#cjps
	CJPD, #* constrained *
	CJPMDA,
	CJPIADA,
	CJPIADANR,
	IWDCJPMDA,
	IWSCJPMDA,
	SAIWDCJPMDA,
	SAIWSCJPMDA,

	#IDA/EPEA, QUANT, FMT/RRT
	SEARCH_END,
};

enum MessageId {
	SLIDE_MODE_NA,
	SNAP_MODE_NA,
	SPLIT_NA,
	SLIDE_NA,
	SHIFT_NA,
}

var messages:Dictionary = {
	MessageId.SLIDE_MODE_NA : "Slide mode is not available.",
	MessageId.SNAP_MODE_NA : "Snap mode is not available.",
	MessageId.SPLIT_NA : "Splitting is not available.",
	MessageId.SLIDE_NA : "Sliding is not available.",
	MessageId.SHIFT_NA : "Shifting is not available.",
}


func world_to_pos_t(pos:Vector2) -> Vector2i:
	return (pos / TILE_WIDTH).floor();

func pos_t_to_world(pos_t:Vector2i) -> Vector2:
	return (Vector2(pos_t) + Vector2(0.5, 0.5)) * TILE_WIDTH;

func world_to_xt(x:float) -> int:
	return floori(x / TILE_WIDTH);

func xt_to_world(x:int) -> float:
	return (x + 0.5) * TILE_WIDTH;
	
func same_sign_inclusive(a, b) -> bool:
	if a == 0:
		return true;
	if a > 0:
		return b >= 0;
	return b <= 0;

func same_sign_exclusive(a, b) -> bool:
	if a == 0:
		return false;
	if a > 0:
		return b > 0;
	return b < 0;
		
func factorial(n) -> int:
	if factorials.size() > n:
		return factorials[n];
	
	var ans = factorials[factorials.size() - 1];
	for i in range(factorials.size(), n+1):
		ans *= i;
		factorials.push_back(ans);
	return ans;

func combinations_gen(n, k) -> int:
	if n < k:
		return 0;
	if n == k:
		return 1;
	@warning_ignore("integer_division")
	return factorial(n)/factorial(k)/factorial(n-k);

func combinations_dp(n, k) -> int:
	#range check
	if n < 0 or k < 0 or k > n:
		return 0;
	
	#query stored answers
	if combinations.size() > n:
		if combinations[n][k] != -1:
			return combinations[n][k];
	else:
		#expand combinations
		for i in range(combinations.size(), n+1):
			var row = [];
			row.resize(i+1);
			row.fill(-1);
			combinations.push_back(row);
	
	#recursion
	var ans = 1 if (k == 0 or k == n) else (combinations_dp(n-1, k) + combinations_dp(n-1, k-1));
	combinations[n][k] = ans;
	return ans;

func sin_approx(angle_rad:float):
	pass;

#doesn't do ZERO->EMPTY optimization
func tile_val_to_id(power:int, ssign:int) -> int:
	return (power + 1) * ssign + TileId.ZERO;

# ssign should be 1 for TileId.ZERO (required by is_vals_mergeable())
func id_to_tile_val(id:int):
	if id == TileId.ZERO:
		return Vector2i(-1, 1);
	var signed_incremented_pow:int = id - TileId.ZERO;
	return Vector2i(absi(signed_incremented_pow) - 1, signi(signed_incremented_pow));

func is_approx_equal(a:float, b:float, tolerance:float) -> bool:
	if absf(a - b) <= tolerance:
		return true;
	return false;

func get_animator_type(animator_id:int) -> int:
	return animator_id >> 1;

#func set_tile_push_limit(_tile_push_limit):
#	abilities["tile_push_limit"] = _tile_push_limit;
#
#	#change physicsEnabler size
#	var size:Vector2 = PHYSICS_ENABLER_BASE_SIZE + abilities["tile_push_limit"] * 2 * GV.TILE_WIDTH * Vector2.ONE;
#	PHYSICS_ENABLER_SHAPE.set_size(size);


func _ready():
	#TODO remove these
	level_scores.resize(LEVEL_COUNT);
	level_scores.fill(0);
	level_last_savepoint_ids.resize(LEVEL_COUNT);
	level_last_savepoint_ids.fill(-1);
	level_initial_savepoint_ids.resize(LEVEL_COUNT);
	level_initial_player_powers.resize(LEVEL_COUNT);
	level_initial_player_ssigns.resize(LEVEL_COUNT);
	
	#calculate shift parameter
	for frame in range(1, SHIFT_TIME+1):
		var term_sign = 1;
		for term in range(1, frame+1):
			SHIFT_LERP_WEIGHT_TOTAL += term_sign * combinations_dp(frame, term) * pow(SHIFT_LERP_WEIGHT, term);
			term_sign *= -1;
	SHIFT_DISTANCE_TO_MAX_SPEED = 60 / SHIFT_LERP_WEIGHT_TOTAL;
	
	#fill sorted entity_id lists
	entity_ids_decreasing_premove_priority = premove_priorities.keys();
	entity_ids_decreasing_premove_priority.sort_custom(func(a, b): return premove_priorities[a] > premove_priorities[b]);
	
#	#init physics enabler size
#	set_tile_push_limit(abilities["tile_push_limit"]);
#
#	#scale shapecasts (bc inspector can't handle precise floats)
#	var shape_LR:RectangleShape2D = preload("res://Objects/ShapeCastShapeLR.tres");
#	var shape_UD:RectangleShape2D = preload("res://Objects/ShapeCastShapeUD.tres");
#	shape_LR.size.y *= GV.PLAYER_COLLIDER_SCALE;
#	shape_UD.size.x *= GV.PLAYER_COLLIDER_SCALE;
