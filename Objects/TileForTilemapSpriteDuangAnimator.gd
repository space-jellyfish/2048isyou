class_name TileForTilemapSpriteDuangAnimator
extends TileForTilemapSpriteAnimator;


func _init(sprite:Sprite2D):
	self.sprite = sprite;

#should sync to slide progress in case tile bounces
func step(delta:float):
	pass;
