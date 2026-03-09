extends Node

# Synced with physics process, called by player

func audio_loop():
	# sliding noise
	
	if owner.slide_state and !$SlideNoise.playing:
		$SlideNoise.play(randf_range(0,9.5))
		$SlideNoise.volume_linear = lerpf($SlideNoise.volume_linear, 1.5, 0.4)
	elif !owner.slide_state:
		$SlideNoise.stop()
		$SlideNoise.volume_linear = 0
		
	$WindNoise.volume_linear = clampf(lerpf($WindNoise.volume_linear, (owner.velocity.length() - 12) / 16, 0.5), 0, 5)
	
	
