# Godot-Active-Rigid-Ragdoll

This project has various Active Rigid Body Ragdolls including a full self balancing humanoid


DESCRIPTION:

I have found a way to make a simple self balancing humanoid ragdoll in Godot

It doesn't NEED extra code to balance, it can do it entirely with the physics engine.
You can use code to match it to any mesh you want (Deform skeleton with ragdoll)
we just need corresponding bone names. (probably needs to be a similar height for best results)



PHYSICS:

the physics is similar to Moose Mighty Beanz

It is easier for things to balance if their Centre of Mass is closer to the ground
The Centre of Mass of a rigid body in Godot is located at the origin of the rigid body.
For the purposes of rotation, all the mass of a rigid body is located at the origin of the rigid body.
In other words, the Centre of Mass of a rigid body in Godot is located at the origin of the rigid body.

So if we put the origin, of a rigid body capsule player, on the ground then all the mass will be located in that spot.

We can use this to make a capsule that stays upright (a moose mighty bean)


Description with pictures
[tutorial of concepts.pdf](https://github.com/TjhaiME/Godot-Active-Rigid-Ragdoll/files/10121843/tutorial.of.concepts.pdf)
