extends CharacterBody3D

# lil baby script
func _physics_process(_delta):
	if move_and_slide():
		look_at(global_position - get_last_slide_collision().get_normal(), Vector3(0,0.9999, 0.005)) # cant ignore that fuckass warning
		reparent(get_last_slide_collision().get_collider())
		set_physics_process(false)
		velocity = Vector3(0,0,0)
		
func _on_die(_body: Node3D) -> void:
	print("ufdcfijsdjcsdijoc")
	# only kills if it's latched onto something
	if not is_physics_processing():
		visible = false
		print("as;dlkfja")
		
	
