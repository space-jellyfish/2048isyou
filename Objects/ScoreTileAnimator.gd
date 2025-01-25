class_name ScoreTileAnimator


#called by AnimationSprite every physics frame to progress the animation
func step(s:ScoreTileAnimationSprite, delta:float) -> bool:
	return false;

#reverses animation direction (start and end keyframes get swapped)
#does not change current animation parameter(s)
func reverse():
	pass;
