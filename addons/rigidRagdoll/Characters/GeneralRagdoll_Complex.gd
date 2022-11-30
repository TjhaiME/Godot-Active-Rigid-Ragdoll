extends "res://addons/rigidRagdoll/Scripts/ragdollExtra.gd"




# Called when the node enters the scene tree for the first time.
func _ready():
	
	rigidBodiesFromBones = {
		#"BONE_NAME" : "RIGIDBODY_NODE_NAME",
		#we put the name of our bone as the key
		#we put the name of the corresponding rigidBody as the value (has to be child of skeleton)
		#so if we change the model but keep the ragdoll, then we only change the keys
		#the rest of the data will be generated from this list and the data in skeleton
		"mixamorig_Hips" : "Hips",
		"mixamorig_Spine1" : "Spine1",
		"mixamorig_Spine2" : "Spine2",
		"mixamorig_Head" : "Head",
		"mixamorig_LeftArm" : "LeftArm",
		"mixamorig_LeftForeArm" : "LeftForeArm",
		"mixamorig_LeftHand" : "LeftHand",
		"mixamorig_RightArm" : "RightArm",
		"mixamorig_RightForeArm" : "RightForeArm",
		"mixamorig_RightHand" : "RightHand",
		"mixamorig_LeftUpLeg" : "LeftUpLeg",
		"mixamorig_RightUpLeg" : "RightUpLeg",
		"mixamorig_LeftLeg" : "LeftLeg",
		"mixamorig_RightLeg" : "RightLeg",
	}
	
	
	
	
	
	skeleton = $SkeletonRagdoll
	rigidBodyParent = skeleton
	#_set_up()
	
	my_skel = skeleton
	my_headNode = $SkeletonRagdoll/Head
	basePosNode = $SkeletonRagdoll/capsuleBase #could be a singular ffoot or hips
	
	parent_is_ready()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	floorPos = basePosNode.global_transform.origin
	extra_animations(delta)
	#deform_skeleton_with_rigidBodies() #done in base Script
	pass
