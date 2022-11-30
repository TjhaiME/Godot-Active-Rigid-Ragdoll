extends Spatial
#extends Skeleton #could do this and put the code on the skeleton, then we dont need to worry as much about instancing
#but we should be the parent of the rigidBodyNodes or we have to change rigid_body_match in deform_skeleton_with_rigidBodies()







#NOTES:
#things balance easier when their centre of mass is close to the ground
#godot rigidBodies mass is entirely distributed at the origin of the RigidBody
#so we can put the Centre of mass right at the contact point with thew ground for a capsule
#we can use this to make "Mighty Beanz" style capsules that hold things upright using mainly the physics Engine
#Most these ragdolls use this, (capsule rotated to be like a typical player capsule orientation, BUT the centre of mass/origin of rigidBody is on the contact point with the ground)
#the capsule that holds it up usually needs a much higher mass than the rest, see examples


#we balance the mass and gravity scale of various bodyParts to give it it's upright stiffness
#(use gravity scale of -1 or -0.5 to give an upwards pulling force)
#IMPORTANT make sure to keep the gravity_scale of the Hips (or whgatever the root bone) at default 1.
#otherwise the ragdoll will not fall with gravity
#general rule: have mass decrease as you go out from the root bone (hips)
#exceptions: when making a capsule stabiliser or when using negative gravity_scales.

####    Runtime random problems:

#changing physics properties:
#general rule: Changing physics properties of rigidBodies in process or another nodes integrate_focres function leads to unintended effects and errors. (e.g. gravity_scale and mass)
# exceptions: linear and angular_damp

#making joints
#Joints cannot have some of their variables changed once they are made.
#somewhere in the code I tried to move a joint or change its variables
# or something and it only worked if I made a new joint with those variables
# I think some of the variables need the ready function of the joint to be properly set up



var skeleton = null #needs to be assigned before this ready funbction is called
var rigidBodyParent = self #if not self we need to tell
var rigidBodiesFromBones = { #
#	#we put the name of our bone as the key
#	#we put the name of the corresponding rigidBody as the value (has to be child of skeleton)
#	#so if we change the model but keep the ragdoll, then we only change the keys
#	#the rest of the data will be generated from this list and the data in skeleton
#	"mixamorig_Spine2" : "mixamorig_Spine2",
#	"mixamorig_Hips" : "mixamorig_Hips",
#	"mixamorig_Head" : "mixamorig_Head",
#	"mixamorig_LeftArm" : "mixamorig_LeftArm",
#	"mixamorig_LeftForeArm" : "mixamorig_LeftForeArm",
#	"mixamorig_RightArm" : "mixamorig_RightArm",
#	"mixamorig_RightForeArm" : "mixamorig_RightForeArm",
}


#var actual_bones_used = rigidBodiesFromBones.keys()
var rigidBodiesInitialTForms = {}
var rigidBodiesInverseTForms = {}
var boneInitialTForms = {}
var boneNameToIndex = {}


#############################
#   Most important part
#############################
#This is the function that handles deforming the skeleton which defprms the mesh to align with the reigidBody ragdoll jointed structure
func deform_skeleton_with_rigidBodies():
	#this should do it for a general ragdoll, as long as we give it the bones to use
	#this is probably slower than the other one but it could work with other models.
	for boneName in rigidBodiesFromBones.keys():
		var boneIndex = boneNameToIndex[boneName]#skeleton_bones_sync[boneName]
		var rB_name = rigidBodiesFromBones[boneName]
		var rigid_body_match = rigidBodyParent.get_node(rB_name) #rigidBodyParent.get_node(rB_name)
		if rigid_body_match == null:
			continue
		var rB_tForm_final = rigid_body_match.transform
		var relative_tForm = rB_tForm_final*rigidBodiesInverseTForms[rB_name]
		var final_bone_tForm = relative_tForm*boneInitialTForms[boneName]
		
		
		skeleton.set_bone_global_pose_override(boneIndex, final_bone_tForm, 1, true)
	#fix_clothing_positions()


func get_initial_tforms():
	for boneName in rigidBodiesFromBones.keys():
		boneNameToIndex[boneName] = skeleton.find_bone(boneName)
		var rigidBodyName = rigidBodiesFromBones[boneName]
		var tForm = rigidBodyParent.get_node(rigidBodyName).transform
		rigidBodiesInitialTForms[rigidBodyName] = tForm
		rigidBodiesInverseTForms[rigidBodyName] = tForm.affine_inverse() ##this tForm should have no scaling if we want normal inverse()
		var boneIndex = boneNameToIndex[boneName]#skeleton_bones_sync[boneName]
		boneInitialTForms[boneName] = skeleton.get_bone_global_pose(boneIndex) #returns transform relative to skeleton



# Called when the node enters the scene tree for the first time.
#func _ready():
#	get_initial_tforms()
#	pass # Replace with function body.


func _set_up():
	get_initial_tforms()

	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta):
	deform_skeleton_with_rigidBodies()
	pass





######################### USEFUL FUNCTIONS #############################

func spawn_a_joint(bodyPart, externalNode, jointConditions):
	print("spawning a joint as a child of bodyPart: ", bodyPart)
	var jointPos = bodyPart.global_transform.origin
	var joint = Generic6DOFJoint.new()
	var parent = bodyPart# self#skelRagdoll
	var bodyPath = str("../", parent.get_path_to(bodyPart))
	var externalPath = str("../", parent.get_path_to(externalNode))
	
	joint.set("nodes/node_a", bodyPath)
	#var spawnedSegmentMainRigidBody = segment.get_child(0).name #should probs do this in a better way
	#var pathToNode = bodyPart.get_path_to(externalNode)
	#print("in joint creation. Path to external node = ", pathToNode)
	joint.set("nodes/node_b", externalPath)
	#we are in czpsuleBase, we should probs add the joint as a child of skeletonRagdoll
	#add_child(joint) #I dont think this works because skelRagdoll doesnt move
	parent.add_child(joint)#perhaps I should make the joint a child of the handRigidBody
	#this helps the joint move around but the rotation isnt right
	joint.global_transform.origin = jointPos
	joint.name = str("grbJnt")
	
	dampen_joint(joint)
	
	for jointConditionDuo in jointConditions:
		var jointParameter = jointConditionDuo[0]
		var jointValue = jointConditionDuo[1]
		joint.set(jointParameter, jointValue)


func dampen_joint(joint):
	var dampValue = 16
	var softValue = 0.01
	var restiValue = 0.1
	for dim in ["x", "y", "z"]:
		var angLimString = str("angular_limit_",dim)
		joint.set(str("angular_limit_",dim,"/damping"), dampValue)
		joint.set(str("angular_limit_",dim,"/softness"), softValue)
		joint.set(str("angular_limit_",dim,"/restitution"), restiValue)
		joint.set(str("linear_limit_",dim,"/damping"), dampValue)
