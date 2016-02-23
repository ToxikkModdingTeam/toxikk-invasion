//--DOOM 3 PINKY DEMON
//------------------------------------------------------------------
Class Pinky extends ToxikkMonster;

var				SoundCue			MetalSound;

simulated function PlayMetal()
{
	if (Health > 0)
		PlaySound(MetalSound, TRUE);
}

DefaultProperties
{
    Begin Object Name=CollisionCylinder
        CollisionHeight=+33.000000
		CollisionRadius=+64.000000
		bDrawBoundingBox=true
    End Object

	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Pinky.toxikk_pinky'
        AnimSets(0)=AnimSet'Doom3Monsters.Pinky.pinky_animset'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Boney.boney_mesh_Physics'
		PhysicsWeight=0.0
    End Object
    Mesh=MainMesh

	// How fast we run
    GroundSpeed=260.0

	PainSoundChance=0.5
	
	FootstepSound=SoundCue'Doom3Monsters.Pinky.VP.pinkystep_metal_cue'
	MetalSound=SoundCue'Doom3Monsters.Pinky.VP.pinkystep_metal_cue'
	
	PainSound=SoundCue'Doom3Monsters.Pinky.VP.pinky_pain_cue'
	
	SightSound=SoundCue'Doom3Monsters.Pinky.VP.pinky_roar_cue'
	DeathSound=SoundCue'Doom3Monsters.Pinky.VP.pinky_death_cue'
	AttackSound=SoundCue'Doom3Monsters.Pinky.VP.pinky_melee_cue'
	ChatterSound=SoundCue'Doom3Monsters.Pinky.VP.pinky_idle_cue'
	IdleSound=SoundCue'Doom3Monsters.Pinky.VP.pinky_idle_cue'
	
	bHasMelee=true

	MeleeAttackAnims(0)=Attack1
	MeleeAttackAnims(1)=Attack2
	MeleeAttackAnims(2)=Attack3
	MeleeAttackAnims(3)=Attack4
	
	PunchDamage=30
	
	Health=350
	
	AttackDistance=200
	
	RunningAnim=Run
	
	SightAnims(0)=Roar
	SightAnims(1)=Roar2
	SightAnims(2)=Roar3
	
	bUseAimOffset=false
}
