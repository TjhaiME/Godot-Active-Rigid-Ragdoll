extends "res://addons/rigidRagdoll/Scripts/Object_pickable_modified_rigidJoint.gd"#RigidBody


#IDEA:
#create a sword that when you stab with it it creates a slidey joint
#so you can stab in and out
var attackLength = 0.8


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_StabArea_body_entered(body):
	return #skip this for now it is too troublesome
	if has_node("stabJoint"):
		return
	print("we stabbed something")
	#we need to check if it was with enough force
	
	#create a (special?) sliding joint and attach it to this body
	pass # Replace with function body.
	var joint = SliderJoint.new()
	add_child(joint)
	joint.global_transform.origin = $StabArea.global_transform.origin
	joint.rotation_degrees = Vector3(0,-90,0) #slide along x axis, sword blade is z axis
	
	
	joint.set("nodes/node_a", str("../")) #joint.set("nodes/node_a", str("../", name))
	#var spawnedSegmentMainRigidBody = segment.get_child(0).name #should probs do this in a better way
	var pathToBody = get_path_to(body)
	joint.set("nodes/node_b", str("../", pathToBody))
	joint.name = "stabJoint"
	
	#we need a special slider joint that detaches when it goes too far in one direction
