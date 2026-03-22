extends Node

# Synced with physics process, called by player

func audio_loop():
	# sliding noise
	
	if owner.slide_state:
		if !$SlideNoise.playing:
			$SlideNoise.play(randf_range(0,9.5))
			$SlideNoise.volume_linear = lerpf($SlideNoise.volume_linear, 5 * Global.sfx_volume, 0.4)
	else:
		$SlideNoise.stop()
		$SlideNoise.volume_linear = 0
		
	if owner.grapple.is_hooked and owner.grapple.visible:
		if !$HookNoiseLoop.playing:
			$HookNoiseLoop.play()
			$HookNoiseLoop.volume_linear = lerpf($HookNoiseLoop.volume_linear, 4 * Global.sfx_volume, 0.4)
	else:
		$HookNoiseLoop.stop()
		$HookNoiseLoop.volume_linear = 0
		
	$WindNoise.volume_linear = clampf(lerpf($WindNoise.volume_linear, (owner.velocity.length() - 12) / 16, 0.5), 0, 4 * Global.sfx_volume)
	
	
