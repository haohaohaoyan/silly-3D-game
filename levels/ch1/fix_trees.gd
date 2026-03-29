@tool
extends EditorScript

# Makes all of the trees randomized, rotated, and scaled randomly. 

func _run():
	var rng = RandomNumberGenerator.new()
	var multimesh = EditorInterface.get_edited_scene_root().get_node("Trees").multimesh
	for tree in multimesh.instance_count:
		# rotate upright (thanks guy on reddit)
		var transform = multimesh.get_instance_transform(tree)
		transform.basis = Basis.IDENTITY * Basis(Vector3.UP, deg_to_rad(rng.randi_range(0,360))) # set upright and random rotation
		var x_z_scale = rng.randf_range(1.5,3)
		transform.basis *= Basis(Vector3.RIGHT * x_z_scale, Vector3.UP * rng.randf_range(2, 4), Vector3.FORWARD * x_z_scale)
		multimesh.set_instance_transform(tree, transform)
		# scale up
