extends "res://addons/rigidRagdoll/Scripts/Object_pickable_modified.gd"
#extends RigidBody

signal finished_selection#(Array)

onready var paintBlobNode = get_tree().get_current_scene()#.get_node("paintBlobNode") #get_tree().get_current_scene()
onready var paintedRigidBodyScene = preload("res://addons/rigidRagdoll/Items/paintedRigidBodyBASE.tscn") #I think I did this to be able to pick it up


var paintingNow = false
var sculpture_transforms = []
var lastExtremityTransforms = [Transform.IDENTITY, Transform.IDENTITY]#[sculpture_transforms[0], sculpture_transforms[sculpture_transforms.size()-1]]
var temp_blobs = []

var add_collision_bool = true #if true the paintings get collision meshes and become rigid bodies that can be picked up, false is just meshes for painting

# Called when the node enters the scene tree for the first time.
func _ready():
	#update_brush_radius(segment_radius) #default
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if paintingNow == true:
		paint_process(delta)
	pass






func action():
	paintingNow = true
#in function Pickup, so to make a custom action we just need a func called action
#	elif p_button == action_button_id:
#		if picked_up_object and picked_up_object.has_method("action"):
#			picked_up_object.action()

#in function pickup we also have
#emit_signal("has_picked_up", picked_up_object), this doesnt work here





var remaining_ink = 1
var frameCounter = 0
var segment_length = 3 #amount of frames before a new segment
var segment_radius = 0.2

func paint_process(delta):
	if frameCounter == 0:
		sculpture_transforms.append($Brush.global_transform)
		spawn_temp_paint_blob($Brush.global_transform)
		remaining_ink -= delta
		frameCounter = (frameCounter + 1)%segment_length
	else:
		finish_painting()

func update_brush_radius(newRadius):
	print("updating brush radius to ", newRadius)
	segment_radius = newRadius
	$Brush.mesh.size.x = newRadius



func spawn_temp_paint_blob(tForm):
	var blob = MeshInstance.new()
	paintBlobNode.add_child(blob)
	blob.global_transform = tForm
	blob.mesh = CubeMesh.new()
	blob.mesh.size = Vector3(segment_radius,0.06,0.04)#Vector3(segment_radius,segment_radius,0.04)
	var newMaterial = $MaterialChooser/MeshInstance.get("material/0")
	blob.set("material/0",newMaterial)
	temp_blobs.append(blob.name)


func delete_temp_blocks():
	for index in temp_blobs.size():
		var blobName = temp_blobs[index]
		var current_blob = paintBlobNode.get_node(blobName)
		current_blob.queue_free()
	temp_blobs.clear()

func finish_painting():
	var chosenTransform = sculpture_transforms[0]
	emit_signal("finished_selection", chosenTransform)
	#create_proper_sculpture()
	#var meshInst = make_array_mesh(add_collision_bool)#add_collision_bool, if true it spawns rigid bodies, if false it spawns just floating meshes that dont collide
	#turn_mesh_into_rigidBody(meshInst)
	#delete_temp_blocks()
	paintingNow = false
	sculpture_transforms.clear()
	pass




