//--DOOM 3 SABAOTH
//------------------------------------------------------------------
Class Sabaoth extends ToxikkMonster;

var					array<Name>				RightGears, LeftGears;
var					AudioComponent			TreadComponent;
var					Rotator					LeftRot, RightRot;
var					float					TreadRotRate;
var					float					TreadSpeed;
var					bool					bTreadMoving;

replication
{
	if (bNetDirty || bNetInitial)
		bTreadMoving;
}

simulated function StartTreads()
{
	TreadComponent.Play();
}

simulated function StopTreads()
{
	TreadComponent.Stop();
}

simulated function Tick(Float Delta)
{
	super.Tick(Delta);
	
	if (ROLE == ROLE_Authority)
	{
		// If we're moving
		if (VSize(Velocity) >= TreadSpeed)
		{
			if (!bTreadMoving)
			{
				bTreadMoving=true;
				StartTreads();
			}
		}
		// Else
		else
		{
			if (bTreadMoving)
			{
				bTreadMoving=false;
				StopTreads();
			}
		}
	}
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		TurnTreads();
	}
}

simulated function TurnTreads()
{
	if (bTreadMoving)
	{
		LeftRot.Yaw -= TreadRotRate;
		RightRot.Yaw += TreadRotRate;
	}
}

DefaultProperties
{
	TreadRotRate=200
	
	TreadSpeed=25
	
	// Gears that turn to the right
	RightGears(0)=gears_12
	RightGears(1)=gears_14
	RightGears(2)=gears_16
	RightGears(3)=gears_18
	RightGears(4)=gears_20
	RightGears(5)=gears_2
	RightGears(6)=gears_4
	RightGears(7)=gears_6
	RightGears(8)=gears_8
	RightGears(9)=gears_10
	
	// Gears that turn to the left
	LeftGears(0)=gears_1
	LeftGears(1)=gears_3
	LeftGears(2)=gears_5
	LeftGears(3)=gears_7
	LeftGears(4)=gears_9
	LeftGears(5)=gears_11
	LeftGears(6)=gears_13
	LeftGears(7)=gears_15
	LeftGears(8)=gears_17
	LeftGears(9)=gears_19
	
	ShakeDamage=75
	ShakeDistance=1500
	TorsoName=Bruiser
	
	// Stop()
	// Play()
	Begin Object Name=TComponent Class=AudioComponent
		SoundCue=SoundCue'Doom3Monsters.Sabaoth.VP.sab_walk_cue'
		bAutoPlay=false
	End Object
	TreadComponent=TComponent
	Components.Add(TComponent)

    Begin Object Name=CollisionCylinder
        CollisionHeight=+60.000000
		CollisionRadius=+80.000000
		bDrawBoundingBox=true
    End Object

	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Sabaoth.sabaoth_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Sabaoth.sabaoth_anims'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Sabaoth.sabaoth_mesh_Physics'
		PhysicsWeight=0.0
		Translation=(Z=15.0)
    End Object
    Mesh=MainMesh

	// How fast we run
    GroundSpeed=150.0

	PainSoundChance=0.5
	
	FootstepSound=None

	PainSound=None
	
	SightSound=SoundCue'Doom3Monsters.Sabaoth.VP.sab_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Sabaoth.VP.sab_death_cue'
	AttackSound=None
	FireSound=SoundCue'Doom3Monsters.Sabaoth.VP.bfg_fire_cue'
	ChatterSound=SoundCue'Doom3Monsters.Sabaoth.VP.sab_taunt_cue'
	IdleSound=SoundCue'Doom3Monsters.Sabaoth.VP.sab_taunt_cue'
	
	TipBoneLeft=sock_lgun
	TipBoneRight=sock_lgun
	TipBone=sock_lgun

	bHasMelee=true
	MeleeAttackAnims(0)=Attack2
	PunchDamage=45

	bHasRanged=true
	MissileClass=Class'SabaothBall'
	RangedDelay=0.5
	AttackDistance=150
	RangedAttackDistance=2500
	RangedAttackAnims(0)=Attack1

	Health=2500

	RunningAnim=Travel
	
	SightAnims(0)=Sight
	
	Mass=2000
	
	MonsterName = "Sabaoth"
}
