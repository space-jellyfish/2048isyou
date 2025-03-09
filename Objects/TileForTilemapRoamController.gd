# movement controller for slide mode
class_name TileForTilemapRoamController
extends TileForTilemapController;


func step(delta:float):
	#friction
	tile.velocity *= 1 - GV.PLAYER_MU;

	#input
	var hdir = int(Input.get_axis("left", "right"));
	var vdir = int(Input.get_axis("up", "down"));
	var dir:Vector2i = Vector2i(hdir, vdir);
	
	#accelerate
	tile.velocity += dir * GV.PLAYER_SLIDE_SPEED;

	#clamping
	if tile.velocity.length() < GV.PLAYER_SLIDE_SPEED_MIN:
		tile.velocity = Vector2.ZERO;
	
	#move
	tile.move_and_slide()
	
	#emit moved signal
	if tile.get_last_motion().length():
		tile.moved_for_tracking_cam.emit();
	
	for index in tile.get_slide_collision_count():
		var collision:KinematicCollision2D = tile.get_slide_collision(index);
		var collider:Node2D = collision.get_collider();
		
		if collider is TileMap:
			#find slide direction
			var slide_dir:Vector2 = collision.get_normal() * (-1);
			if absf(slide_dir.x) >= absf(slide_dir.y):
				slide_dir.y = 0;
			else:
				slide_dir.x = 0;
			slide_dir = slide_dir.normalized();
			
			#slide if slide_dir and player_dir agree
			# this means player can guide itself to alignment if it cuts a tile really thin on the corner
			if (slide_dir.x && slide_dir.x == dir.x) or (slide_dir.y && slide_dir.y == dir.y):
				pass;
				# add premove using self.premove_priority
				#var tile_entity:Entity = tile.world.get_entity(tile.old_type_id, tile);
				#var pushed_tile_entity:Entity = tile.world.get_aligned_tile_entity()
				#var premove:Premove = Premove.new(tile_entity, )
				#tile_entity.add_premove();
