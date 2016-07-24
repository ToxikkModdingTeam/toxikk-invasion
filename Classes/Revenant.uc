//--DOOM 3 REVENANT
//------------------------------------------------------------------
Class Revenant extends ToxikkMonster;

DefaultProperties
{
    Begin Object Name=CollisionCylinder
        CollisionHeight=+45.000000
		CollisionRadius=+32.000000
		bDrawBoundingBox=true
    End Object

	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Revenant.revenant_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Revenant.revenant_anims'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Revenant.revenant_ragdoll'
		PhysicsWeight=0.0
    End Object
    Mesh=MainMesh

	// How fast we run
    GroundSpeed=100.0

	PainSoundChance=0.5
	
	FootstepSound=SoundCue'Doom3Monsters.Revenant.VP.rev_step_cue'
	
	PainSound=SoundCue'Doom3Monsters.Revenant.VP.rev_pain_cue'
	
	SightSound=SoundCue'Doom3Monsters.Revenant.VP.rev_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Revenant.VP.rev_death_cue'
	AttackSound=None
	FireSound=SoundCue'Doom3Monsters.Revenant.VP.rev_fire_cue'
	ChatterSound=SoundCue'Doom3Monsters.Revenant.VP.rev_chattercombat_cue'
	IdleSound=SoundCue'Doom3Monsters.Revenant.VP.rev_chatter_cue'
	
	TipBoneLeft=sock_lgun
	TipBoneRight=sock_rgun
	TipBone=sock_rgun
	
	MissileClass=Class'RevenantMissile'
	
	bHasMelee=true
	bHasRanged=true

	MeleeAttackAnims(0)=Attack1
	MeleeAttackAnims(1)=Attack2
	MeleeAttackAnims(2)=Attack3
	
	PunchDamage=15
	
	Health=750
	
	AttackDistance=100
	RangedAttackDistance=2500
	
	RangedAttackAnims(0)=RangedAttackBoth
	RangedAttackAnims(1)=RangedAttackLeft
	RangedAttackAnims(2)=RangedAttackRight
	
	RunningAnim=Walk
	
	SightAnims(0)=Sight
	SightAnims(1)=Sight2
	
	Mass=400
	
	MonsterName = "Revenant"
}
