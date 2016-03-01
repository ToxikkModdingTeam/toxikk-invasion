//--DOOM 3 HELL KNIGHT
//------------------------------------------------------------------
Class InvulHunter extends ToxikkMonster;

//------------------------------------------------------------------
var()					ParticleSystemComponent			HandFireComponent;
var()					Name							HandFireBone;
var()					SoundCue						FireballCue;

var() repnotify			bool							bInvincible;
var()					ParticleSystem					StompSystem, SummonSystem;

var()					name							StompAnim, InvulAnim, ZapParameter, StompSocket;
var()					float							NormalZap, InvulZap;

// How intense our zap is (Clientside)
var()					float							ZapAlpha;
var()					MaterialInstanceConstant		ZapMIC;
var()					int								ZapID;
var()					float							StompScale, SummonScale;
//------------------------------------------------------------------

replication
{
	if (bNetDirty || bNetInitial)
		bInvincible;
}

simulated function Tick(float Delta)
{
	ControlZapAlpha(Delta);
	Super.Tick(Delta);
}

// CONTROL THE ZAP INTENSITY
/*
simulated function ControlZapAlpha(float Delta)
{
	// Are we invincible?
	if (bInvincible)
	{
		if (ZapAlpha < InvulZap)
			ZapAlpha += Delta;
	}
	// Normal
	else
	{
		if (ZapAlpha > NormalZap)
			ZapAlpha -= Delta;
	}
}
*/

simulated function ControlZapAlpha(float Delta)
{
	if (bInvincible && Health > 0)
		ZapAlpha=InvulZap;
	else
		ZapAlpha=NormalZap;
	
	ZapMIC.SetScalarParameterValue(ZapParameter,ZapAlpha);
}

// Only stomp serverside
simulated function ShockStomp()
{
	local Rotator R;
	local ParticleSystemComponent PSC;
	local Vector HL;
	
	if (ROLE == Role_Authority)
		ToggleInvul(false);
		
	PlaySound(FootstepSound,TRUE);
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		HL =  Mesh.GetBoneLocation('origin');
		PSC = WorldInfo.MyEmitterPool.SpawnEmitter(StompSystem, HL, R, None);
		PSC.SetScale(StompScale);
	}
}

// Summon serverside
simulated function DoSummon()
{
	local Rotator R;
	local ParticleSystemComponent PSC;
	local Vector HL;
	
	if (ROLE == Role_Authority)
		ToggleInvul(true);
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
			HL =  Mesh.GetBoneLocation('origin');
			PSC = WorldInfo.MyEmitterPool.SpawnEmitter(SummonSystem, HL, R, None);
			PSC.SetScale(StompScale);
	}
}

reliable server function ToggleInvul(bool bInvul)
{
	bInvincible = bInvul;
	
	// If we're doing the summon, play a sound
	if (bInvul)
		PlaySound(SightSound,TRUE);
}

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

// Here, we spawn some particle effects
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	
	Mesh.AttachComponentToSocket(HandFireComponent, HandFireBone);
	
	// Grab MIC
	if (WorldInfo.NetMode != NM_DedicatedServer)
		ZapMIC = Mesh.CreateAndSetMaterialInstanceConstant(ZapID);
}

// Don't take damage if we're invincible
event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	// Do certain things here if the player tries to hurt us
	if (bInvincible)
		return;
	else
		super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

simulated function PlayPrefire()
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
		PlaySound(FireballCue,TRUE);
}

DefaultProperties
{
	bInvincible=false
	
	StompSystem=ParticleSystem'Doom3Monsters.InvulHunter.invul_stomp_particles'
	SummonSystem=ParticleSystem'Doom3Monsters.InvulHunter.invul_summon_particles'
	ShakeDamage=300
	ShakeDistance=1500
	
	ZapAlpha=0.0
	ZapID=1
	
	TorsoName=Bruiser
	
	// May or may not use
	HandFireBone=sock_rgun
	
    Begin Object Name=CollisionCylinder
        CollisionHeight=+70.000000
		CollisionRadius=+65.000000
		bDrawBoundingBox=true
    End Object
	
	// HAND FIRE
	Begin Object Class=ParticleSystemComponent Name=HandFire
		Template=ParticleSystem'Doom3Monsters.InvulHunter.invul_ball'
		bAutoActivate=false
		Scale=2.5
		End Object
		HandFireComponent = HandFire;
	Components.Add(HandFire);
	
	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.InvulHunter.invul_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.InvulHunter.invul_anims'
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
		Translation=(Z=-16.0)
    End Object
    Mesh=MainMesh

	// How fast we run
    GroundSpeed=150.0

	PainSoundChance=0.5
	
	FootstepSound=SoundCue'Doom3Monsters.InvulHunter.VP.invul_step_cue'
	FireballCue=SoundCue'Doom3Monsters.InvulHunter.VP.invul_prefire_cue'
	
	PainSound=SoundCue'Doom3Monsters.InvulHunter.VP.invul_pain_cue'
	
	SightSound=SoundCue'Doom3Monsters.InvulHunter.VP.invul_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.InvulHunter.VP.invul_death_cue'
	AttackSound=None
	FireSound=None
	ChatterSound=SoundCue'Doom3Monsters.InvulHunter.VP.invul_growl_cue'
	IdleSound=SoundCue'Doom3Monsters.InvulHunter.VP.invul_growl_cue'
	
	TipBoneLeft=sock_rgun
	TipBoneRight=sock_rgun
	TipBone=sock_rgun
	
	ControllerClass=Class'InvulController'
	
	MissileClass=Class'InvulBall'
	
	bHasMelee=true
	bHasRanged=true

	MeleeAttackAnims(0)=Attack2
	MeleeAttackAnims(1)=Attack3
	
	PunchDamage=75
	
	Health=2500
	
	AttackDistance=150
	RangedAttackDistance=2500
	
	RangedAttackAnims(0)=Attack1
	RangedAttackAnims(1)=ShockAttack
	
	// Controls for the external zap filter
	ZapParameter=ZapIntensity
	NormalZap=0.02
	InvulZap=0.75
	
	StompSocket=sock_stomp
	StompAnim=ShockWave
	InvulAnim=Summon
	
	RunningAnim=Walk
	
	SightAnims(0)=Summon
	
	StompScale=5.0
	SummonScale=5.0
	SightChance=0.0
	
	Mass=10000
}
