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
	
	tile.move_and_slide()
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
				# add premove using self.premove_priority
				tile.world.add_premove()
