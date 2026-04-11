extends Node

# Synced with physics process, called by player

func audio_loop():
	# sliding noise
	if owner.state == "slide":
		if !$SlideNoise.playing:
			$SlideNoise.play(randf_range(0,9.5))
			$SlideNoise.volume_linear = move_toward($SlideNoise.volume_linear, 5 * Global.sfx_volume, 1)
	else:
		$SlideNoise.stop()
		$SlideNoise.volume_linear = 0
		
	if owner.state == "hooked":
		if !$HookNoiseLoop.playing:
			$HookNoiseLoop.play()
			$HookNoiseLoop.volume_linear = move_toward($HookNoiseLoop.volume_linear, 4 * Global.sfx_volume, 4)
			$HookNoiseLoop.pitch_scale = move_toward($HookNoiseLoop.pitch_scale, 2, 0.2)
	else:
		$HookNoiseLoop.stop()
		$HookNoiseLoop.volume_linear = 0
		$HookNoiseLoop.pitch_scale = 0.8
		
	# $WindNoise.volume_linear = clampf(move_toward($WindNoise.volume_linear, (owner.velocity.length() - 12) / 16, 0.2), 0, 3 * Global.sfx_volume)
