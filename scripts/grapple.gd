extends CharacterBody3D

var is_hooked : bool = false

# lil baby script
func _physics_process(_delta):
	if move_and_slide() and visible:
		look_at(global_position - get_last_slide_collision().get_normal(), Vector3(0,0.9999, 0.005)) # cant ignore that fuckass warning
		# reparent(get_last_slide_collision().get_collider()) # for moving objects
		is_hooked = true
		velocity = Vector3(0,0,0)
	if is_hooked and (len($RemoveCheck.get_overlapping_areas()) != 0 or len($RemoveCheck.get_overlapping_bodies()) != 0):
		die()
		
func die():
	visible = false
	is_hooked = false
	
