//--DOOM 3 MANCUBUS
//------------------------------------------------------------------
Class Cyberdemon extends ToxikkMonster;

//--FOR PARTICLE EFFECTS-----------------------------------
var			name							BackBone1, BackBone2, BackBone3;
var			name							RFootBone, LFootBone;
var			name							MouthBone;

// cyberdemon_stomp_fx
var	()		ParticleSystemComponent			MouthFireComponent, LDustComponent, RDustComponent;
//---------------------------------------------------------

// FOOTSTEP PARTICLES WILL GO HERE, SCREEN SHAKE TOO
// Notify, this is client anyway
simulated function PlayFootstepLeft()
{
	if (Health > 0)
	{
		PlayFootstep();
		LDustComponent.ActivateSystem();
		// FootstepSmoke(LFootBone);
	}
}

simulated function PlayFootstepRight()
{
	if (Health > 0)
	{
		PlayFootstep();
		RDustComponent.ActivateSystem();
		// FootstepSmoke(RFootBone);
	}
}

// Clientside footstep smoke
simulated function FootstepSmoke(name BoneName)
{
	local rotator R, FR;
	local vector FP;
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		Mesh.GetSocketWorldLocationAndRotation(BoneName, FP, FR, 0);
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Doom3Monsters.Cyberdemon.cyberdemon_stomp_fx', FP, R, None);
	}
}


// Here, we spawn some particle effects
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	Mesh.AttachComponentToSocket(MouthFireComponent, MouthBone);
	Mesh.AttachComponentToSocket(LDustComponent, LFootBone);
	Mesh.AttachComponentToSocket(RDustComponent, RFootBone);
}


DefaultProperties
{
	ShakeDamage=500
	ShakeDistance=1500
	
	// MOUTH FIRE
	Begin Object Class=ParticleSystemComponent Name=MouthFire
		Template=ParticleSystem'Doom3Monsters.Cyberdemon.cyber_mouth_particles'
		bAutoActivate=true
		Rotation=(Yaw=16384)
		End Object
		MouthFireComponent = MouthFire;
	Components.Add(MouthFire);
	
	// DUSTS
	Begin Object Class=ParticleSystemComponent Name=LDust
		Template=ParticleSystem'Doom3Monsters.Cyberdemon.cyberdemon_stomp_fx'
		bAutoActivate=false
		Scale=7.5
		End Object
		LDustComponent = LDust;
	Components.Add(LDust);
	
	Begin Object Class=ParticleSystemComponent Name=RDust
		Template=ParticleSystem'Doom3Monsters.Cyberdemon.cyberdemon_stomp_fx'
		bAutoActivate=false
		Scale=7.5
		End Object
		RDustComponent = RDust;
	Components.Add(RDust);
		
	TorsoName=Cyberdemon
	
/* now set dynamically in SetMonsterAsBoss()
	bIsBossMonster=true
	bForceInitialTarget=true
*/

	FocusBone = part_mouthfire
	BossBone = Hips
	BossVector = (Y=100.0,Z=300.0)
	
	// PARTICLE BONES
	MouthBone = part_mouthfire
	BackBone1 = part_backfire1
	BackBone2 = part_backfire2
	BackBone3 = part_backfire3
	RFootBone = part_rdust
	LFootBone = part_ldust
	
    Begin Object Name=CollisionCylinder
        CollisionHeight=100.00
		CollisionRadius=60.00
		bDrawBoundingBox=true
    End Object

	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Cyberdemon.cyberdemon_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Cyberdemon.cyberdemon_animset'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Cyberdemon.cyberdemon_mesh_Physics'
		PhysicsWeight=0.0
    End Object
    Mesh=MainMesh

	// How fast we run
    GroundSpeed=100.0

	PainSoundChance=0.05
	
	FootstepSound=SoundCue'Doom3Monsters.Cyberdemon.VP.cyber_step_cue'
	
	PainSound=SoundCue'Doom3Monsters.Cyberdemon.VP.cyber_pain_cue'
	
	SightSound=SoundCue'Doom3Monsters.Cyberdemon.VP.cyber_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Cyberdemon.VP.cyber_death_cue'
	AttackSound=SoundCue'Doom3Monsters.Cyberdemon.VP.cyber_fire_cue'
	FireSound=SoundCue'Doom3Monsters.Cyberdemon.VP.cyber_fire_cue'
	ChatterSound=SoundCue'Doom3Monsters.Cyberdemon.VP.cyber_chatter_cue'
	IdleSound=SoundCue'Doom3Monsters.Cyberdemon.VP.cyber_chatter_cue'
	
	TipBoneLeft=sock_rgun
	TipBoneRight=sock_rgun
	TipBone=sock_rgun
	
	MissileClass=Class'CyberdemonMissile'
	
	bHasMelee=false
	bHasRanged=true

	// Used for stomp damage here, instantly kill a player
	PunchDamage=500
	
	Health=3500
	
	AttackDistance=200
	RangedAttackDistance=20000
	
	// 1, 2, or 3 missiles
	RangedAttackAnims(0)=Shot1
	RangedAttackAnims(1)=Shot2
	RangedAttackAnims(2)=Shot3
	
	RunningAnim=Walk
	
	SightAnims(0)=Sight
	
	SightChance=1.0
	
	SightRadius=1.0
	
	Mass=10000
	
	MonsterName="Cyberdemon"
}
