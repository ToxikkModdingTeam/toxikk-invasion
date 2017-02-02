//--DOOM 3 FAT ZOMBIE
//------------------------------------------------------------------
Class FatZombie extends ToxikkMonster;

// Mostly cosmetic variables
var() repnotify			bool								bDecayed, bHasWrench;
var()					MaterialInstanceConstant			InvisoTex, DecayTex, WrenchTex, ZombieTex;
var()					int									DecayID, WrenchID, NormalID;
var()					array<Name>							WalkingAnims;

replication
{
	if (bNetDirty || bNetInitial)
		bDecayed, bHasWrench;
}

// Decide if we're decayed and if we have a wrench
simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	
	// Set cosmetics server-side, that way all players can see and it's not unsync'd
	if (Role == ROLE_Authority)
	{
		// Wrench?
		if (FRand() >= 0.5)
			bHasWrench=true;
			
		// Show intestines?
		if (FRand() >= 0.5)
			bDecayed=true;
			
		if (WorldInfo.NetMode == NM_Standalone)
		{
			ControlIntestines(bDecayed);
			ControlWrench(bHasWrench);
		}
	}
}

// If our cosmetics vars change, update cosmetics
simulated event ReplicatedEvent(name VarName)
{
	super.ReplicatedEvent(VarName);
	
	// Show or hide intestines
	if (VarName == 'bDecayed')
		ControlIntestines(bDecayed);
		
	// Show or hide monkey wrench
	if (VarName == 'bHasWrench')
		ControlWrench(bHasWrench);
}

// Intestines
simulated function ControlIntestines(bool bShow)
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		// Show intestines
		if (bShow)
		{
			Mesh.SetMaterial(NormalID,InvisoTex);
			Mesh.SetMaterial(DecayID,ZombieTex);
		}
		// Hide intestines
		else
		{
			Mesh.SetMaterial(NormalID,ZombieTex);
			Mesh.SetMaterial(DecayID,InvisoTex);
		}
	}
}

// Monkeywrench
simulated function ControlWrench(bool bShow)
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (bShow)
			Mesh.SetMaterial(WrenchID,WrenchTex);
		else
			Mesh.SetMaterial(WrenchID,InvisoTex);
	}
}

DefaultProperties
{
	// Torso profile name
	TorsoName=Default
	
	// Invisible, wrench, zombie
	InvisoTex=MaterialInstanceConstant'Doom3Monsters.doom3_mic_invis'
	WrenchTex=MaterialInstanceConstant'Doom3Monsters.Fatty.monkeywrench_mic'
	ZombieTex=MaterialInstanceConstant'Doom3Monsters.Fatty.fattyzombie_mic'
	
	// Normal texture, wrench texture, intestined texture
	NormalID=0
	WrenchID=1
	DecayID=2
	
	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Fatty.fatty_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Fatty.fattyzombie_anims'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Fatty.fatty_ragdoll'
		PhysicsWeight=0.0
		Translation=(Z=-2.0)
    End Object
    Mesh=MainMesh

	// How fast we run
    GroundSpeed=125.0

	PainSoundChance=0.75
	
	// Sounds
	FootstepSound=SoundCue'Doom3Monsters.Fatty.VP.fatty_step_cue'
	PainSound=SoundCue'Doom3Monsters.Fatty.VP.fatty_pain_cue'
	SightSound=SoundCue'Doom3Monsters.Fatty.VP.fatty_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Fatty.VP.fatty_death_cue'
	AttackSound=SoundCue'Doom3Monsters.Fatty.VP.fatty_attack_cue'
	FireSound=None
	ChatterSound=SoundCue'Doom3Monsters.Fatty.VP.fatty_chatter_cue'
	IdleSound=SoundCue'Doom3Monsters.Fatty.VP.fatty_idle_cue'
		
	bHasMelee=true
	bHasRanged=false
	bHasLunge=false

	MeleeAttackAnims(0)=MeleeAttack01
	MeleeAttackAnims(1)=MeleeAttack02
	MeleeAttackAnims(2)=MeleeAttack03
	MeleeAttackAnims(3)=MeleeAttack04
	
	PunchDamage=15
	
	Health=200
	
	AttackDistance=80

	// Walk anims
	RunningAnim=Walk01
	WalkingAnims(0)=Walk01
	WalkingAnims(1)=Walk02
	WalkingAnims(2)=Walk03
	WalkingAnims(3)=Walk04
	WalkingAnims(4)=Walk05
	
	HeadBone=head
	HeadRadius=16.0
	
	SightAnims(0)=Sight
	
	MonsterName="Fat Zombie"
	
	Mass=1000
}
