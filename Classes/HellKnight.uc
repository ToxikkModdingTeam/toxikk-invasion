//--DOOM 3 HELL KNIGHT
//------------------------------------------------------------------
Class HellKnight extends ToxikkMonster;

var()		ParticleSystemComponent			HandFireComponent;
var()		Name							HandFireBone;
var()		SoundCue						FireballCue, QuietFootstepSound;

// Show the fireball effect
simulated function CreateFireball()
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		HandFireComponent.ActivateSystem();
		PlaySound(FireballCue,TRUE);
	}
}

simulated function ShootProjectile()
{
	HandFireComponent.DeActivateSystem();
	super.ShootProjectile();
}

// Animnotify, play a footstep sound
function QuietFootstep()
{
	if (Health > 0 && WorldInfo.NetMode != NM_DedicatedServer)
		PlaySound(QuietFootstepSound, TRUE);
}

// Here, we spawn some particle effects
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	Mesh.AttachComponentToSocket(HandFireComponent, HandFireBone);
}

DefaultProperties
{
	ShakeDamage=100
	ShakeDistance=1000
	
	TorsoName=Bruiser
	HandFireBone=sock_rgun
	QuietFootstepSound=SoundCue'Doom3Monsters.HellKnight.VP.hk_quietstep_cue'
	
    Begin Object Name=CollisionCylinder
        CollisionHeight=+60.000000
		CollisionRadius=+55.000000
		bDrawBoundingBox=true
    End Object
	
	// HAND FIRE
	Begin Object Class=ParticleSystemComponent Name=HandFire
		Template=ParticleSystem'Doom3Monsters.HellKnight.hk_hand_effect'
		bAutoActivate=false
		Scale=2.5
		End Object
		HandFireComponent = HandFire;
	Components.Add(HandFire);
	
	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.HellKnight.hellknight_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.HellKnight.hellknight_anims'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.HellKnight.hellknight_mesh_Physics'
		PhysicsWeight=0.0
		Translation=(Z=-16.0)
    End Object
    Mesh=MainMesh

	// How fast we run
    GroundSpeed=150.0

	PainSoundChance=0.5
	
	FootstepSound=SoundCue'Doom3Monsters.HellKnight.VP.hk_step_cue'
	FireballCue=SoundCue'Doom3Monsters.HellKnight.VP.hk_fireball_Cue'
	
	PainSound=SoundCue'Doom3Monsters.HellKnight.VP.hk_pain_cue'
	
	SightSound=SoundCue'Doom3Monsters.HellKnight.VP.hk_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.HellKnight.VP.hk_die_cue'
	AttackSound=None
	FireSound=None
	ChatterSound=SoundCue'Doom3Monsters.HellKnight.VP.hk_chatter_cue'
	IdleSound=SoundCue'Doom3Monsters.HellKnight.VP.hk_chatter_cue'
	
	TipBoneLeft=sock_rgun
	TipBoneRight=sock_rgun
	TipBone=sock_rgun
	
	MissileClass=Class'HellknightBall'
	
	bHasMelee=true
	bHasRanged=true

	MeleeAttackAnims(0)=Attack1
	MeleeAttackAnims(1)=Attack2
	MeleeAttackAnims(2)=Attack3
	MeleeAttackAnims(3)=Attack4
	
	// Anims that we should perform root motions on
	RootAnims(0)=RangedAttack_RM
	// RootAnims(1)=Attack2
	
	PunchDamage=45
	
	Health=750
	
	AttackDistance=150
	RangedAttackDistance=2500
	
	RangedAttackAnims(0)=RangedAttack_RM
	
	RunningAnim=Walk
	
	SightAnims(0)=Roar
	
	Mass=2000
	
	MonsterName="Hell Knight"
	
	HeadBone=head
	NeckBone=neck
	HeadRadius=16.0
	SpewRotator=(Pitch=16384,Roll=-16384)
	HeadHealth = 400
	
	Begin Object Name=Stumped
		Scale=5
	End Object
	
	Begin Object Name=SpewSpew
		Scale=2.0
	End Object
}
