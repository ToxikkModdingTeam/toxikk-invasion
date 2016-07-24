//--DOOM 3 BRUISER
//------------------------------------------------------------------
Class Bruiser extends ToxikkMonster;

// Screen textures
var			MaterialInstanceConstant			Screen_Angry, Screen_Idle, Screen_Sight, Screen_Pain;
var			int									ScreenID;

// SCREEN CHANGES, CALLED FROM NOTIFY
simulated function AngryScreen()
{
	Mesh.SetMaterial(ScreenID,Screen_Angry);
}

simulated function IdleScreen()
{
	Mesh.SetMaterial(ScreenID,Screen_Idle);
}

simulated function SightScreen()
{
	Mesh.SetMaterial(ScreenID,Screen_Sight);
}

simulated function PainScreen()
{
	Mesh.SetMaterial(ScreenID,Screen_Pain);
}

DefaultProperties
{
	TorsoName=Bruiser
	ShakeDamage=100
	ShakeDistance=1000
	
	// SCREEN TEX
	Screen_Angry = MaterialInstanceConstant'Doom3Monsters.Bruiser.screen_mic_angry'
	Screen_Idle = MaterialInstanceConstant'Doom3Monsters.Bruiser.screen_mic_idle'
	Screen_Sight = MaterialInstanceConstant'Doom3Monsters.Bruiser.screen_mic_sight'
	Screen_Pain = MaterialInstanceConstant'Doom3Monsters.Bruiser.screen_mic_pain'
	
	ScreenID = 2
	
    Begin Object Name=CollisionCylinder
        CollisionHeight=+55.000000
		CollisionRadius=+55.000000
		bDrawBoundingBox=true
    End Object
	
	Mass=2000

	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Bruiser.bruiser_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Bruiser.bruiser_anims'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Bruiser.bruiser_mesh_Physics'
		PhysicsWeight=0.0
    End Object
    Mesh=MainMesh

    GroundSpeed=150.0

	PainSoundChance=0.5

	FootstepSound=SoundCue'Doom3Monsters.Bruiser.VP.bruiser_fs_cue'

	PainSound=SoundCue'Doom3Monsters.Bruiser.VP.bruiser_pain_cue'

	SightSound=SoundCue'Doom3Monsters.Bruiser.VP.bruiser_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Bruiser.VP.bruiser_death_cue'
	AttackSound=None
	FireSound=SoundCue'Doom3Monsters.Bruiser.VP.bruiser_fire_cue'
	ChatterSound=SoundCue'Doom3Monsters.Bruiser.VP.bruiser_chatter_cue'
	IdleSound=SoundCue'Doom3Monsters.Bruiser.VP.bruiser_chatter_cue'
	
	TipBoneLeft=sock_lgun
	TipBoneRight=sock_rgun
	TipBone=sock_rgun

	bHasMelee=true
	PunchDamage=45
	AttackDistance=150

	bHasRanged=true
	MissileClass=Class'BruiserBall'
	RangedAttackDistance=2500
	RangedAttackAnims(0)=RangedAttack1
	RangedAttackAnims(1)=RangedAttack2
	// RangedAttackAnims(2)=RangedAttack3

	// Bruiser walks while attacking
	bWalkingAttack=true
	bWalkingRanged=true

	MeleeAttackAnims(0)=Attack1
	MeleeAttackAnims(1)=Attack2

	Health=750

	RunningAnim=Walk

	SightAnims(0)=Sight
	
	MonsterName="Bruiser"
}
