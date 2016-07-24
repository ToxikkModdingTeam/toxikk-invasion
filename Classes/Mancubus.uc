//--DOOM 3 MANCUBUS
//------------------------------------------------------------------
Class Mancubus extends ToxikkMonster;

DefaultProperties
{
	ShakeDamage=200
	ShakeDistance=1000
	
    Begin Object Name=CollisionCylinder
        CollisionHeight=+45.000000
		CollisionRadius=+64.000000
		bDrawBoundingBox=true
    End Object

	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Mancubus.mancubus_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Mancubus.mancubus_anims'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Mancubus.mancubus_ragdoll'
		PhysicsWeight=0.0
    End Object
    Mesh=MainMesh

    GroundSpeed=100.0

	PainSoundChance=0.5

	FootstepSound=SoundCue'Doom3Monsters.Mancubus.VP.fatty_step_cue'

	PainSound=SoundCue'Doom3Monsters.Mancubus.VP.fatty_pain_cue'

	SightSound=SoundCue'Doom3Monsters.Mancubus.VP.fatty_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Mancubus.VP.fatty_die_cue'
	AttackSound=SoundCue'Doom3Monsters.Mancubus.VP.fatty_chatter_combat_cue'
	FireSound=SoundCue'Doom3Monsters.Mancubus.VP.fatty_fire_cue'
	ChatterSound=SoundCue'Doom3Monsters.Mancubus.VP.fatty_chatter_combat_cue'
	IdleSound=SoundCue'Doom3Monsters.Mancubus.VP.fatty_chatter_cue'

	TipBoneLeft=sock_lgun
	TipBoneRight=sock_rgun
	TipBone=sock_rgun

	bHasMelee=true
	MeleeAttackAnims(0)=Attack1
	PunchDamage=30
	AttackDistance=200

	bHasRanged=true
	MissileClass=Class'MancubusMissile'
	RangedAttackDistance=2500
	RangedAttackAnims(0)=MultiFire
	
	Health=750
	
	RunningAnim=Walk
	
	SightAnims(0)=Sight
	
	Mass=10000
	
	MonsterName = "Mancubus"
}
