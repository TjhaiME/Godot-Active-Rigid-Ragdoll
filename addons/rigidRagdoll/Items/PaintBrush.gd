extends "res://addons/rigidRagdoll/Scripts/Object_pickable_modified.gd"
#extends RigidBody

signal finished_sculpture#(Array)

onready var paintBlobNode = get_tree().get_current_scene()#.get_node("paintBlobNode") #get_tree().get_current_scene()
onready var paintedRigidBodyScene = preload("res://addons/rigidRagdoll/Items/paintedRigidBodyBASE.tscn") #I think I did this to be able to pick it up


var paintingNow = false
var sculpture_transforms = []
var lastExtremityTransforms = [Transform.IDENTITY, Transform.IDENTITY]#[sculpture_transforms[0], sculpture_transforms[sculpture_transforms.size()-1]]
var temp_blobs = []

var add_collision_bool = true #if true the paintings get collision meshes and become rigid bodies that can be picked up, false is just meshes for painting
#TODO Change add_collision_bool to a numeric value so I can have more options, like making static bodies instead
#there are only 3 spots it shows up and its really important
#it would be easiest to add a secondary variable that then 
#could determine the collision bool beforehand then half these checks would be the same

#like instead of function(add_col_bool) we have func(intVal)
#thewn at begininng of func we set coll bool val based on if that type should have it


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
		
	if remaining_ink <= 0:
		finish_painting()
	
	
	remaining_ink -= delta
	frameCounter = (frameCounter + 1)%segment_length
	

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
	if frameCounter != 0:
		sculpture_transforms.append($Brush.global_transform)
	#should we clean the sculpture transforms array first, default amount for 1 second with 3 frame skip is 20 (non vr), if we have the following code on we can reduce the sculpture_transforms down to 10, normally less
	var new_transforms = []
	new_transforms.append(sculpture_transforms[0])
	for ind in sculpture_transforms.size()-1:
		var index = ind+1 #so we skip 0
		var indexOfLastSavedTransform = new_transforms.size()-1
		var lastTForm = new_transforms[indexOfLastSavedTransform]
		var lastPos = lastTForm.origin
		var newTForm = sculpture_transforms[index]
		var newPos = newTForm.origin
		#if they are too close then skip it
		if lastPos.distance_to(newPos) >= 2*segment_radius:
			new_transforms.append(newTForm)
	
	#before we reset sculptureTransforms, record the first and last value
	
	sculpture_transforms = new_transforms.duplicate(true)
	print("sculpture_transforms.size() = ", sculpture_transforms.size())
	lastExtremityTransforms = [sculpture_transforms[0], sculpture_transforms[sculpture_transforms.size()-1]]
	emit_signal("finished_sculpture", lastExtremityTransforms)
	#create_proper_sculpture()
	var meshInst = make_array_mesh(add_collision_bool)#add_collision_bool, if true it spawns rigid bodies, if false it spawns just floating meshes that dont collide
	#turn_mesh_into_rigidBody(meshInst)
	delete_temp_blocks()
	remaining_ink = 1
	paintingNow = false
	sculpture_transforms.clear()
	pass





func make_array_mesh(add_collision_bool):
	var amount_of_segments = sculpture_transforms.size()-1
	if amount_of_segments <= 0:
		return
	#we need to find a spot to define the meshinstance vertices relative to
	var averageMidPoint = Vector3(0,0,0)
	for prismIndex in amount_of_segments:
		var segment_mid_point = 0.5*sculpture_transforms[prismIndex].origin + 0.5*sculpture_transforms[prismIndex+1].origin
		averageMidPoint += segment_mid_point
	averageMidPoint /= amount_of_segments
	print("average mid point is = ", averageMidPoint)
	#var arrayMesh = ArrayMesh.new()
	var newRigidBody
	var rigid_owner_ID #turn off if we want multiple owners
	var mi := MeshInstance.new()
	if add_collision_bool == true:
		pass
		#newRigidBody = RigidBody.new() 
		newRigidBody = paintedRigidBodyScene.instance() #a pick up able object
		#newRigidBody.mode = RigidBody.MODE_STATIC
		
		#paintBlobNode.add_child(mi)
		newRigidBody.add_child(mi)
		paintBlobNode.add_child(newRigidBody) #should this be done later?
		newRigidBody.global_transform.origin = averageMidPoint
		mi.global_transform.origin = averageMidPoint
		
		#call_deferred(paintBlobNode.add_child(newRigidBody))
		#paintBlobNode.call_deferred("add_child", newRigidBody)
		rigid_owner_ID = newRigidBody.create_shape_owner(newRigidBody) #create new owners ONCE shape
	else:
		paintBlobNode.add_child(mi)
		mi.global_transform.origin = averageMidPoint
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices = [] #the final vertices array that we turn into poolVec array to pass into arrayMesh
	var centreOfMass = []
	#arrays[Mesh.ARRAY_VERTEX] = []
	#need to actually define the points here
	#make cylinder
	var angle_divisions = []
	var angle_division_amount = 4
	for index in angle_division_amount:
		#angle_divisions.append((angle_division_amount - index-1)*2.0*PI/float(angle_division_amount))
		angle_divisions.append((index)*2.0*PI/float(angle_division_amount))
	var startPrism = false
	var endPrism = false #do we draw the face on the end
	var middlePositionVec = 0.5*sculpture_transforms[0].origin + 0.5*sculpture_transforms[amount_of_segments].origin
	
	
	for prismIndex in amount_of_segments:
		if prismIndex == 0:
			startPrism = true
		if prismIndex == amount_of_segments - 1:
			endPrism = true
		var startVec = sculpture_transforms[prismIndex] #actually a transform
		var endVec = sculpture_transforms[prismIndex+1]
		var dirVec = endVec.origin - startVec.origin
		var midVec = 0.5*startVec.origin + 0.5*endVec.origin
		var dirVecLength = dirVec.length()
		#0.5*dirVecLength#0.4
		var normalDirVec = dirVec/float(dirVecLength)
		#number_of_vertices = 8
	#	for vertIndex in number_of_vertices:
	#		var vertPos = 
		
		
		var vert_positions = []
		#var newVert_indices = [] #should be 8 vertices , top left start = 0th entry clockwise around to 3rd entry, then repeat but for end vertices
		#var newVertIndexMod = 0
		#var new_indices_for_triangles = []#must be mulitple of 3
		for sideIndex in 2: #start and end
			var current_side_vert = startVec.origin
			var current_basis = startVec.basis
			var indexMod = 0
			if sideIndex == 0:
				current_side_vert = startVec.origin
				current_basis = startVec.basis
			else:
				current_side_vert = endVec.origin
				current_basis = endVec.basis
				#indexMod = angle_divisions.size() - 1
			#get plane that we draw the cube on
			var basisVec1 = current_basis.x #this allows us to tilt the brush to go between 2D and 3D.
			var basisVec2 = current_basis.y
			
			for index in angle_divisions.size():
				#var newIndex = (index + indexMod)%angle_divisions.size()
				var angle = angle_divisions[index]
				var vertPos =  current_side_vert + segment_radius*cos(angle)*basisVec1 + segment_radius*sin(angle)*basisVec2
				vert_positions.append(vertPos)
				#newVert_indices.append(newVertIndexMod)
				
				#newVertIndexMod += 1
			#now we have the vertices we need to define the indices for the triangles
		var result = add_rectangular_prism_segment(averageMidPoint, vert_positions, startPrism, endPrism) #result = [vertices, collisionVertices]
		var new_vertices = result[0]
		var collisionVertices = result[1] #vertices for a convex collision shape
		centreOfMass.append(result[2])
		###############################################################
		# Generate convexPolygon for each hexahedron in the mesh
		###############################################################
		if add_collision_bool == true:
			var colShape = ConvexPolygonShape.new()
			colShape.set_points(collisionVertices)
			#var rigid_owner_ID = newRigidBody.create_shape_owner(newRigidBody) #create new owners for each shape
			newRigidBody.shape_owner_add_shape(rigid_owner_ID, colShape)
			print("Added a new shape for rigidBody")
		#newMeshInst.global_transform.origin = midVec
		###############################################################
		vertices.append_array(new_vertices)
		
	
	var actual_centre_of_mass = Vector3(0,0,0)
	for CentreOMass in centreOfMass:
		actual_centre_of_mass = actual_centre_of_mass + CentreOMass
	actual_centre_of_mass = actual_centre_of_mass/float(centreOfMass.size())
	
	
	
	#we should only do the below part once
	###############################
	#from woopdeedoo
	var colors := []
	for i in range(vertices.size()):
		colors.append(Color.red)
	var mesh := ArrayMesh.new()
	#var arrays := []
	#arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PoolVector3Array(vertices)
	arrays[Mesh.ARRAY_COLOR] = PoolColorArray(colors)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# mesh.surface_set_material(0, your_material)   # will need uvs if using a texture
	
	#your_material.vertex_color_use_as_albedo = true # will need this for the array of colors
	
	#var mi := MeshInstance.new()
	mi.mesh = mesh
	var newMaterial = $MaterialChooser/MeshInstance.get("material/0")
	mi.set("material/0", newMaterial) #trying to take materials from the outside world
	if add_collision_bool == false:
#		paintBlobNode.add_child(mi)
#		mi.global_transform.origin = averageMidPoint
		return mi #exit the function here if we just want a mesh
	
	#add_child(mi) # don't forget to add it as child of something (I always forget, lol)
	# if the texture is a tileset like minecraft's, then maybe you can use this 
	# instead of setting the material for each surface
	# mi.material_override = your_material      # will need uvs if using a texture
	
	#mi.transform = Transform.IDENTITY #test does this fix picking up rigid bodies
	#newRigidBody.add_child(mi)
	var name_of_mesh_scene = mi.name
	newRigidBody.center_pickup_on = name_of_mesh_scene
	newRigidBody.center_pickup_on_node = mi
	newRigidBody.collision_layer = 1
	newRigidBody.collision_mask = 3 #1 and 2
	#newRigidBody.add_collision_exception_with(newRigidBody)
	for childIndex in newRigidBody.get_child_count():
		print("child of rigid body is = ", newRigidBody.get_child(childIndex), " class = ", newRigidBody.get_child(childIndex).get_class())
	#PRINT RIGIDbODY SHAPES:
	var owners = []
	owners = newRigidBody.get_shape_owners()
	print("owners = newRigidBody.get_shape_owners() : ", newRigidBody.get_shape_owners())
	for owner_ID in owners:
		var amount_of_shapes = newRigidBody.shape_owner_get_shape_count(owner_ID)
		for shape_ID in amount_of_shapes:
			print("found a new shape in newRigidBody for owner ", owner_ID, " with shape_ID = ", shape_ID)
	
	#seems that collisionShape scenes do not actually exist at runtime and I need to acsess it all through CollisionObject
	#https://docs.godotengine.org/en/3.4/classes/class_collisionobject.html
	#look up how to transfer collision Shapes from one object to another
	#https://godotengine.org/qa/4966/collision-detection-working-when-objects-created-from-script
	
	##################################################



	#call_deferred(paintBlobNode.add_child(newRigidBody)) #shold this be done earlier?
	#paintBlobNode.call_deferred("add_child", newRigidBody)
	#yield(get_tree().create_timer(0.1), "timeout")
	#mi.global_transform.origin = actual_centre_of_mass #testing setting both to close to mesh, ruins position of mesh when its generated, shape is in the right spot still
	#mi.global_transform.origin = averageMidPoint
	#newRigidBody.global_transform.origin = mi.global_transform.origin
	
	newRigidBody.mode = RigidBody.MODE_RIGID#MODE_CHARACTER #on normal rigid mode they just fly toward the origin for some reason
	#the mode change isnt needed for the scene
	newRigidBody.ready_update()
	#newRigidBody.get_first_mesh_as_highlight_mesh()
	#paintBlobNode.add_child(mi) 
	return mi
	#mi.global_transform.origin = spawnPos







# I like to use this convention, but you can use whatever you like
#               010           110                         Y
#   Vertices     A0 ---------- B1            Faces      Top    -Z
#           011 /  |      111 /  |                        |   North
#             E4 ---------- F5   |                        | /
#             |    |        |    |          -X West ----- 0 ----- East X
#             |   D3 -------|-- C2                      / |
#             |  /  000     |  / 100               South  |
#             H7 ---------- G6                      Z    Bottom
#              001           101                          -Y

#startPrism needs to do northface
#endPrism needs to do southFace

func add_rectangular_prism_segment(originVertex, vertexArray, startPrism, endPrism):#, spawnPos):
	var a = Vector3(0, 1, 0) # if you want the cube centered on grid points
	var b := Vector3(1, 1, 0) # you can subtract a Vector3(0.5, 0.5, 0.5)
	var c := Vector3(1, 0, 0) # from each of these
	var d := Vector3(0, 0, 0)
	var e := Vector3(0, 1, 1)
	var f := Vector3(1, 1, 1)
	var g := Vector3(1, 0, 1)
	var h := Vector3(0, 0, 1)
	var letterList = ["a","b","c","d","e","f","g","h"]
	if vertexArray.size() == letterList.size():
		#print("changing vertex positions")
#		for index in letterList.size():
#			var letter = letterList[index]
#			set(letter, vertexArray[index])
		a = vertexArray[0]
		b = vertexArray[1]
		c = vertexArray[2]
		d = vertexArray[3]
		e = vertexArray[4]
		f = vertexArray[5]
		g = vertexArray[6]
		h = vertexArray[7]
		
#		a = vertexArray[4]
#		b = vertexArray[5]
#		c = vertexArray[6]
#		d = vertexArray[7]
#		e = vertexArray[0]
#		f = vertexArray[1]
#		g = vertexArray[2]
#		h = vertexArray[3]
		
	else:
		print("NOT changing vertex positions")
	########################################
	#those are in global co-ordinate space, we need to convert then to local space
	a -= originVertex
	b -= originVertex
	c -= originVertex
	d -= originVertex
	e -= originVertex
	f -= originVertex
	g -= originVertex
	h -= originVertex
	#######################################
	for index in letterList.size():
		var letter = letterList[index]
		var value = get(letter)
		#print("letter ", letter, " = ", value)
	#print("letterVariables = ", a," , ",b," , ",c," , ",d," , ",e," , ",f," , ",g," , ",h)
#	var vertices := [   # faces (triangles)
#		b,a,d,  b,d,c,  # N
#		e,f,g,  e,g,h,  # S
#		a,e,h,  a,h,d,  # W
#		f,b,c,  f,c,g,  # E
#		a,b,f,  a,f,e,  # T
#		h,g,c,  h,c,d,  # B
#	]
	var dir = (e-a).normalized() #vector from a to e
	var vertices = []
	if startPrism == true:
		vertices.append_array([b,a,d,  b,d,c])
	if endPrism == true:
		vertices.append_array([e,f,g,  e,g,h])
	var vertices_for_side_faces := [   # faces (triangles)
#		b,a,d,  b,d,c,  # N
#		e,f,g,  e,g,h,  # S
		a,e,h,  a,h,d,  # W
		f,b,c,  f,c,g,  # E
		a,b,f,  a,f,e,  # T
		h,g,c,  h,c,d,  # B
	]
	vertices.append_array(vertices_for_side_faces)
	
	var collisionVertices = []#[a,b,c,d,h,g,f,e]
	#but we may need to adjust them so they dont overlap at all
	var startFace = [a,b,c,d]
	var endFace = [h,g,f,e]
	var collisionMargin = 0.04
	for vec in startFace:
		var newVec = vec + collisionMargin*dir
		collisionVertices.append(newVec)
	for vec in endFace:
		var newVec = vec - collisionMargin*dir
		collisionVertices.append(newVec)
	
	#now get centre of mass
	var vertexList = [a,b,c,d,h,g,f,e]
	var sum = Vector3(0,0,0)
	for vertex in vertexList:
		sum = sum + vertex
	sum = sum/float(vertexList.size())
	
	
	#return vertices
	var result = [vertices, collisionVertices, sum]
	return result
	#var verticesForMesh = vertices
	#return [verticesForMesh, verticesForCollision]


#func turn_mesh_into_rigidBody(meshInst):
#	meshInst.create_multiple_convex_collisions()







func _on_MaterialChooser_body_entered(body):
	#if I am currently picked up
	if picked_up_by == null:
		return
	
	var material = get_first_mesh_instance_material(body)
	#then check the body and if it has a material
	if material == null:
		return
	#change colour chooser to new material
	$MaterialChooser/MeshInstance.set("material/0", material)
	pass # Replace with function body.

func get_first_mesh_instance_material(body):
	for childIndex in body.get_child_count():
		var child = body.get_child(childIndex)
		if child.get_class() == "MeshInstance":
			if child.mesh == null:
				continue
			
			var material 
			if child.get("material/0") != null:
				material = child.get("material/0")
			elif child.mesh.get("surface_1/material") != null:
				material = child.mesh.get("surface_1/material")
			else:
				continue
			
			return material
	return null #if we fail
























#func make_array_mesh_global_old(add_collision_bool):
#	#var arrayMesh = ArrayMesh.new()
#	var newRigidBody
#	var rigid_owner_ID #turn off if we want multiple owners
#	if add_collision_bool == true:
#		pass
#		#newRigidBody = RigidBody.new() 
#		newRigidBody = paintedRigidBodyScene.instance() #a pick up able object
#		#paintBlobNode.add_child(newRigidBody) #should this be done later?
#		#call_deferred(paintBlobNode.add_child(newRigidBody))
#		#paintBlobNode.call_deferred("add_child", newRigidBody)
#		rigid_owner_ID = newRigidBody.create_shape_owner(newRigidBody) #create new owners ONCE shape
#	var arrays = []
#	arrays.resize(Mesh.ARRAY_MAX)
#	var vertices = [] #the final vertices array that we turn into poolVec array to pass into arrayMesh
#	var centreOfMass = []
#	#arrays[Mesh.ARRAY_VERTEX] = []
#	#need to actually define the points here
#	#make cylinder
#	var angle_divisions = []
#	var angle_division_amount = 4
#	for index in angle_division_amount:
#		#angle_divisions.append((angle_division_amount - index-1)*2.0*PI/float(angle_division_amount))
#		angle_divisions.append((index)*2.0*PI/float(angle_division_amount))
#	var startPrism = false
#	var endPrism = false #do we draw the face on the end
#	var amount_of_segments = sculpture_transforms.size()-1
#	if amount_of_segments <= 0:
#		return
#	var middlePositionVec = 0.5*sculpture_transforms[0].origin + 0.5*sculpture_transforms[amount_of_segments].origin
#	for prismIndex in amount_of_segments:
#		if prismIndex == 0:
#			startPrism = true
#		if prismIndex == amount_of_segments - 1:
#			endPrism = true
#		var startVec = sculpture_transforms[prismIndex] #actually a transform
#		var endVec = sculpture_transforms[prismIndex+1]
#		var dirVec = endVec.origin - startVec.origin
#		var midVec = 0.5*startVec.origin + 0.5*endVec.origin
#		var dirVecLength = dirVec.length()
#		#0.5*dirVecLength#0.4
#		var normalDirVec = dirVec/float(dirVecLength)
#		#number_of_vertices = 8
#	#	for vertIndex in number_of_vertices:
#	#		var vertPos = 
#
#
#		var vert_positions = []
#		#var newVert_indices = [] #should be 8 vertices , top left start = 0th entry clockwise around to 3rd entry, then repeat but for end vertices
#		#var newVertIndexMod = 0
#		#var new_indices_for_triangles = []#must be mulitple of 3
#		for sideIndex in 2: #start and end
#			var current_side_vert = startVec.origin
#			var current_basis = startVec.basis
#			var indexMod = 0
#			if sideIndex == 0:
#				current_side_vert = startVec.origin
#				current_basis = startVec.basis
#			else:
#				current_side_vert = endVec.origin
#				current_basis = endVec.basis
#				#indexMod = angle_divisions.size() - 1
#			#get plane that we draw the cube on
#			var basisVec1 = current_basis.x #this allows us to tilt the brush to go between 2D and 3D.
#			var basisVec2 = current_basis.y
#
#			for index in angle_divisions.size():
#				#var newIndex = (index + indexMod)%angle_divisions.size()
#				var angle = angle_divisions[index]
#				var vertPos =  current_side_vert + segment_radius*cos(angle)*basisVec1 + segment_radius*sin(angle)*basisVec2
#				vert_positions.append(vertPos)
#				#newVert_indices.append(newVertIndexMod)
#
#				#newVertIndexMod += 1
#			#now we have the vertices we need to define the indices for the triangles
#		var result = add_rectangular_prism_segment(vert_positions, startPrism, endPrism) #result = [vertices, collisionVertices]
#		var new_vertices = result[0]
#		var collisionVertices = result[1] #vertices for a convex collision shape
#		centreOfMass.append(result[2])
#		###############################################################
#		# Generate convexPolygon for each hexahedron in the mesh
#		###############################################################
#		if add_collision_bool == true:
#			var colShape = ConvexPolygonShape.new()
#			colShape.set_points(collisionVertices)
#			#var rigid_owner_ID = newRigidBody.create_shape_owner(newRigidBody) #create new owners for each shape
#			newRigidBody.shape_owner_add_shape(rigid_owner_ID, colShape)
#			print("Added a new shape for rigidBody")
#		#newMeshInst.global_transform.origin = midVec
#		###############################################################
#		vertices.append_array(new_vertices)
#
#
#	var actual_centre_of_mass = Vector3(0,0,0)
#	for CentreOMass in centreOfMass:
#		actual_centre_of_mass = actual_centre_of_mass + CentreOMass
#	actual_centre_of_mass = actual_centre_of_mass/float(centreOfMass.size())
#
#
#
#	#we should only do the below part once
#	###############################
#	#from woopdeedoo
#	var colors := []
#	for i in range(vertices.size()):
#		colors.append(Color.red)
#	var mesh := ArrayMesh.new()
#	#var arrays := []
#	#arrays.resize(Mesh.ARRAY_MAX)
#	arrays[Mesh.ARRAY_VERTEX] = PoolVector3Array(vertices)
#	arrays[Mesh.ARRAY_COLOR] = PoolColorArray(colors)
#	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
#	# mesh.surface_set_material(0, your_material)   # will need uvs if using a texture
#
#	#your_material.vertex_color_use_as_albedo = true # will need this for the array of colors
#
#	var mi := MeshInstance.new()
#	mi.mesh = mesh
#	var newMaterial = $MaterialChooser/MeshInstance.get("material/0")
#	mi.set("material/0", newMaterial) #trying to take materials from the outside world
#	if add_collision_bool == false:
#		paintBlobNode.add_child(mi)
#		return mi #exit the function here if we just want a mesh
#
#	#add_child(mi) # don't forget to add it as child of something (I always forget, lol)
#	# if the texture is a tileset like minecraft's, then maybe you can use this 
#	# instead of setting the material for each surface
#	# mi.material_override = your_material      # will need uvs if using a texture
#
#	mi.transform = Transform.IDENTITY #test does this fix picking up rigid bodies
#	newRigidBody.add_child(mi)
#	var name_of_mesh_scene = mi.name
#	newRigidBody.center_pickup_on = name_of_mesh_scene
#	newRigidBody.center_pickup_on_node = mi
#	newRigidBody.collision_layer = 1
#	newRigidBody.collision_mask = 3 #1 and 2
#	#newRigidBody.add_collision_exception_with(newRigidBody)
#	for childIndex in newRigidBody.get_child_count():
#		print("child of rigid body is = ", newRigidBody.get_child(childIndex), " class = ", newRigidBody.get_child(childIndex).get_class())
#	#PRINT RIGIDbODY SHAPES:
#	var owners = []
#	owners = newRigidBody.get_shape_owners()
#	print("owners = newRigidBody.get_shape_owners() : ", newRigidBody.get_shape_owners())
#	for owner_ID in owners:
#		var amount_of_shapes = newRigidBody.shape_owner_get_shape_count(owner_ID)
#		for shape_ID in amount_of_shapes:
#			print("found a new shape in newRigidBody for owner ", owner_ID, " with shape_ID = ", shape_ID)
#
#	#seems that collisionShape scenes do not actually exist at runtime and I need to acsess it all through CollisionObject
#	#https://docs.godotengine.org/en/3.4/classes/class_collisionobject.html
#	#look up how to transfer collision Shapes from one object to another
#	#https://godotengine.org/qa/4966/collision-detection-working-when-objects-created-from-script
#
#	##################################################
#
#
#
#	#call_deferred(paintBlobNode.add_child(newRigidBody)) #shold this be done earlier?
#	paintBlobNode.call_deferred("add_child", newRigidBody)
#	yield(get_tree().create_timer(0.1), "timeout")
#	#mi.global_transform.origin = actual_centre_of_mass #testing setting both to close to mesh, ruins position of mesh when its generated, shape is in the right spot still
#	newRigidBody.global_transform.origin = mi.global_transform.origin
#
#	newRigidBody.mode = RigidBody.MODE_CHARACTER #on normal rigid mode they just fly toward the origin for some reason
#	#the mode change isnt needed for the scene
#
#	#paintBlobNode.add_child(mi) 
#	return mi
#	#mi.global_transform.origin = spawnPos
