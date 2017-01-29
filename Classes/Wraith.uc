//--THE WRAITH
//------------------------------------------------------------------
Class Wraith extends ToxikkMonster;

// Particle system to be used when we teleport, should be a beam
var				ParticleSystem			TeleportFXTemplate;
var				SoundCue				TeleportInSound, TeleportOutSound;

var RepNotify bool bCloaked;

Replication
{
	if ( bNetDirty )
		bCloaked;
}

// Spawn a decorative beam from one spot to another, only for instant teleports
function TeleportBeam(vector StartLoc, vector EndLoc)
{
	local ParticleSystemComponent E;

	E = WorldInfo.MyEmitterPool.SpawnEmitter(TeleportFXTemplate, StartLoc);
	E.SetVectorParameter('BeamEnd', EndLoc);
	E.SetDepthPriorityGroup(SDPG_World);

	PlaySound(TeleportOutSound, false,,, StartLoc);
	PlaySound(TeleportInSound, false,,, EndLoc);
}

// Delayed teleports
simulated function SetCloaked(bool NewCloaked)
{
	bCloaked = NewCloaked;
	if ( Role == ROLE_Authority )
	{
		SetHidden(bCloaked);
		SetCollision(!bCloaked, !bCloaked);
	}

	if ( WorldInfo.NetMode != NM_DedicatedServer )
	{
		if ( Health > 0 )
			DeathBlender.SetBlendTarget(bCloaked ? 1.0 : 0.0, 0.0);

		PlaySound(bCloaked ? TeleportInSound : TeleportOutSound, true);
	}
}

simulated event ReplicatedEvent(Name VarName)
{
	if ( VarName == 'bCloaked' )
		SetCloaked(bCloaked);
	else
		Super.ReplicatedEvent(VarName);
}


DefaultProperties
{
    Begin Object Name=CollisionCylinder
        CollisionHeight=+40.000000
		CollisionRadius=+36.000000
		bDrawBoundingBox=true
    End Object
	
	TeleportFXTemplate=ParticleSystem'Doom3Monsters.Wraith.FX.wraith_teleport_fx'

	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Wraith.tx_wraith'
        AnimSets(0)=AnimSet'Doom3Monsters.Wraith.tx_wraith_anims'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Wraith.tx_wraith_physics'
		PhysicsWeight=0.0
    End Object
    Mesh=MainMesh

	// How fast we run
    GroundSpeed=260.0

	PainSoundChance=0.5
	
	FootstepSound=SoundCue'Doom3Monsters.Wraith.VP.wraith_footstep_cue'
	PainSound=SoundCue'Doom3Monsters.Wraith.VP.wraith_pain_cue'
	SightSound=SoundCue'Doom3Monsters.Wraith.VP.wraith_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Wraith.VP.wraith_death_cue'
	AttackSound=None
	ChatterSound=None
	IdleSound=SoundCue'Doom3Monsters.Wraith.VP.wraith_idle_cue'
	TeleportInSound=SoundCue'Doom3Monsters.Wraith.VP.wraith_telein_cue'
	TeleportOutSound=SoundCue'Doom3Monsters.Wraith.VP.wraith_teleout_cue'
	
	bHasMelee=true

	MeleeAttackAnims(0)=Attack1
	MeleeAttackAnims(1)=Attack2
	MeleeAttackAnims(2)=Attack3
	
	PunchDamage=30
	
	Health=250
	
	ControllerClass=Class'WraithController'
	
	AttackDistance=150
	
	RunningAnim=Run
	
	SightAnims(0)=Sight
	
	bUseAimOffset=false
	
	Mass=500
	
	MonsterName = "Wraith"
}
