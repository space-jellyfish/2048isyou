class_name TileForTilemapSpriteDwingAnimator
extends TileForTilemapSpriteAnimator;


func _init(sprite:TileForTilemapSprite, governor_tile:TileForTilemap):
	self.sprite = sprite;
	
#should sync to slide progress in case tile bounces
func step(delta:float):
	pass;
