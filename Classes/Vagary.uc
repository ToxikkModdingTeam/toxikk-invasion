//--DOOM 3 VAGARY
//------------------------------------------------------------------
Class Vagary extends ToxikkMonster;

// Number of shards to spawn
var()							int						NumShards;
var()							float					ShardSpawnChance;
var()							array<VagaryShard>		Shards;
var()							float					ShardCheckRadius;
var()							float					ShardTossSpeed, ShardZAdd;

// Locked onto a shard, get ready to throw it
var()							VagaryShard				LockedShard;
//------------------------------------------------------------------

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	
	// Spawn some shards and shit for us to throw around
	if (Role == ROLE_Authority)
		SpawnShards();
}

simulated function Destroyed()
{
	if (Role == ROLE_Authority)
		DestroyShards();
}

simulated function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
  if (Super.Died(Killer, DamageType, HitLocation))
  {
	if (Role == Role_Authority)
		DestroyShards();
  }
  
  return true;
}

// Destroy all of our shards
simulated function DestroyShards()
{
	local int l;
	
	for (l=0; l<Shards.Length; l++)
	{
		if (Shards[l] != None)
			Shards[l].Destroy();
	}
}

// Spawn the shards around the map (Serverside)
simulated function SpawnShards()
{
	local int l;
	local NavigationPoint NP;
	local VagaryShard VS;
	
	DestroyShards();
	Shards.Length=0;
	
	// Spawn a shard for each count
	for (l=0; l<NumShards; l++)
	{
		VS = None;
		
		do
		{
			ForEach DynamicActors(Class'NavigationPoint',NP)
			{
				if (FRand() >= 1.0-ShardSpawnChance)
				{
					VS = Spawn(Class'VagaryShard',,,NP.Location);
					Shards.AddItem(VS);
					break;
				}
			}
		} until (VS != None);
	}
}

// If there's a shard within a certain radius
function bool CanUseShards()
{
	local int l;
	local bool bFound;
	
	for (l=0; l<Shards.Length; l++)
	{
		if (VSize(Shards[l].Location - Location) <= ShardCheckRadius)
			bFound=true;
	}
	
	return bFound;
}

function VagaryShard PickRandomShard()
{
	local int l;

	l = Rand(Shards.Length);
	
	if (Shards[l] != None)
		return Shards[l];
	else
		Return None;
}

// Actually toss a shard toward the player
simulated function TossShard(VagaryShard VS, Pawn ShardTarget)
{
	local vector tmp_V;
	
	if (ShardTarget == None)
		return;
		
	VS.bIsRising=false;
	
	tmp_V = Normal(ShardTarget.Location-VS.Location) * ShardTossSpeed;
	tmp_V.Z += ShardZAdd;
	VS.Velocity = tmp_V;
	VS.SetPhysics(PHYS_Falling);
}

// Called from notify
simulated function GrabBall()
{
	if (Role == ROLE_Authority)
	{
		LockedShard = PickRandomShard();
		if (LockedShard != None)
			LockedShard.Rise();
	}
}

simulated function ShootProjectile()
{
	if (Role == ROLE_Authority)
	{
		PlaySound(FireSound,TRUE);
		if (LockedShard != None && Pawn(ToxikkMonsterController(Controller).Target) != None)
			TossShard(LockedShard,Pawn(ToxikkMonsterController(Controller).Target));
	}
}

DefaultProperties
{
	NumShards=15
	TorsoName=Cyberdemon
	// 25% chance of picking a point
	ShardSpawnChance=0.75
	ShardTossSpeed=3000
	ShardZAdd=260
	
	Mass=2500
	Begin Object Name=CollisionCylinder
        CollisionHeight=75.0
		CollisionRadius=100.0
    End Object
	
	ControllerClass=Class'VagaryController'

	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Vagary.vagary_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Vagary.vagary_anims'
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
    GroundSpeed=225.0

	PainSoundChance=0.75
	
	FootstepSound=SoundCue'Doom3Monsters.Vagary.VP.vag_footstep_cue'
	PainSound=SoundCue'Doom3Monsters.Vagary.VP.vag_pain_cue'
	
	SightSound=SoundCue'Doom3Monsters.Vagary.VP.vag_chatter_cue'
	DeathSound=SoundCue'Doom3Monsters.Vagary.VP.vag_death_cue'
	AttackSound=None
	FireSound=SoundCue'Doom3Monsters.Vagary.VP.vag_toss_cue'
	ChatterSound=SoundCue'Doom3Monsters.Vagary.VP.vag_chatter_cue'
	IdleSound=SoundCue'Doom3Monsters.Vagary.VP.vag_idle_cue'
	
	TipBoneLeft=sock_rgun
	TipBoneRight=sock_rgun
	TipBone=sock_rgun
	
	// Technically we don't have a ranged attack
	MissileClass=None
	
	bHasMelee=true
	bHasRanged=true
	bHasLunge=false

	MeleeAttackAnims(0)=Melee1
	
	PunchDamage=25
	
	Health=1500
	
	AttackDistance=120
	RangedAttackDistance=2000
	ShardCheckRadius=1500
	
	RangedAttackAnims(0)=RangedAttack1
	RangedAttackAnims(1)=RangedAttack2
	
	RunningAnim=Walk
	
	SightAnims(0)=Sight
}
