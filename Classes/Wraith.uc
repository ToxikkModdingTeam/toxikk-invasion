//--THE WRAITH
//------------------------------------------------------------------
Class Wraith extends ToxikkMonster;

// Particle system to be used when we teleport, should be a beam
var				ParticleSystem			TeleportFXTemplate;
var				SoundCue				TeleportInSound, TeleportOutSound;

// Spawn a decorative beam from one spot to another, only for instant teleports
unreliable client function TeleportBeam(vector StartLoc, vector EndLoc)
{
	local ParticleSystemComponent E;
	local TemporarySound TS;

	E = WorldInfo.MyEmitterPool.SpawnEmitter(TeleportFXTemplate, StartLoc);
	E.SetVectorParameter('BeamEnd', EndLoc);
	E.SetDepthPriorityGroup(SDPG_World);

	TS = Spawn(Class'TemporarySound',,,StartLoc);
	TS.PlaySound(TeleportOutSound);
	TS.Destroy();
	
	TS = Spawn(Class'TemporarySound',,,EndLoc);
	TS.PlaySound(TeleportInSound);
	TS.Destroy();
}

// Called serverside for delayed teleports
simulated function SetCloaked(bool bCloaked)
{
	// SetHidden will pretty much hide the monster anyway
	// SetCloaked(bCloaked);
	
	SetHidden(bCloaked);
	
	ControlAnimLock(bCloaked);
	
	if (bCloaked)
		SetCollision(false,false);
	else
		SetCollision(true,true);
}

reliable client function ControlAnimLock(bool bLock)
{
	if (Health <= 0)
		return;
		
	if (bLock)
		DeathBlender.SetBlendTarget(1.0,0.0);
	else
		DeathBlender.SetBlendTarget(0.0,0.0);
}

// Clientside effects, used for delayed cloaks
/*
reliable client function SetCloaked(bool bCloaked)
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (bCloaked)
		{
			Mesh.CastShadow = false;
			Mesh.bCastDynamicShadow = false;
			ReattachMesh();
			Mesh.SetHidden(true);
		}
		else
		{
			UpdateShadowSettings(!class'Engine'.static.IsSplitScreen() && class'UTPlayerController'.default.PawnShadowMode == SHADOW_All);
			Mesh.SetHidden(false);
		}
	}
}
*/

// From CRZPawn
/*
simulated function ReattachMesh()
{
	Class'Cruzade.CRZPawn'.Static.DetachMeshComponentsOnActor(self,AllComponents);
	Class'Cruzade.CRZPawn'.Static.AttachMeshComponentsOnActor(self,AllComponents);
}
*/

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
	
	Mass=300
	
	MonsterName = "Wraith"
}
