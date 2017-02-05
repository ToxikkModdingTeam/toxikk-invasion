Class LostSoul extends ToxikkMonster_Flying;

var			ParticleSystemComponent				FireComp;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		Mesh.AttachComponentToSocket(FireComp, 'FlameSocket');
	}
}

DefaultProperties
{
    Begin Object Name=CollisionCylinder
        CollisionHeight=25.000000
		CollisionRadius=12.500000
		bDrawBoundingBox=true
    End Object
	
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
	
	AttackDistance=500
	RangedAttackDistance=1000
	
	RunningAnim=Walk
	
	SightAnims(0)=Sight
	
	LungeStartAnim=Charge
	LungeMidAnim=Charge
	LungeEndAnim=Charge
	LungeSpeed=1000.0
	
	LungeDamage=30
	
	// 100 percent, always lunge
	LungeChance=0.0
	// Rotating the trite's torso would be a disaster
	bUseAimOffset=false
	
	MonsterName = "Lost Soul"
}
