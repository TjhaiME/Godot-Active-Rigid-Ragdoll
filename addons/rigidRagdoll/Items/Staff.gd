extends "res://addons/rigidRagdoll/Scripts/Object_pickable_modified_rigidJoint.gd"#RigidBody


#IDEA:
#create a sword that when you stab with it it creates a slidey joint
#so you can stab in and out
var attackLength = 0.9

var projectileScene = null

# Called when the node enters the scene tree for the first time.
func _ready():
	projectileScene = load("res://addons/rigidRagdoll/Items/simpleProjectile.tscn") #would this work to keep it loaded
	pass # Replace with function body.

var coolDownOn = false
var coolDownTimer = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if coolDownOn == true:
		coolDownTimer += delta
		if coolDownTimer >= 1:
			coolDownOn = false
			coolDownTimer = 0



func rangeAtk(targetPos):
	if coolDownOn == true:
		return
	#called when the npc who holds this item does an attack "animation"
	var projectile = projectileScene.instance()
	#add_child(projectile)
	get_tree().get_current_scene().add_child(projectile) #just add it to the top scene
	projectile.global_transform.origin = $ProjectileSpawn.global_transform.origin
	var targetDir = projectile.global_transform.origin - global_transform.basis.z
	projectile.look_at( targetPos, Vector3(0,1,0) )
	#print("projectile looking at" , targetPos)
	#FIX not sure if this is meanat to go - or +
	projectile.linear_velocity = -10*projectile.global_transform.basis.z
	coolDownOn = true
