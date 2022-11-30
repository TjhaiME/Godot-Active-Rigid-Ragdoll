extends "res://addons/rigidRagdoll/Scripts/Object_pickable_modified_rigidJoint.gd"

#this was made when I didnt know how to add scripts through script, I assume
#also to have it all preloaded

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():

	pass # Replace with function body.

func ready_update():
	reset_transform_on_pickup = false
	original_mode = RigidBody.MODE_RIGID#RigidBody.MODE_CHARACTER
	mode = original_mode
	get_first_mesh_as_highlight_mesh()

func get_first_mesh_as_highlight_mesh():
	if highlight_mesh_instance == null:
		for childIndex in get_child_count():
			var child = get_child(childIndex)
			if child.get_class() == "MeshInstance":
				highlight_mesh_instance = child.name
				highlight_mesh_instance_node = child
				for i in range(0, highlight_mesh_instance_node.get_surface_material_count()):
					original_materials.push_back(highlight_mesh_instance_node.get_surface_material(i))

func special_fix_transform_on_pickup():
	var hand
	if by_controller == null:
		if picked_up_by == null:
			return
		else:
			hand = picked_up_by
	else:
		hand = by_controller
	var newPos = hand.global_transform.origin
	global_transform.origin = newPos
	for childIndex in get_child_count():
		var child = get_child(childIndex)
		child.global_transform.origin = newPos
	print("trying to fix the pesky transforms of the rigidbody we created")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
