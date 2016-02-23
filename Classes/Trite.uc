//--DOOM 3 TRITE
//------------------------------------------------------------------
Class Trite extends ToxikkMonster;

DefaultProperties
{
    Begin Object Name=CollisionCylinder
        CollisionHeight=+25.000000
		CollisionRadius=+25.000000
		bDrawBoundingBox=true
    End Object

	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Trite.trite_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Trite.trite_anims'
        AnimTreeTemplate=AnimTree'Doom3Monsters.doom3_animtree'
        HiddenGame=FALSE
        HiddenEditor=FALSE
		CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=false
		BlockRigidBody=true
		RBChannel=RBCC_Untitled3
		RBCollideWithChannels=(Untitled3=true,Default=true)
		bAcceptsStaticDecals=FALSE
		bAcceptsDynamicDecals=TRUE
		LightingChannels=(BSP=true,Static=true)
		LightEnvironment=MyLightEnvironment
		bHasPhysicsAssetInstance=true
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Trite.trite_mesh_Physics'
		PhysicsWeight=0.0
    End Object
    Mesh=MainMesh

	// How fast we run
    GroundSpeed=225.0

	PainSoundChance=0.5
	
	FootstepSound=SoundCue'Doom3Monsters.Trite.VP.trite_walk_cue'

	PainSound=SoundCue'Doom3Monsters.Trite.VP.trite_pain_cue'
	
	SightSound=SoundCue'Doom3Monsters.Trite.VP.trite_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Trite.VP.trite_death_cue'
	AttackSound=SoundCue'Doom3Monsters.Trite.VP.trite_attack_cue'
	ChatterSound=SoundCue'Doom3Monsters.Trite.VP.trite_sight_cue'
	IdleSound=SoundCue'Doom3Monsters.Trite.VP.trite_sight_cue'
	
	bHasMelee=true
	bHasRanged=true
	bHasLunge=true

	MeleeAttackAnims(0)=Attack1
	MeleeAttackAnims(1)=Attack2
	
	PunchDamage=15
	
	Health=50
	
	AttackDistance=64
	RangedAttackDistance=1000
	
	RunningAnim=Walk1
	
	SightAnims(0)=Sight
	
	LungeStartAnim=Jump_Start
	LungeMidAnim=Jump_Mid
	LungeEndAnim=Jump_End
	LungeSpeed=1000.0
	
	LungeDamage=30
	
	// 100 percent, always lunge
	LungeChance=0.0
	// Rotating the trite's torso would be a disaster
	bUseAimOffset=false
}
