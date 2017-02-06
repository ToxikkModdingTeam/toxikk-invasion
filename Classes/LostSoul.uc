Class LostSoul extends ToxikkMonster_Flying;

var			ParticleSystemComponent				FireComp;
var			AudioComponent						AmbComp;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	
	// Attach fire
	if (WorldInfo.NetMode != NM_DedicatedServer)
		Mesh.AttachComponentToSocket(FireComp, 'FlameSocket');
}

simulated function LungeMid(){AmbComp.SoundCue=SoundCue'Doom3Monsters.LostSoul.VP.ls_charge_cue';}
simulated function LungeEnd(){AmbComp.SoundCue=SoundCue'Doom3Monsters.LostSoul.VP.ls_idle_cue';}

function bool Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	if (Super.Died(Killer, DamageType, HitLocation))
	{
		AmbComp.SoundCue = None;
		DetachComponent(AmbComp);
		FireComp.DeactivateSystem();
		SetPhysics(PHYS_Falling);
		return true;
	}
	
	return false;
}

DefaultProperties
{
    Begin Object Name=CollisionCylinder
        CollisionHeight=25.000000
		CollisionRadius=12.500000
		bDrawBoundingBox=true
    End Object
	
	// Ambient sound
	Begin Object Class=AudioComponent Name=AmbientComp
		SoundCue=SoundCue'Doom3Monsters.LostSoul.VP.ls_idle_cue'
		VolumeMultiplier=0.5
		bAutoPlay=true
	End Object
	AmbComp = AmbientComp
	Components.Add(AmbientComp)
	
	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.LostSoul.tx_lostsoul'
        AnimSets(0)=AnimSet'Doom3Monsters.LostSoul.tx_lostsoul_anims'
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
		//PhysicsAsset=PhysicsAsset'Doom3Monsters.Trite.trite_mesh_Physics'
		PhysicsWeight=0.0
    End Object
    Mesh=MainMesh
	
	Begin Object Class=ParticleSystemComponent Name=MouthFire
		Template=ParticleSystem'Doom3Monsters.LostSoul.FX.lostsoul_flametrail'
		bAutoActivate=true
	End Object
	Components.Add(MouthFire)
	
	FireComp = MouthFire

	// How fast we run
    GroundSpeed = 225.0
	AirSpeed = 225.0

	PainSoundChance=0.5
	
	PainSound=SoundCue'Doom3Monsters.LostSoul.VP.ls_pain_cue'
	
	SightSound=SoundCue'Doom3Monsters.LostSoul.VP.ls_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.LostSoul.VP.ls_death_cue'
	AttackSound=SoundCue'Doom3Monsters.LostSoul.VP.ls_attack_cue'
	ChatterSound=SoundCue'Doom3Monsters.LostSoul.VP.ls_chatter_cue'
	IdleSound=SoundCue'Doom3Monsters.LostSoul.VP.ls_chatter_cue'
	

	bHasMelee=true
	bHasRanged=true
	bHasLunge=true

	MeleeAttackAnims(0)=Attack1
	MeleeAttackAnims(1)=Attack2
	
	PunchDamage=15
	
	Health=50
	
	AttackDistance=64
	RangedAttackDistance=1000
	
	RunningAnim=Walk
	
	LungeZBoost = 0
	
	SightAnims(0)=Sight
	
	LungeStartAnim=Charge
	LungeMidAnim=Charge
	LungeEndAnim=Charge
	LungeSpeed=1000.0
	
	LungeDamage=30
	bUseLungeStart = false
	bUseLungeEnd = false
	bContinuousLunge = true
	
	// 100 percent, always lunge
	LungeChance=0.0
	// Rotating the trite's torso would be a disaster
	bUseAimOffset=false
	
	MonsterName = "Lost Soul"
	
	LungeCutoffTime = 3.0
}
