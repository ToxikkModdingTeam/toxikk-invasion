//--DOOM 3 IMP
//------------------------------------------------------------------
Class Imp extends ToxikkMonster;

var()		ParticleSystemComponent			HandFireComponent;
var()		Name							HandFireBone;
var()		SoundCue						FireballCue;

// Show the fireball effect
simulated function CreateFireball()
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		HandFireComponent.ActivateSystem();
		PlaySound(FireballCue,TRUE);
	}
}

simulated function ShootProjectileRight()
{
	HandFireComponent.DeActivateSystem();
	super.ShootProjectile();
}

// Here, we spawn some particle effects
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	Mesh.AttachComponentToSocket(HandFireComponent, HandFireBone);
}

DefaultProperties
{
	TorsoName=Cyberdemon
	HandFireBone=sock_rgun
	
	CrawlChance=0.35

	// HAND FIRE
	Begin Object Class=ParticleSystemComponent Name=HandFire
		Template=ParticleSystem'Doom3Monsters.Imp.Particles.imp_fireball_particles'
		bAutoActivate=false
		Scale=1.5
		End Object
	HandFireComponent = HandFire;
	Components.Add(HandFire);
	
	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Imp.imp_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Imp.imp_anims'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Imp.imp_mesh_Physics'
		PhysicsWeight=0.0
		Translation=(Z=-1.0)
    End Object
    Mesh=MainMesh

	// How fast we run
    GroundSpeed=175.0

	PainSoundChance=0.75
	
	FootstepSound=SoundCue'Doom3Monsters.Imp.VP.imp_step_cue'
	FireballCue=SoundCue'Doom3Monsters.Imp.VP.imp_fireball_cue'
	
	PainSound=SoundCue'Doom3Monsters.Imp.VP.imp_pain_cue'
	
	SightSound=SoundCue'Doom3Monsters.Imp.VP.imp_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Imp.VP.imp_death_cue'
	AttackSound=None
	FireSound=SoundCue'Doom3Monsters.Imp.VP.imp_firethrow_cue'
	ChatterSound=SoundCue'Doom3Monsters.Imp.VP.imp_chatter_cue'
	IdleSound=SoundCue'Doom3Monsters.Imp.VP.imp_breathe_cue'
	
	TipBoneLeft=sock_rgun
	TipBoneRight=sock_rgun
	TipBone=sock_rgun
	
	MissileClass=Class'ImpBall'
	
	bHasMelee=true
	bHasRanged=true
	bHasLunge=true
	bLungeIfCrouched=true

	MeleeAttackAnims(0)=Slash1
	MeleeAttackAnims(1)=Slash2
	MeleeAttackAnims(2)=Slash3
	
	LungeStartAnim=JumpStart
	LungeMidAnim=JumpMid3
	LungeEndAnim=JumpEnd
	LungeSpeed=2000.0
	LungeDamage=30
	LungeChance=0.5
	
	// Anims that we should perform root motions on
	RootAnims(0)=RangedAttack_RM
	// RootAnims(1)=Attack2
	
	PunchDamage=15
	
	Health=200
	
	AttackDistance=80
	RangedAttackDistance=2000
	
	RangedAttackAnims(0)=RangedAttack2
	RangedAttackAnims(1)=RangedAttack3
	RangedAttackAnims(2)=RangedAttack4
	RangedAttackAnims(3)=RangedAttack5
	CrouchedRangedAnims(0)=RangedAttack1
	
	RunningAnim=Walk
	
	SightAnims(0)=Sight
	
	MonsterName = "Imp"
	
	Mass=1000
}
