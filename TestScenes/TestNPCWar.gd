extends Spatial

#need to make one scene to show off all general ragdolls
#and abiility to switch models

#need to fix sword swings, maybe I should swing outwards first


#test the ability to run larger battle simulations (10 people or so, ideally MUCH more)
#need to make npcs unique enough to apply different morphs (note this and blends shapes are what lags the game not the physics)
#might need a lower quality rigidRagdoll to be able to do big simulations
#          o
# e.g.    /O\    3 or 4 rigidBodies 2 or 3 joints. instead of 13 bodies and 12 joints,
#so we can have a lot of units on the field without overloading the physics.

#we need to uniquify the npc AND equip sword through code, here

#var npcPreload = preload("res://addons/rigidRagdoll/Characters/rigidRagdollNPC_less.tscn")
#rigidRagdoll/Characters/rigidRagdollNPC.tscn")
#var npcPreload = preload("res://addons/rigidRagdoll/Characters/rigidRagdollNPC.tscn")
#var npcPreload = preload("res://addons/rigidRagdoll/Characters/GeneralRagdoll_CapsuleFoot.tscn")
#var npcPreload = preload("res://addons/rigidRagdoll/Characters/GeneralRagdoll_Complex.tscn")
#var npcPreload = preload("res://addons/rigidRagdoll/Characters/GeneralRagdoll_Simple.tscn")
var npcPreload = preload("res://addons/rigidRagdoll/Characters/GeneralRagdoll_Stumble.tscn")
#var npcPreload = preload("res://addons/rigidRagdoll/Characters/rigidRagdollNPC_minimal.tscn")
#var npcPreload = preload("res://addons/rigidRagdoll/Characters/rigidRagdollNPC.tscn")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var faction = -1
export var enemyAmount = 1
export var ragdollType = 3

var npcFinalStrings = ["Simple", "Complex", "CapsuleFoot", "Stumble"]
#var npcStrings = []
# Called when the node enters the scene tree for the first time.
func _ready():
	#var amountOfEach = 5
#	###################3
#	#spawn 1 of each ragdoll
#	var xPos = -8
#	for finalStr in npcFinalStrings:
#		var newStr = str("res://addons/rigidRagdoll/Characters/GeneralRagdoll_", finalStr,".tscn")
#		#npcStrings.append(npcStrings)
#		xPos += 1
#		var npcPos = Vector3(xPos,0,-16)
#		var faction = 0
#		npcPreload = load(newStr)
#		var npc = spawn_npc(npcPos, faction)
#	############################
	
	#return
	
	var xPos = -8
	var finalStr = npcFinalStrings[ragdollType%npcFinalStrings.size()]
	var newStr = str("res://addons/rigidRagdoll/Characters/GeneralRagdoll_", finalStr,".tscn")
	#npcStrings.append(npcStrings)
	xPos += 1
	var npcPos = Vector3(xPos,0,-16)
	var faction = 0
	npcPreload = load(newStr)
	for i in enemyAmount:
		var npc = spawn_npc(npcPos, faction)
		npcPos += Vector3(1,0,0)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn_npc(npcPos, faction):
	var npc = npcPreload.instance()
	add_child(npc)
	npc.global_transform.origin = npcPos
	#return #FOR TESTING GENERAL RAGDOLLS THAT DONT HAVE STATE CODE
	set_up_npc_state(npc, faction)
	return npc


func set_up_npc_state(npc, faction):
	#turn on fighting mode
	#var skelRagDoll = npc.get_node("Armature/SkeletonRagdoll")
	var skelRagDoll = npc
	
	skelRagDoll.faction = faction
	
	
	skelRagDoll.extraAnimBool = true
	skelRagDoll.extraAnimString = "anim_meleeFight"#"anim_boxingFight" #"state_alert"#
	skelRagDoll.extraAnimTime = 0
	skelRagDoll.extraAnimNode = $Camera/KinematicBody
	#skelRagDoll.stats.swingSpeed = 0.5*(2*randf()-1) + 1 #[0.5,1.5]
	#skelRagDoll.stats.walkSpeed =  0.2*(2*randf()-1) + 1.2# 0.2*(2*randf()-1) + 1 #[0.8,1.2]
	skelRagDoll.stats.walkSpeed =  0.275
	
	###
	var weapons = ["StabbingSword", "shortSword", "longSword"]#, "Staff"]#
	var randVar = randi()%weapons.size()
	var weaponName = weapons[randVar]
	var weaponPath = str("res://addons/rigidRagdoll/Items/", weaponName,".tscn")
	if weaponName in ["Staff"]:
		skelRagDoll.extraAnimString = "anim_rangedFight"
	#var randVar = randi()%2
	
	npc.spawn_and_equip(weaponPath)

