extends Node

var boneIndex = {
	"MorphChest" : 31, #makes both boobs bigger can be scaled on both x and y
	"BreastLeft" : 32, #can rotate the boobs individually to give different shapes
	"BreastRight" : 33,
	"MorphNipples" : 34, #can scale x slightly (up to 1.4) for bigger nipples, after that point the sideways growth of the nipple is too noticeable, note this works differently for men
	"MorphBack" : 35, #scaleX in [0.3,1.4], scaleY up for weird shoulder bumps (raceMod), scaleZ down to 0 for mega pushed out back and up to 1.2 for slightly inwards back
	"MorphWaist" : 36, #scaleX down to 0 is anorexia/starvation, up to 1.4 is slightly wider waist, scaleY fucked, scaleZ down to 0.3 gets the hourglass inwards part of the back to go in more, if pushed further it could be a raceMod
	"MorphButt" : 47, #scaleX up to 2 is superWide hips down to 0.5 to make hips very small, scaleY up to 2.2 for high/tall butt down to 0 to decrease upper hip width (like scaleX going down), scaleZ up to 2.5 for butt that comes out more or down to 0 for a flat butt
	"MorphBelly" : 48, #scaleX up to 4 for belly width and scaleZ up to 6 for belly depth , scaleY is fucked, we can also scale x and z down to 0 to add to the flat belly skinny effect
	"MorphThighs" : 49, #scaleX up to 2 for super wide upper legs down to 0.7 for super thin legs, scaleY up to 3 for Faun raceMod scale down to 0.5 to lower hips, scaleZ up to 1.8 to increase thigh depth scale down to 0 for thinner upper legs
}

var bodyBlend = {
	"Belly" : 1, #[-0.25, 1]
	"FlatBoobs" : 2, #[-1,1]
	"Male" : 3, #[-0.5, 1]
	"Muscles" : 4, #[-0.2,1]
	"Thickness" : 5, #[-0.5, 1]
	"Thighs" : 6, #[-1,1]
}

var headBlendLimits = {
	"Beak" : {
		"enum" : 0,
		"max" : 1,
		"min" : -0.3,
	},
	"CheeksFlat" : {
		"enum" : 0,
		"max" : 1,
		"min" : -1,
	},
	"ChinDown" : {
		"enum" : 0,
		"max" : 1,
		"min" : -1,
	},
	"ChinSmooth" : {
		"enum" : 0,
		"max" : 1,
		"min" : -1,
	},
	"EarsBig" : {
		"enum" : 0,
		"max" : 1,
		"min" : -0.4,
	},
	"Eye Edge Lift" : {
		"enum" : 0,
		"max" : 1,
		"min" : -0.5,
	},
	"Eye Shape Tight" : {
		"enum" : 0,
		"max" : 1,
		"min" : -0.8,
	},
	"EyeBottomLift" : {
		"enum" : 0,
		"max" : 1,
		"min" : -0.5,
	},
	"HeadSpikes" : {
		"enum" : 0,
		"max" : 1,
		"min" : 0,
	},
	"Horns" : {#
		"enum" : 0,
		"max" : 1,
		"min" : -0.2,
	},
	"JawStrong" : {
		"enum" : 0,
		"max" : 1,
		"min" : -1,
	},
	"LipsPuckered" : {
		"enum" : 0,
		"max" : 1,
		"min" : -1,
	},
	"Male" : {
		"enum" : 0,
		"max" : 1,
		"min" : -1,
	},
	"MouthDown" : {
		"enum" : 0,
		"max" : 1,
		"min" : -0.4,
	},
	"MouthWidth" : {
		"enum" : 0,
		"max" : 1,
		"min" : -1,
	},
	"NoseBig" : {
		"enum" : 0,
		"max" : 1,
		"min" : -0.8,
	},
	"SpikyEars" : {
		"enum" : 0,
		"max" : 1,
		"min" : -0.4,
	},
}

var headBoneLimits = {}

var bodyBlendLimits = {
	"Belly" : {
		"enum" : 1,
		"max" : 1,
		"min" : -0.25,
	}, 
	"FlatBoobs" : {
		"enum" : 2,
		"max" : 0.5,
		"min" : -1,
	},  #[-1,1]
	"Male" : {
		"enum" : 3,
		"max" : 1,
		"min" : -0.5,
	}, #[-0.5, 1]
	"Muscles" : {
		"enum" : 4,
		"max" : 1,
		"min" : -0.2,
	}, #[-0.2,1]
	"Thickness" : {
		"enum" : 5,
		"max" : 0.4, #1,  was fine for females but not for males
		"min" : -0.5, #Fine for both
#		"maxF" : 1, #1,  was fine for females but not for males
#		"minF" : -0.7, #Fine for both
	}, #[-0.5, 1]
	"Thighs" : {
		"enum" : 4,
		"max" : 1,
		"min" : -1,
	}, #[-1,1]
}
#so fatness needs to increase belly thicness and thighs
#thickness thighs and boobs are genetic blendshapes that could be part of a genetic code that is passed down

#take axis of rotation as the eigenvector of the rotation matrix
var bodyBoneLimits = { #I have recorded scale max and min but most of this can be done with pose and it might be better to do it with pose if I can
	"MorphChest" : {
		"index" : 31, #makes both boobs bigger can be scaled on both x and y
		"scaleMax" : [1.6, 1.6, 2], #[x, y, z]
		"scaleMin" : [0.7, 0.5, 0.5],  #PoseZ(-2,4) for male chest pushed in/out
		"poseMax" : [0, 3, 4.5], #pose.origin.y controls droop in [-5,3] = [saggy , higher up],
		"poseMin" : [0, -2, -5], #pose.origin.z controls size from [-2.5,4.5] (forwards/back)
		"rotMax" : [0, 0, 0],
		"rotMin" : [0, 0, 0],
	},
	"BreastLeft" : { #same as scaling morphChest, can make lopsided boobs with this, rotation is more important here to give different shapes
		"index" : 32, #makes both boobs bigger can be scaled on both x and y
		"scaleMax" : [1.6, 1.6, 2], #[x, y, z]
		"scaleMin" : [0.7, 0.5, 0.5],
		#pose reserved for physical movement
		"poseMax" : [0, 0, 0],
		"poseMin" : [0, 0, 0], 
		"rotMax" : [0, 0, 0], #rotate about x we go down (sag) in [-60,15] = [saggynessMAx, slightPerk], rotate about z we go sideways (shape)
		"rotMin" : [0, 0, 0],
		#max rotation for shape outwards is (0.707,-0.707,0)|(0.707,0.707,0)|(0,0,1)| which is approx a rotation of 45 degrees in z axis
		#rotating about y axis adds some sideways boob shape up to 60 degrees. look more subtle than changing z rotation
	}, 
	"BreastRight" : { #same as scaling morphChest, can make lopsided boobs with this, rotation is more important here to give different shapes
		"index" : 33, #makes both boobs bigger can be scaled on both x and y
		"scaleMax" : [1.6, 1.6, 2], #[x, y, z]
		"scaleMin" : [0.7, 0.5, 0.5],
		"poseMax" : [0, 0, 0],
		"poseMin" : [0, 0, 0], 
		"rotMax" : [0, 0, 0],
		"rotMin" : [0, 0, 0],
	}, 
	"MorphNipples" : { #can scale x slightly (up to 1.4) for bigger nipples, after that point the sideways growth of the nipple is too noticeable, note this works differently for men
		"index" : 34, 
		"scaleMax" : [1.4, 1, 1], #[x, y, z]
		"scaleMin" : [1, 1, 1], 
		"poseMax" : [0, 5, 0], #can move pose.origin.y to 5 for huge nipples instead, but this also starts to dend downwards
		"poseMin" : [0, 0, 0], 
		"rotMax" : [0, 0, 0],
		"rotMin" : [0, 0, 0],
	},  
	"MorphBack" : { #scaleX in [0.3,1.4], scaleY up for weird shoulder bumps (raceMod), scaleZ down to 0 for mega pushed out back and up to 1.2 for slightly inwards back
		"index" : 35, 
		"scaleMax" : [1.4, 1, 1.2], #[x, y, z]
		"scaleMin" : [0.3, 1, 0.8], #could do a raceMod by changing y here or by changnign z less than 0.8
		"poseMax" : [0, 4, 2], #(raceMod) pose.origin.y in [-3,4] more subtle effect than changning scale.
		"poseMin" : [0, -3, -5],  #could be pushed outwards by setting poseZ to -5 and push back inwards by setting it to -2, these mods work for males
		"rotMax" : [0, 0, 0], 
		"rotMin" : [0, 0, 0],
	}, 
	"MorphWaist" : { #scaleX down to 0 is anorexia/starvation, up to 1.4 is slightly wider waist, scaleY fucked, scaleZ down to 0.3 gets the hourglass inwards part of the back to go in more, if pushed further it could be a raceMod
		"index" : 36, 
		"scaleMax" : [1.4, 1, 1], #[x, y, z] can scale up z to 1.3 max for boys
		"scaleMin" : [1, 1, 0.3], #x was 0
		"poseMax" : [0, 6, 0],  #pose.origin.y in [-6,6] changes position of belly button, not sure how it would interact with scale adjustments
		"poseMin" : [0, -6, 0], 
		"rotMax" : [0, 0, 0],
		"rotMin" : [0, 0, 0],
	}, 
	"MorphButt" : { #scaleX up to 2 is superWide hips down to 0.5 to make hips very small, scaleY up to 2.2 for high/tall butt down to 0 to decrease upper hip width (like scaleX going down), scaleZ up to 2.5 for butt that comes out more or down to 0 for a flat butt
		"index" : 47, 
		"scaleMax" : [1.5, 2.2, 2.5], #[x, y, z] for female scaleX to 2 for super wide hips we lower this for males
		"scaleMin" : [0.5, 0, 0], 
		"poseMax" : [0, 10, 5],  #pose.origin.y [-5,10]= [butt sag, butt lift], 
		"poseMin" : [0, -5, -15], #pose.origin.z = [-15,5] = [butt biggness, butt flatness] #5 was good for chicks for mens butts look weird
		"rotMax" : [0, 0, 0],  #moving butt up rotate x up to 60 or down to -15 in [-15,60]
		"rotMin" : [0, 0, 0],
	}, 
	"MorphBelly" : { #scaleX up to 4 for belly width and scaleZ up to 6 for belly depth , scaleY is fucked, we can also scale x and z down to 0 to add to the flat belly skinny effect
		"index" : 48, 
		"scaleMax" : [4, 1, 6], #[x, y, z]
		"scaleMin" : [0, 1, 0], 
		"poseMax" : [0, 10, 10], #pose.origin.y in [-10,10] = move belly button [down,up] , 
		"poseMin" : [0, -10, -5], #pose.origin.z in [-5,10] belly sucked in to belly out
		"rotMax" : [0, 0, 0], 
		"rotMin" : [0, 0, 0],
	}, 
	"MorphThighs" : {
		"index" : 49, 
		"scaleMax" : [1.7, 1, 1.8], #scaleY up to 3 for Faun raceMod
		"scaleMin" : [0.7, 0.5, 0], #scale down to 0.5 to lower hips
		"poseMax" : [0, 0, 6], 
		"poseMin" : [0, 0, -1], #pose.origin.z [-1,6] push thighs [back, forward]
		"rotMax" : [0, 0, 0],
		"rotMin" : [0, 0, 0], 
	}, #scaleX up to 2 for super wide upper legs down to 0.7 for super thin legs, scaleY up to 3 for Faun raceMod scale down to 0.5 to lower hips, scaleZ up to 1.8 to increase thigh depth scale down to 0 for thinner upper legs
}


var bodyMorphs = {
#	"morphName" : {
#		"typeString" : "bone or blend",
#		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
#		"transformAxis" : 0, #0=x, 1=y,2=z
#		"nameString" : "boneName or blendShapeName",
#		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
#		#Description : 
#	},
#	"morphNameDefault" : {
#		"typeString" : "bone or blend",
#		"transformType" : "null", 
#		"transformAxis" : 0, 
#		"nameString" : "boneName or blendShapeName",
#		"value" : 0, 
#		#Description : 
#	},
	"Male" : { #should be set cis default as it's easier to test if other morphs mess it up
		"typeString" : "blend",
		"transformType" : "null", 
		"transformAxis" : 0, 
		"nameString" : "Male",
		"value" : 0, 
		"LOD" : 0,
		#Description : Male blendshape
	},
	"Thickness" : { #makes male boobs look weird if it goes too thin
		"typeString" : "blend",
		"transformType" : "null", 
		"transformAxis" : 0, 
		"nameString" : "Thickness",
		"value" : 0, 
		"LOD" : 1,
		#Description : Thickness blendshape
	},
	"Thighs" : {
		"typeString" : "blend",
		"transformType" : "null", 
		"transformAxis" : 0, 
		"nameString" : "Thighs",
		"value" : 0, 
		"LOD" : 1,
		#Description : Thighs blendshape
	},
	"Muscles" : { 
		"typeString" : "blend",
		"transformType" : "null", 
		"transformAxis" : 0, 
		"nameString" : "Muscles",
		"value" : 0, 
		"LOD" : 1,
		#Description : Muscles blendshape
	},
	"FlatBoobs" : {
		"typeString" : "blend",
		"transformType" : "null", 
		"transformAxis" : 0, 
		"nameString" : "FlatBoobs",
		"value" : 0, 
		"LOD" : 0,
		#Description : FlatBoobs blendshape
	},
	"ChestForward" : {
		"typeString" : "bone",
		"transformType" : "pose", 
		"transformAxis" : 2, #z
		"nameString" : "MorphChest",
		"value" : 0, 
		#Description : pushes the chest out with higher values and pushes in with lower values.
	},
	"ChestSag" : {
		"typeString" : "bone",
		"transformType" : "pose", 
		"transformAxis" : 1, #y
		"nameString" : "MorphChest",
		"value" : 0, 
		#Description : pushes the chest up and down
	},
	"LiftBellyButton" : {  #Ruins male pecs
		"typeString" : "bone",
		"transformType" : "pose", 
		"transformAxis" : 1,  #y
		"nameString" : "MorphWaist",
		"value" : 0, 
		#Description : pushes the belly button up with higher values and pushes it down with lower values.
	},
	"BigUpperBack" : {
		"typeString" : "bone",
		"transformType" : "pose", 
		"transformAxis" : 2, #z
		"nameString" : "MorphBack",
		"value" : 0, 
		#Description : pushes the back out with lower values and pushes in with higher values.
	},
	"WaistScale" : {
		"typeString" : "bone",
		"transformType" : "scale", 
		"transformAxis" : 0, #x
		"nameString" : "MorphWaist",
		"value" : 1, 
		#Description : pushes the waist in/out
	},
	"WideHips" : {
		"typeString" : "bone",
		"transformType" : "scale", 
		"transformAxis" : 0, #x
		"nameString" : "MorphButt",
		"value" : 1, 
		#Description : pushes the hips in/out sideways
	},
	"WideThighs" : {
		"typeString" : "bone",
		"transformType" : "scale", 
		"transformAxis" : 0, #x
		"nameString" : "MorphThighs",
		"value" : 1, 
		#Description : pushes the thighs in/out sideways
	},
	"BiggerNipples" : {
		"typeString" : "bone",
		"transformType" : "pose", 
		"transformAxis" : 1, #y
		"nameString" : "MorphNipples",
		"value" : 0, 
		#Description : pushes the nipples in/out
	},
	"FlatButt" : {
		"typeString" : "bone",
		"transformType" : "pose", 
		"transformAxis" : 2, #z
		"nameString" : "MorphButt",
		"value" : 1, 
		#Description : pushes the butt in/out so it can be flat or out
	},
	"SagButt" : {
		"typeString" : "bone",
		"transformType" : "pose", 
		"transformAxis" : 1, #y
		"nameString" : "MorphButt",
		"value" : 1, 
		#Description : pushes the butt up/down so it can be saggy
	},
}

var headMorphs = {
#	"morphName" : {
#		"typeString" : "bone or blend",
#		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
#		"transformAxis" : 0, #0=x, 1=y,2=z
#		"nameString" : "boneName or blendShapeName",
#		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
#		#Description : 
#	},
	"Beak" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "Beak",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 0,
		#Description : 
	},
	"CheeksFlat" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "CheeksFlat",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 2,
		#Description : 
	},
	"ChinDown" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "ChinDown",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 2,
		#Description : 
	},
	"ChinSmooth" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "ChinSmooth",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 2,
		#Description : 
	},
	"EarsBig" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "EarsBig",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 1,
		#Description : 
	},
	"Eye Edge Lift" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "Eye Edge Lift",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 2,
		#Description : 
	},
	"Eye Shape Tight" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "Eye Shape Tight",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 2,
		#Description : 
	},
	"EyeBottomLift" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "EyeBottomLift",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 2,
		#Description : 
	},
	"HeadSpikes" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "HeadSpikes",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 0,
		#Description : 
	},
	"Horns" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "Horns",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 0,
		#Description : 
	},
	"JawStrong" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "JawStrong",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 2,
		#Description : 
	},
	"LipsPuckered" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "LipsPuckered",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 2,
		#Description : 
	},
	"Male" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "Male",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 1,
		#Description : 
	},
	"MouthDown" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "MouthDown",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 1,
		#Description : 
	},
	"MouthWidth" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "MouthWidth",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 2,
		#Description : 
	},
	"NoseBig" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "NoseBig",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 2,
		#Description : 
	},
	"SpikyEars" : {
		"typeString" : "blend",
		"transformType" : "null", #"pose, scale or rotation" #for boneMorphs only, null for blendShapes
		"transformAxis" : 0, #0=x, 1=y,2=z
		"nameString" : "SpikyEars",
		"value" : 0, #between 0 and 1, keep as zero in script and set in game. (we need to be able to set to what was originally 0)
		"LOD" : 1,
		#Description : 
	},
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


var LOD_bodyBlendShapes = {
	#0 is most important ones that should show up at furthest distances then the next number will be slightly less important and so on
	0 : ["Male" , "FlatBoobs"]
}

var LOD_headBlendShapes = {
	#0 is most important ones that should show up at furthest distances then the next number will be slightly less important and so on
	0 : ["Horns", "HeadSpikes", "Beak"],
	1 : ["SpikyEars", "Male", "EarsBig"]
}

var raceEnum = {
	"human" : 0,
	"elf" : 1,
	"demon" : 2,
	"bird" : 3,
	"sahagin" : 4,
}

func setBaseEnivronmentalCultureMods(brains, brainID, race, normalisedHotAvg, normalisedWetAvg, distanceToEquator, wildness):
	var skinLightness = distanceToEquator
	var cultureMod = normalisedWetAvg
# NOT race specific
	#brains[brainID].bodyMorphs[] = 
#	BODY MORPHS
#	"Male" : 0,

#############body Morphs turned off for now as they do not work with the new system
#	brains[brainID].bodyMorphs["Thickness"] = 1-normalisedHotAvg
#	brains[brainID].bodyMorphs["Thighs"] = distanceToEquator
##	"Muscle" : 0,
##	"FlatBoobs" : 0,
##		"ChestForward" : 0, #individual genes
##		"ChestSag" : 0, #individual genes
##		"LiftBellyButton" : 0, #individual genes
##		"BigUpperBack" : 0, #maybe race based
##		"WaistScale" : 0, #individual genes
#	brains[brainID].bodyMorphs["WideHips"] = 1-normalisedWetAvg
#	brains[brainID].bodyMorphs["WideThighs"] = normalisedHotAvg
##		"BiggerNipples" : 0, #individual genes
#	brains[brainID].bodyMorphs["FlatButt"] = 1-distanceToEquator #1-latitude so it corresponds with thighs


#		"SagButt" : 0, #individual genes
	#HEADMORPHS
#		"Beak" : 0, #raceMod
#		"CheeksFlat" : 0, #individual genes
#		"ChinDown" : 0, #individual genes
#		"ChinSmooth" : 0, #individual genes
#		"EarsBig" : 0, #individual genes
	brains[brainID].headMorphs["Eye Edge Lift"] = min(1,brains[brainID].headMorphs["Eye Edge Lift"]+float(normalisedWetAvg)/2.0) #wet
	brains[brainID].headMorphs["Eye Shape Tight"] = min(1,brains[brainID].headMorphs["Eye Edge Lift"]+float(normalisedHotAvg)/2.0)
#		"Eye Bottom Lift" : 0, #racemod
#		"HeadSpikes" : 0, #racemod
#		"Horns" : 0, #racemod
#		"JawStrong" : 0, #individual genes
#		"LipsPuckered" : 0, #individual genes
#		"Male" : 0, #sex slider
	brains[brainID].headMorphs["MouthDown"] = normalisedHotAvg #hot
	brains[brainID].headMorphs["MouthWidth"] = distanceToEquator #latitude
	brains[brainID].headMorphs["NoseBig"] = normalisedHotAvg #hot
#		"SpikyEars" : 0, #raceMod
	
	
	#Race specific culture mods
	var mod = wildness #was 0.2*wildness #float(worldData.vertexData[str(structVertex.x,",",structVertex.y)].dijkstra.distanceToPath)/float(dicData.config["MaxDistanceToPathApproximation"])
	print("wildness = " , wildness, " mod = ", mod)
	if race == raceEnum["elf"]:
		brains[brainID].headMorphs["SpikyEars"] = min(1, mod + brains[brainID].headMorphs["SpikyEars"]) # += mod
		brains[brainID].headMorphs["Eye Edge Lift"] = min(1, mod + brains[brainID].headMorphs["Eye Edge Lift"])
		brains[brainID].headMorphs["Eye Shape Tight"] = min(1, mod + brains[brainID].headMorphs["Eye Shape Tight"])
	elif race == raceEnum["demon"]:
		brains[brainID].headMorphs["Horns"] += mod
		brains[brainID].headMorphs["HeadSpikes"] += mod
		brains[brainID].headMorphs["Eye Shape Tight"] += mod
		brains[brainID].headMorphs["EyeBottomLift"] += -mod #-0.8 #is this okay to move to -ve
		brains[brainID].otherMorphs["scaleMax"] = 1.4 - 0.7*normalisedHotAvg #makes demons into imps in hot areas
	elif race == raceEnum["bird"]:
		brains[brainID].headMorphs["Beak"] = min(1, mod + brains[brainID].headMorphs["Beak"])
		brains[brainID].headMorphs["Horns"] = min(1, mod + brains[brainID].headMorphs["Horns"])
	elif race == raceEnum["sahagin"]:
		brains[brainID].headMorphs["EyeBottomLift"] += mod
		brains[brainID].headMorphs["LipsPuckered"] += mod
		brains[brainID].headMorphs["MouthDown"] += mod
		brains[brainID].headMorphs["MouthWidth"] += mod
		brains[brainID].headMorphs["JawStrong"] += -mod
	else: #raceEnumVar == raceEnum["human"]:
		pass
	setBaseRaceColour(brains, brainID, race, cultureMod, skinLightness, null) #(brainID, raceEnumVar, cultureMod, skinLightness, subRaceMod)
	#setNaturalHairColour(brainID)


func setBaseHeadRaceMods(brains, brainID, raceEnumVar): #set the values of the raceMods, in the dictionary. Im not sure if 0 is right
#	if raceEnumVar == raceEnum["human"]:
#		pass
	#brainID += 1
	if raceEnumVar == raceEnum["elf"]:
		brains[brainID].headMorphs["SpikyEars"] = 0.8
		brains[brainID].headMorphs["Eye Edge Lift"] = 0.8
		brains[brainID].headMorphs["Eye Shape Tight"] = 0.8
	elif raceEnumVar == raceEnum["demon"]:
		brains[brainID].headMorphs["Horns"] = 0.8
		brains[brainID].headMorphs["HeadSpikes"] = 0.8
		brains[brainID].headMorphs["Eye Shape Tight"] = 0.8
		brains[brainID].headMorphs["EyeBottomLift"] = 0.2#0#-0.8
	elif raceEnumVar == raceEnum["bird"]:
		brains[brainID].headMorphs["Beak"] = 0.8
		brains[brainID].headMorphs["Horns"] = 0.5
	elif raceEnumVar == raceEnum["sahagin"]:
		brains[brainID].headMorphs["EyeBottomLift"] = 0.8
		brains[brainID].headMorphs["LipsPuckered"] = 0.8
		brains[brainID].headMorphs["MouthDown"] = 0.8
		brains[brainID].headMorphs["MouthWidth"] = 0.8
		brains[brainID].headMorphs["JawStrong"] = 0.2#-0.8
	else: #raceEnumVar == raceEnum["human"]:
		pass

func setBaseRaceColour(brains, brainID, raceEnumVar, cultureMod, skinLightness, subRaceMod):
	#FIX this was written for the spatial material not the outline shader material, we need a rewrite
	var H = {"val":0, "max":1, "min":0}
	var S = {"val":0, "max":1, "min":0}
	var V = {"val":0, "max":1, "min":0}
	if raceEnumVar == raceEnum["elf"]:
		H.max = 300.0/360.0
		H.min = 60.0/360.0
		H.val = cultureMod*(H.max-H.min)+H.min
		S.max = 80.0/100.0
		S.min = 20.0/100.0
		S.val = (1-skinLightness)*(S.max-S.min)+S.min #so as skin lightness gets bigger, saturation gets smaller making it more light skinned
		V.val = 1
	elif raceEnumVar == raceEnum["demon"]:
		H.max = 50.0/360.0
		H.min = 0.0/360.0
		H.val = cultureMod*(H.max-H.min)+H.min
		S.val = 1
		V.max = 100.0/100.0
		V.min = 20.0/100.0
		V.val = skinLightness*(V.max-V.min)+V.min #so as skin lightness gets bigger, value gets bigger making it more light skinned
	elif raceEnumVar == raceEnum["bird"]:
		H.max = 340.0/360.0
		H.min = 260.0/360.0
		H.val = cultureMod*(H.max-H.min)+H.min
		S.val = 1
		V.max = 100.0/100.0
		V.min = 50.0/100.0
		V.val = skinLightness*(V.max-V.min)+V.min
	elif raceEnumVar == raceEnum["sahagin"]:
		H.max = 160.0/360.0
		H.min = 200.0/360.0
		H.val = cultureMod*(H.max-H.min)+H.min
		S.max = 100.0/100.0
		S.min = 30.0/100.0
		S.val = (1-skinLightness)*(S.max-S.min)+S.min
		V.val = 1
	else: #raceEnumVar == raceEnum["human"]:
		H.val = 10.0/360.0
		S.max = 60.0/100.0
		S.min = 30.0/100.0
		S.val = cultureMod*(S.max-S.min)+S.min
		V.max = 100.0/100.0
		V.min = 30.0/100.0
		V.val = skinLightness*(V.max-V.min)+V.min
	
	brains[brainID]["otherMorphs"]["skinColour.h"] = H.val
	brains[brainID]["otherMorphs"]["skinColour.s"] = S.val
	brains[brainID]["otherMorphs"]["skinColour.v"] = V.val
	
	#skeletonNode.get_node("Body").mesh.get("surface_1/material").albedo_color = Color.from_hsv(H.val,S.val,V.val)
	#skeletonNode.get_node("Head").mesh.get("surface_1/material").albedo_color = Color.from_hsv(H.val,S.val,V.val)
