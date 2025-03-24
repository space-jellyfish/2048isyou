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
var tracking_cam_resolution:Vector2 = Vector2(800, 600);
const BORDER_DISTANCE_T:int = 120; #128; #2000000000;
const BORDER_MIN_POS_T:Vector2i = -Vector2i(BORDER_DISTANCE_T, BORDER_DISTANCE_T);
const BORDER_MAX_POS_T:Vector2i = Vector2i(BORDER_DISTANCE_T, BORDER_DISTANCE_T);
const WORLD_MIN_POS_T:Vector2i = BORDER_MIN_POS_T + Vector2i.ONE; #leave gap for border cell
const WORLD_MAX_POS_T:Vector2i = BORDER_MAX_POS_T - Vector2i.ONE;

#level-related stuff
const LEVEL_COUNT:int = 4;
var current_level_index:int = 0;
var current_level_from_save:bool = false;
var level_scores = [];
var changing_level:bool = false;
var reverting:bool = false; #if true, fade faster and don't show lv name
#var through_goal:bool = false; #changing level via goal

#procgen-related stuff
enum TilePow {
	VAL_ZERO = -1,
	VAL_ONE = 0,
	MAX = 14,
	MAX_PROCGEN = 11,
};
const TILE_VALUE_COUNT:int = 2 * TilePow.MAX + 3;
const TILE_LOAD_BUFFER:int = 12;
const TILE_UNLOAD_BUFFER:int = 12;
# no. tiles between active rect and loaded rect
# inactive buffer is necessary to prevent inactive entities from overlapping with unspawned cells
const ENTITY_INACTIVE_BUFFER:int = 4;

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

const TRACKING_CAM_LEAD_RATIO:float = 1.24; #target = pos + ratio * (track_pos - pos)
const TRACKING_CAM_SLACK_RATIO:float = 0.15; #0.25; #ratio applied to slack (tracking movement along the non-trigger axis)
const TRACKING_CAM_TRANSITION_TIME:float = 1.28;
const PLAYER_SPAWN_INVINCIBILITY_TIME:float = 0.25;

const SNAP_TOLERANCE:float = 2.3; # in px
const COLLISION_TEST_DISTANCE:float = 0.4;
const PLAYER_MU:float = 0.16; #coefficient of friction
const PLAYER_SLIDE_SPEED:float = 33;
const PLAYER_SLIDE_SPEED_MIN:float = 8;
#const PLAYER_SPEED_RATIO:float = 0.9; #must be less than 1 so tile solidifies before premove
const TILE_SLIDE_SPEED:float = 256; #288; #320

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
const DUANG_SPEED:float = 0.09; #0.1;
const DUANG_FADE_SPEED:float = DUANG_SPEED / (DUANG_END_ANGLE - DUANG_START_ANGLE);

const DWING_START_ANGLE:float = 1;
const DWING_FACTOR:float = sin(DWING_START_ANGLE);
const DWING_END_ANGLE:float = PI - DWING_START_ANGLE;
const DWING_SPEED:float = 0.09; #0.1;
const DWING_FADE_SPEED:float = DWING_SPEED / (DWING_END_ANGLE - DWING_START_ANGLE);

const SHIFT_TIME:float = 9; #in frames
const SHIFT_LERP_WEIGHT:float = 0.59;
const SHIFT_SPEED_MIN:float = TILE_SLIDE_SPEED;
const SHIFT_BOUNCE_DECELERATION:float = 0.85;
var SHIFT_LERP_WEIGHT_TOTAL:float = 0; # NOTE capitalized since these are technically constants, they just require some calculation
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
	NONE, #when in path returned by path_controller, indicates tile should wait
	SLIDE,
	SPLIT,
	SHIFT,
}

enum TransitId {
	NONE,
	ROAM,
	SLIDE, # uniform speed
	SPLIT,
	SHIFT, # accelerates to cover shift dist in same time as a slide
	MERGE,
}

# z_index
enum ZId {
	BACKGROUND = -10,
	HIDDEN_LABEL = -9,
	SAVE_OR_GOAL = -1,
	DEFAULT = 0, # walls, stationary tiles, non-converting moving tiles
	SPLITTING_NEW = 1,
	SPLITTING_OLD = 2,
	COMBINING_NEW_MOVING = 3,
	COMBINING_OLD_MOVING = 4,
	COMBINING_NEW = 5,
	COMBINING_OLD = 6,
	LEVEL_NAME = 10,
}

# layer, (mask)
enum CollisionId {
	DEFAULT = 1, # walls, non-converting tiles, squid (tiles, squid)
	MEMBRANE, # membrane, (non-player tiles, squid)
	SAVE_OR_GOAL, # savepoint/goal, (hostile tiles, squid)
	TRACKING_CAM, # player, tracking_cam ()
}

enum TrackingCamTriggerMode {
	LEAVE_AREA,
	FINISH_ACTION,
}
var tracking_cam_trigger_mode:int = TrackingCamTriggerMode.LEAVE_AREA;

# NOTE order matters! equal to 1.5x - .5y + 1.5
enum DirectionId {
	LEFT,
	DOWN,
	UP,
	RIGHT,
}

const DIRECTIONS:Dictionary = {
	DirectionId.LEFT : Vector2i(-1, 0),
	DirectionId.DOWN : Vector2i(0, 1),
	DirectionId.UP : Vector2i(0, -1),
	DirectionId.RIGHT : Vector2i(1, 0),
};

var abilities:Dictionary = {
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

# should match tile_sheet
enum TileId { #5 bits
	EMPTY = 0,
	ZERO = 16,
};

# should match tile_sheet
enum TypeId { #3 bits
	NONE = 0,
	PLAYER,
	DUPLICATOR,
	HOSTILE,
	VOID,
	REGULAR,
	SQUID,
}

# should match back_sheet
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

# NOTE TypeId should be usable as EntityId without conversion
enum EntityId {
	NONE = 0,
	PLAYER, #for simplicity, player priorities/push_weight/tpl are the same when roaming
	DUPLICATOR,
	HOSTILE,
	VOID,
	REGULAR,
	SQUID_BODY,
	SQUID_CLUB,
	STP_SPAWNING,
	STP_SPAWNED,
	SNAKE,
}

# for open world
enum StructureId {
	THIN_MOAT,
	THICK_MOAT,
}

const B_WALL_OR_BORDER:Array = [BackId.BORDER_ROUND, BackId.BORDER_SQUARE, BackId.BLACK_WALL, BackId.BLUE_WALL, BackId.RED_WALL];
const B_SAVE_OR_GOAL:Array = [BackId.SAVEPOINT, BackId.GOAL];
const B_EMPTY:Array = [BackId.EMPTY, BackId.BOARD_FRAME];
const T_NONE_OR_REGULAR:Array = [TypeId.NONE, TypeId.REGULAR];
const T_KILLABLE_BY_ZEROING:Array = [TypeId.DUPLICATOR, TypeId.HOSTILE];
const E_HAS_PATHFINDING:Array = [EntityId.DUPLICATOR];
const E_ENEMY:Dictionary = { #[src_entity, dest_entity]
	EntityId.NONE : {
		EntityId.NONE : false,
		EntityId.PLAYER : false,
		EntityId.DUPLICATOR : false,
		EntityId.HOSTILE : false,
		EntityId.VOID : false,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : false,
		EntityId.SQUID_CLUB : false,
		EntityId.STP_SPAWNING : false,
		EntityId.STP_SPAWNED : false,
		EntityId.SNAKE : false,
	},
	EntityId.PLAYER : {
		EntityId.NONE : false,
		EntityId.PLAYER : true,
		EntityId.DUPLICATOR : true,
		EntityId.HOSTILE : true,
		EntityId.VOID : true,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : true,
		EntityId.SQUID_CLUB : true,
		EntityId.STP_SPAWNING : true,
		EntityId.STP_SPAWNED : true,
		EntityId.SNAKE : true,
	},
	EntityId.DUPLICATOR : {
		EntityId.NONE : false,
		EntityId.PLAYER : true,
		EntityId.DUPLICATOR : false,
		EntityId.HOSTILE : false,
		EntityId.VOID : true,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : true,
		EntityId.SQUID_CLUB : true,
		EntityId.STP_SPAWNING : true,
		EntityId.STP_SPAWNED : true,
		EntityId.SNAKE : true,
	},
	EntityId.HOSTILE : {
		EntityId.NONE : false,
		EntityId.PLAYER : true,
		EntityId.DUPLICATOR : false,
		EntityId.HOSTILE : false,
		EntityId.VOID : true,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : true,
		EntityId.SQUID_CLUB : true,
		EntityId.STP_SPAWNING : true,
		EntityId.STP_SPAWNED : true,
		EntityId.SNAKE : true,
	},
	EntityId.VOID : {
		EntityId.NONE : false,
		EntityId.PLAYER : true,
		EntityId.DUPLICATOR : true,
		EntityId.HOSTILE : true,
		EntityId.VOID : false,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : true,
		EntityId.SQUID_CLUB : true,
		EntityId.STP_SPAWNING : true,
		EntityId.STP_SPAWNED : true,
		EntityId.SNAKE : true,
	},
	EntityId.REGULAR : {
		EntityId.NONE : false,
		EntityId.PLAYER : false,
		EntityId.DUPLICATOR : false,
		EntityId.HOSTILE : false,
		EntityId.VOID : false,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : false,
		EntityId.SQUID_CLUB : false,
		EntityId.STP_SPAWNING : false,
		EntityId.STP_SPAWNED : false,
		EntityId.SNAKE : false,
	},
	EntityId.SQUID_BODY : {
		EntityId.NONE : false,
		EntityId.PLAYER : true,
		EntityId.DUPLICATOR : true,
		EntityId.HOSTILE : true,
		EntityId.VOID : true,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : false,
		EntityId.SQUID_CLUB : false,
		EntityId.STP_SPAWNING : true,
		EntityId.STP_SPAWNED : true,
		EntityId.SNAKE : true,
	},
	EntityId.SQUID_CLUB : {
		EntityId.NONE : false,
		EntityId.PLAYER : true,
		EntityId.DUPLICATOR : true,
		EntityId.HOSTILE : true,
		EntityId.VOID : true,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : false,
		EntityId.SQUID_CLUB : false,
		EntityId.STP_SPAWNING : true,
		EntityId.STP_SPAWNED : true,
		EntityId.SNAKE : true,
	},
	EntityId.STP_SPAWNING : {
		EntityId.NONE : false,
		EntityId.PLAYER : true,
		EntityId.DUPLICATOR : true,
		EntityId.HOSTILE : true,
		EntityId.VOID : true,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : true,
		EntityId.SQUID_CLUB : true,
		EntityId.STP_SPAWNING : true,
		EntityId.STP_SPAWNED : true,
		EntityId.SNAKE : true,
	},
	EntityId.STP_SPAWNED : {
		EntityId.NONE : false,
		EntityId.PLAYER : true,
		EntityId.DUPLICATOR : true,
		EntityId.HOSTILE : true,
		EntityId.VOID : true,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : true,
		EntityId.SQUID_CLUB : true,
		EntityId.STP_SPAWNING : true,
		EntityId.STP_SPAWNED : true,
		EntityId.SNAKE : true,
	},
	EntityId.SNAKE : {
		EntityId.NONE : false,
		EntityId.PLAYER : true,
		EntityId.DUPLICATOR : true,
		EntityId.HOSTILE : true,
		EntityId.VOID : true,
		EntityId.REGULAR : false,
		EntityId.SQUID_BODY : true,
		EntityId.SQUID_CLUB : true,
		EntityId.STP_SPAWNING : true,
		EntityId.STP_SPAWNED : true,
		EntityId.SNAKE : false,
	},
}

enum TileSetSourceId {
	BACK,
	TILE,
	NAV,
}

# NOTE each TileMapLayer can only store one tile per cell; to allow tiles to overlap back cells, both TILE/BACK are necessary
enum LayerId {
	BACK,
	TILE,
	# only for pathfinder precise state, enabled=false is okay
	# NOTE use new TileMapLayer instead of {BACK with alt_id=1} or {TILE with source_id = LayerId.BACK} since this is more intuitive and flexible
	# NOTE pathfinder should check both BACK and NAV layers for compatibility
	NAV,
}

# dir is obstructed if NavId & (NAV_BIT_BLOCK << DirectionId) != 0
# each NAV_DIR_BITLEN-bit block stores refcount for directional barrier
# assume refcount can go as high as NAV_REFCOUNT_MAX
const NAV_REFCOUNT_MAX:int = 4; #one tile approaching per side (this is possible since corners are rounded)
const NAV_DIR_BITLEN:int = 3; #should be long enough to store max refcount
const NAV_BIT_BLOCK:int = (1 << NAV_DIR_BITLEN) - 1;
enum NavId {
	NONE = 0,
	LEFT = (1 << (DirectionId.LEFT * NAV_DIR_BITLEN)),
	DOWN = (1 << (DirectionId.DOWN * NAV_DIR_BITLEN)),
	UP = (1 << (DirectionId.UP * NAV_DIR_BITLEN)),
	RIGHT = (1 << (DirectionId.RIGHT * NAV_DIR_BITLEN)),
	ALL = LEFT + DOWN + UP + RIGHT,
}

const NAV_TERMS:Dictionary = {
	DIRECTIONS[DirectionId.LEFT] : NavId.LEFT,
	DIRECTIONS[DirectionId.DOWN] : NavId.DOWN,
	DIRECTIONS[DirectionId.UP] : NavId.UP,
	DIRECTIONS[DirectionId.RIGHT] : NavId.RIGHT,
}

const NAV_UNITS:Dictionary = {
	DIRECTIONS[DirectionId.LEFT]  : NavId.ALL - NavId.LEFT,
	DIRECTIONS[DirectionId.DOWN]  : NavId.ALL - NavId.DOWN,
	DIRECTIONS[DirectionId.UP]    : NavId.ALL - NavId.UP,
	DIRECTIONS[DirectionId.RIGHT] : NavId.ALL - NavId.RIGHT,
}

#player tile_push_limit does not change when roaming
var tile_push_limits:Dictionary = {
	EntityId.NONE : 0,
	EntityId.PLAYER : 2,
	EntityId.DUPLICATOR : 0,
	EntityId.HOSTILE : 1,
	EntityId.VOID : 3,
	EntityId.REGULAR : 0,
	EntityId.SQUID_BODY : 0,
	EntityId.SQUID_CLUB : 6,
	EntityId.STP_SPAWNING : 0,
	EntityId.STP_SPAWNED : 2,
	EntityId.SNAKE : 4,
};

var duplicate_upon_split:Dictionary = {
	TypeId.NONE : false,
	TypeId.PLAYER : false,
	TypeId.DUPLICATOR : true,
	TypeId.HOSTILE : false,
	TypeId.VOID : false,
	TypeId.REGULAR : false,
	TypeId.SQUID : false,
}

var merge_priorities:Dictionary = {
	TypeId.NONE : -1,
	TypeId.REGULAR : 0,
	TypeId.PLAYER : 1,
	TypeId.HOSTILE : 2,
	TypeId.DUPLICATOR : 3,
	TypeId.VOID : 4,
	TypeId.SQUID : 5,
}

# push is possible if pusher push_weight >= pushed slide_weight
var slide_weights:Dictionary = {
	EntityId.NONE : 0,
	EntityId.PLAYER : 3, #INT64_MAX when roaming, but doesn't matter since only SQUID_CLUB can push player
	EntityId.DUPLICATOR : 1,
	EntityId.HOSTILE : 2,
	EntityId.VOID : 0,
	EntityId.REGULAR : 0,
	EntityId.SQUID_BODY : 0,
	EntityId.SQUID_CLUB : INT64_MAX,
	EntityId.STP_SPAWNING : INT64_MAX,
	EntityId.STP_SPAWNED : INT64_MAX,
	EntityId.SNAKE : INT64_MAX,
}

# -1 if entity cannot push anything
var push_weights:Dictionary = {
	EntityId.NONE : -1,
	EntityId.PLAYER : 2,
	EntityId.DUPLICATOR : 1,
	EntityId.HOSTILE : 1,
	EntityId.VOID : 2,
	EntityId.REGULAR : -1,
	EntityId.SQUID_BODY : -1,
	EntityId.SQUID_CLUB : 3,
	EntityId.STP_SPAWNING : -1,
	EntityId.STP_SPAWNED : 2,
	EntityId.SNAKE : 2,
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
	EntityId.NONE : -1,
	EntityId.PLAYER : 8,
	EntityId.DUPLICATOR : 3,
	EntityId.HOSTILE : 4,
	EntityId.VOID : 5,
	EntityId.REGULAR : -1,
	EntityId.SQUID_BODY : 2,
	EntityId.SQUID_CLUB : 1,
	EntityId.STP_SPAWNING : 0,
	EntityId.STP_SPAWNED : 7,
	EntityId.SNAKE : 6,
}

# for tiebreaking if 2+ entities have premoves queued (represents 'reaction time' of entity)
# enemies have higher priority so player cannot use premoving to cross enemy-protected cells
# roaming entities should use the premove system instead of initiating moves in the middle of physics frame
var premove_priorities:Dictionary = {
	EntityId.NONE : -1,
	EntityId.PLAYER : 3,
	EntityId.DUPLICATOR : 5,
	EntityId.HOSTILE : 4,
	EntityId.VOID : 6,
	EntityId.REGULAR : -1,
	EntityId.SQUID_BODY : 2,
	EntityId.SQUID_CLUB : 1,
	EntityId.STP_SPAWNING : 0,
	EntityId.STP_SPAWNED : 8,
	EntityId.SNAKE : 7,
	#snake continuity at 90deg turns (if snake is composed of tiles)?
}
var ENTITY_IDS_DECREASING_PREMOVE_PRIORITY:Array;

var max_shift_dists:Dictionary = {
	TypeId.NONE : 0,
	TypeId.PLAYER : 4,
	TypeId.DUPLICATOR : 0,
	TypeId.HOSTILE : 0,
	TypeId.VOID : 6,
	TypeId.REGULAR : 0,
	TypeId.SQUID : 8,
}

# if not null, all instances of entity should move in sync
# TODO pause these when pause menu is opened to avoid the np bug
var global_action_timers:Dictionary = {
	EntityId.NONE : null,
	EntityId.PLAYER : null,
	EntityId.DUPLICATOR : null,
	EntityId.HOSTILE : null,
	EntityId.VOID : null,
	EntityId.REGULAR : null,
	EntityId.SQUID_BODY : null,
	EntityId.SQUID_CLUB : null,
	EntityId.STP_SPAWNING : null,
	EntityId.STP_SPAWNED : null,
	EntityId.SNAKE : null,
}

# in seconds
# NOTE use 0 to let entity try premoves as fast as *physically* possible, as determined by TILE_WIDTH and TILE_SLIDE_SPEED
# NOTE extend to use Vector2i(entity_id, action_id) as key if necessary
# NOTE phase should be delayed if ThreadPool couldn't finish pathfinding on time
const UNINITIATED_PREMOVE_COOLDOWN_DISCOUNT:float = 0.5;
var action_cooldowns:Dictionary = {
	EntityId.NONE : 0,
	EntityId.PLAYER : 0,
	EntityId.DUPLICATOR : 4,#12,
	EntityId.HOSTILE : 0.8,
	EntityId.VOID : 0.5,
	EntityId.REGULAR : 0,
	EntityId.SQUID_BODY : 1,
	EntityId.SQUID_CLUB : 0,
	EntityId.STP_SPAWNING : 2.8, #should accelerate
	EntityId.STP_SPAWNED : 0,
	EntityId.SNAKE : 0, #speed should oscillate for realistic movement
}

# max positive deviation from action_cooldown, in seconds
var action_cooldown_deviations:Dictionary = {
	EntityId.NONE : 0,
	EntityId.PLAYER : 0,
	EntityId.DUPLICATOR : 0.5,#2.5,
	EntityId.HOSTILE : 0,
	EntityId.VOID : 0,
	EntityId.REGULAR : 0,
	EntityId.SQUID_BODY : 0.1,
	EntityId.SQUID_CLUB : 0,
	EntityId.STP_SPAWNING : 0,
	EntityId.STP_SPAWNED : 0,
	EntityId.SNAKE : 0,
}

var entity_base_spawn_weights:Dictionary = {
	TypeId.NONE : 0,
	TypeId.PLAYER : 0,
	TypeId.DUPLICATOR : 2000,#4,
	TypeId.HOSTILE : 50,
	TypeId.VOID : 2,
	TypeId.REGULAR : 10000,
	TypeId.SQUID : 1,
}

var structure_base_spawn_weights:Dictionary = {
	StructureId.THIN_MOAT : 1,
	StructureId.THICK_MOAT : 1,
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


func dir_to_dir_id(dir:Vector2i) -> int:
	return int(1.5 * dir.x - 0.5 * dir.y + 1.5);

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

#doesn't do ZERO->EMPTY optimization
func tile_val_to_id(power:int, ssign:int) -> int:
	return (power + 1) * ssign + TileId.ZERO;

# ssign should be 1 for TileId.ZERO (required by is_vals_mergeable())
func tile_id_to_val(tile_id:int):
	if tile_id == TileId.ZERO or tile_id == TileId.EMPTY:
		return Vector2i(-1, 1);
	var signed_incremented_pow:int = tile_id - TileId.ZERO;
	return Vector2i(absi(signed_incremented_pow) - 1, signi(signed_incremented_pow));

func is_approx_equal(a:float, b:float, tolerance:float) -> bool:
	if absf(a - b) <= tolerance:
		return true;
	return false;

func get_animator_type(animator_id:int) -> int:
	return animator_id >> 1;


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
	assert(SHIFT_DISTANCE_TO_MAX_SPEED >= TILE_SLIDE_SPEED / TILE_WIDTH);
	
	#fill sorted entity_id lists
	ENTITY_IDS_DECREASING_PREMOVE_PRIORITY = premove_priorities.keys();
	ENTITY_IDS_DECREASING_PREMOVE_PRIORITY.sort_custom(func(a, b): return premove_priorities[a] > premove_priorities[b]);
