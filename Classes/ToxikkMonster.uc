//--TOXIKK INVASION MONSTER
//------------------------------------------------------------------
Class ToxikkMonster extends Pawn;

var()			LightEnvironmentComponent		LEC;
var()			SkeletalMeshComponent			FakeComponent;

//=============================================================================
//--SOUNDS---------------------------------------------------------------------
// SightSound: Played when the monster finds a target and it's idling
// DeathSound: Played when the monster dies
// FootstepSound: Footstep sounds obviously
// IdleSound: Periodically played in the idle state
// ChatterSound: Same as idle, but when the monster has a target
// PainSound: Called when the monster is hurt
// AttackSound: Done when the monster melees / shoots
// FireSound: Done when monster shoots
//
// PainSoundChance: FRand() must be greater than this to play pain sounds

var()			SoundCue						SightSound, DeathSound, FootstepSound;
var()			SoundCue						IdleSound, ChatterSound, PainSound, AttackSound, FireSound;
var()			float							PainSoundChance;

//--ANIMATIONS-----------------------------------------------------------------
// bHasMelee: Monster has a melee attack
// bHasRanged: Monster has a ranged attack
// bHasLunge: Monster can lunge (imp, trite, etc.)
// bWalkingAttack: Monster continues to walk when meleeing
// bWalkingRanged: Monster continues to walk when doing ranged attack
// MeleeAttackAnims: Animations to play when attacking
// RangedAttackAnims: Animations to play when shooting / ranged
// LungeStartAnim, LungeMidAnim, LungeEndAnim: Lunge animations
// PainAnims: Anims to play when we get hurt
// SightAnims: Anims to play when we get a new target
// RunningAnim: This monster's run anim
//
// AttackDistance: How close we have to be to start attacking melee-wise
// RangedAttackDistance: Distance the monster must be to attack the player with projs
// PunchDamage: How much damage melee attacks do
// LungeDistance: How close the player has to be to lunge
// SightChance: Chance to play sight anim
// LungeChance: Chance to lunge at the player
//
// TipBone, TipBoneLeft, TipBoneRight: Bones / sockets that projectiles / tracers come out of
// RangedDelay: Minimum time between ranged attacks before the next can occur
// LungeSpeed: How much force is applied when we lunge toward the player
// PreRotateModifier: Amount to speed up our rotation rate when we're prepping ranged attacks

// Nodes in the animtree
var() 			AnimNodePlayCustomAnim 			CustomAnimator, WalkSwitch;
var()			Name							RunningAnim;

var()			bool							bHasMelee, bHasRanged, bWalkingAttack, bWalkingRanged, bHasLunge, bIsLunging;
var()			array<Name>						MeleeAttackAnims;
var()			array<Name>						RangedAttackAnims;
var()			array<Name>						SightAnims;

var()			array<Name>						PainAnims;
var()			int								PunchDamage, LungeDamage;
var()			float							AttackDistance, SightChance, RangedAttackDistance, LungeChance, LungeDistance;
var()			Class<Projectile>				MissileClass;
var()           float                           ProjDamageMult;

var()			name							TipBone, TipBoneLeft, TipBoneRight;
var()			float							RangedDelay, LungeSpeed;

var()			name							LungeStartAnim, LungeMidAnim, LungeEndAnim;
var()			float							PreRotateModifier;

//--BOSS CAMERA----------------------------------------------------------------
// bIsBossMonster: Uses the boss camera when spawning, also starts next wave
// Attachee: Camera position during sight
// BossBone: Bone / socket to attach the sight camera to
// FocusBone: Bone / socket to focus the camera on
// ControllerList: List of controllers that we're forcing the sight camera on
// BossYaw: How much the camera should be rotated around during sight
// bIsInSight: Whether we're currently using the sight camera
// bForceInitialTarget: Instantly search all players in the map and acquire a target when spawned
// RootAnims: Animations that have a moving origin bone
//
// TorsoAimer: Node for rotating the torso around
// TorsoName: Name of the profile that this monster uses for the torso
// bUseAimOffset: Whether or not to use the torso rotator
//
// bDidCamera: Did we trigger the boss camera already? Don't do it again
// CustomSeq: Animation sequence used for playing attack, sight, etc.
//
// ShakeDamage: The intensity of our footstep shakes
// ShakeDistance: Minimum radius the player has to be to experience shakes

var()			bool							bIsBossMonster;
var()			Actor							Attachee;
var()			Name							BossBone, FocusBone;
var()			array<UTPlayerController>		ControllerList;
var()			float							BossYaw;
var()			bool							bIsInSight, bForceInitialTarget;
var()			Vector							BossVector;

var()			AnimNodeAimOffset				TorsoAimer;
var()			name							TorsoName;
var()			bool							bUseAimOffset, bDidCamera;
var()			array<name>						RootAnims;
var()			AnimNodeSequence				CustomSeq;

var()			int								ShakeDamage;
var()			float							ShakeDistance;

//=============================================================================

// Don't take damage when we're dead, keeps the ragdoll from freezing mid-air
state Dying
{
	event TakeDamage(int Damage, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser);
}

// Do a radial shake, called on the player viewport
simulated function ScreenShake(int Intensity, float Dist)
{
	local PlayerController PC;
	
	if (WorldInfo.NetMode == NM_DedicatedServer)
		return;
		
	PC = GetALocalPlayerController();
	
	if (PC.Pawn != None && UTPlayerController(PC) != None)
		UTPlayerController(PC).DamageShake(Intensity * (1.0 -(VSize(PC.Pawn.Location - Location)/Dist)),None);
}

// Is the actor in front of us?
function float GetInFront(actor A, actor B)
{
	local vector aFacing,aToB;
	
	// What direction is A facing in?
	aFacing=Normal(Vector(A.Rotation));
	// Get the vector from A to B
	aToB=B.Location-A.Location;
	 
	return(aFacing dot aToB);
}

// Force the camera to look at us if we're in boss mode
simulated function Tick(float Delta)
{
	local int l;
	local rotator R, FR, UUR;
	local Vector HL;
	local Vector2D AV;
	// OurVector, TheirVector
	local vector OV, TV;
	local float CH1, CR1, CH2, CR2;
	local float RX, RY;
	local rotator TR;
	
	R.Yaw = BossYaw;
	
	if (Role == ROLE_Authority)
	{
		if (Attachee != None && bIsInSight && !bDidCamera)
		{
			// Get the spot to focus the camera on
			if (!Mesh.GetSocketWorldLocationAndRotation(FocusBone, HL, UUR, 0))
				HL = Mesh.GetBoneLocation(FocusBone);
			
			FR = RTurn(Rotator(Attachee.Location - HL),R);
			
			for (l=0; l<ControllerList.Length; l++)
			{
				ControllerList[l].SetRotation(FR);
			}
		}
	}

	if ( Controller == None )
		return;
	
	// SERVER AND CLIENT BOTH, FOR POSITIONS
	// ToDo: Add tween to this that way it doesn't radically snap
	if (TorsoAimer != None && bUseAimOffset)
	{
		GetBoundingCylinder(CR1, CH1);

		// Get our initial rotation
		OV = Location;
		
		if (ToxikkMonsterController(Controller).Target != None)
			TV = ToxikkMonsterController(Controller).Target.Location;
		
		// If we're dead, reset the torso aim
		if (Health <= 0)
		{
			AV.X = 0.0;
			AV.Y = 0.0;
		}
		else
		{
			// Center the rotator if we have no target
			if (ToxikkMonsterController(Controller).Target == None)
			{
				AV.X = 0.0;
				AV.Y = 0.0;
			}
			else
			{
				ToxikkMonsterController(Controller).Target.GetBoundingCylinder(CR2, CH2);
				
				OV.Z += CH1;
				TV.Z += CH2;
				
				// Through a wall
				if (!FastTrace(TV, OV))
				{
					AV.X = 0.0;
					AV.Y = 0.0;
				}
				// Actually calculate
				else
				{
					TR = Rotator(TV-OV) - Rotation;
					RX = Normalize(TR).Yaw;
					RY = Normalize(TR).Pitch;
					
					// 0.5 is directly to the right, -0.5 is directly to the left, so multiply by 2
					AV.X = (RX/32768)*2.0;
					AV.Y = (RY/32768)*2.0;
					
					// Clamp X value between 1 and -1
					if (AV.X > 1.0)
						AV.X = 1.0;
					if (AV.X < -1.0)
						AV.X = -1.0;
						
					// Clamp Y value between 1 and -1
					if (AV.Y > 1.0)
						AV.Y = 1.0;
					if (AV.Y < -1.0)
						AV.Y = -1.0;
				}
			}
		}
		
		TorsoAimer.Aim = AV;
	}
	
	super.Tick(Delta);
}

// Rotate two rotators
function rotator rTurn(rotator rHeading,rotator rTurnAngle)
{
    // Generate a turn in object coordinates 
    //     this should handle any gymbal lock issues
 
    local vector vForward,vRight,vUpward;
    local vector vForward2,vRight2,vUpward2;
    local rotator T;
    local vector  V;
 
    GetAxes(rHeading,vForward,vRight,vUpward);
    //  rotate in plane that contains vForward&vRight
    T.Yaw=rTurnAngle.Yaw; V=vector(T);
    vForward2=V.X*vForward + V.Y*vRight;
    vRight2=V.X*vRight - V.Y*vForward;
    vUpward2=vUpward;
 
    // rotate in plane that contains vForward&vUpward
    T.Yaw=rTurnAngle.Pitch; V=vector(T);
    vForward=V.X*vForward2 + V.Y*vUpward2;
    vRight=vRight2;
    vUpward=V.X*vUpward2 - V.Y*vForward2;
 
    // rotate in plane that contains vUpward&vRight
    T.Yaw=rTurnAngle.Roll; V=vector(T);
    vForward2=vForward;
    vRight2=V.X*vRight + V.Y*vUpward;
    vUpward2=V.X*vUpward - V.Y*vRight;
 
    T=OrthoRotation(vForward2,vRight2,vUpward2);
 
   return(T);    
}

// Special cinematic boss camera
reliable server function SetBossCamera(bool bBoss)
{
	local Controller C;
	local Vector V;
	
	if (bDidCamera)
		return;
	
	V = BossVector;
	
	ControllerList.Length = 0;
	
	bIsInSight = bBoss;
	
	ForEach WorldInfo.AllControllers(Class'Controller',C)
	{
		if( UTPlayerController(C)!=None )
		{
			ControllerList.AddItem(UTPlayerController(C));
			
			if (bBoss)
			{
				if (Attachee == None)
				{
					Attachee = Spawn(Class'FakeAttach',Self);
					Attachee.SetBase(Self,,Mesh,BossBone);
					Attachee.SetRelativeLocation(V);
				}
				UTPlayerController(C).SetViewTarget(Attachee);
				UTPlayerController(C).ClientSetViewTarget(Attachee);
			}
			
			else
			{
				bDidCamera=true;
				Attachee.Destroy();
				ControllerList.Length = 0;
				
				if (C.Pawn != None)
				{
					UTPlayerController(C).SetViewTarget(UTPlayerController(C).Pawn);
					UTPlayerController(C).ClientSetViewTarget(UTPlayerController(C).Pawn);
				}
				else
				{
					UTPlayerController(C).SetViewTarget(None);
					UTPlayerController(C).ClientSetViewTarget(None);
				}		
			}
			
		}
	}
}

// Set up lighting and spawn a controller
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	
	// KEEP THE MODEL FROM LOOKING BLACK
	FakeComponent.LightEnvironment.SetEnabled(true); // just in case init the mesh light environment
	LEC.SetEnabled(true); // now the dynamic light component

	/* This must be off - Pawns spawned during gameplay don't initially have a controller
	if (Role == ROLE_Authority)
		SpawnDefaultController();
	*/
}

// Called by gamemode right after spawn
function SetMonsterIsBoss()
{
	bIsBossMonster = true;
	bForceInitialTarget = true;
	bAlwaysRelevant = true;
}

// Anim tree is initialized
// Grab some animation parameters
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
    super.PostInitAnimTree(SkelComp);

    if (SkelComp == Mesh)
	{
        CustomAnimator = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('CustomPlayer'));
        WalkSwitch = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('WalkSwitch'));
		TorsoAimer = AnimNodeAimOffset(SkelComp.FindAnimNode('AimNode'));
		CustomSeq = AnimNodeSequence(SkelComp.FindAnimNode('CustomSeq'));
		
		// Set default walk anim
		WalkSwitch.PlayCustomAnim(RunningAnim,1.0,,,true);
		TorsoAimer.SetActiveProfileByName(TorsoName);
	}
}

// TURN THE MONSTER INTO A RAGDOLL
simulated function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
  if (Super.Died(Killer, DamageType, HitLocation))
  {
	PlaySound(DeathSound, TRUE);
	SetPawnRBChannels(true);
    Mesh.MinDistFactorForKinematicUpdate = 0.f;
    Mesh.ForceSkelUpdate();
    Mesh.SetTickGroup(TG_PostAsyncWork);
	
	PreRagdollCollisionComponent = CollisionComponent;
    CollisionComponent = Mesh;
	
    CylinderComponent.SetActorCollision(false, false);
    Mesh.SetActorCollision(true, false);
    Mesh.SetTraceBlocking(true, true);
    SetPhysics(PHYS_RigidBody);
    Mesh.PhysicsWeight = 1.0;

    if (Mesh.bNotUpdatingKinematicDueToDistance)
    {
      Mesh.UpdateRBBonesFromSpaceBases(true, true);
    }

    Mesh.PhysicsAssetInstance.SetAllBodiesFixed(false);
    Mesh.bUpdateKinematicBonesFromAnimation = false;
    Mesh.SetRBLinearVelocity(Velocity, false);
    Mesh.ScriptRigidBodyCollisionThreshold = MaxFallSpeed;
    Mesh.SetNotifyRigidBodyCollision(true);
    Mesh.WakeRigidBody();

    return true;
  }
}

// Copied from UTPawn, for ragdolls
simulated function SetPawnRBChannels(bool bRagdollMode)
{
	if(bRagdollMode)
	{
		Mesh.SetRBChannel(RBCC_Pawn);
		Mesh.SetRBCollidesWithChannel(RBCC_Default,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_Pawn,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_Vehicle,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_Untitled3,FALSE);
		Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume,TRUE);
	}
	else
	{
		Mesh.SetRBChannel(RBCC_Untitled3);
		Mesh.SetRBCollidesWithChannel(RBCC_Default,FALSE);
		Mesh.SetRBCollidesWithChannel(RBCC_Pawn,FALSE);
		Mesh.SetRBCollidesWithChannel(RBCC_Vehicle,FALSE);
		Mesh.SetRBCollidesWithChannel(RBCC_Untitled3,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume,FALSE);
	}
}

// Play a single-shot forced anim with optional sound
simulated function PlayForcedAnim(name A, optional SoundCue Snd)
{
	local int l;
	local bool bUseRoot;
	
	if (CustomAnimator == None || Health <= 0)
		return;
		
	// Root animation?
	for (l=0; l<RootAnims.Length; l++)
	{
		if (RootAnims[l] == A)
			bUseRoot=true;
	}
	
	// Enable root anims
	if (bUseRoot)
	{
		CustomSeq.SetRootBoneAxisOption(RBA_Translate, RBA_Translate, RBA_Translate);
		Mesh.RootMotionMode = RMM_Accel;
		CustomSeq.bCauseActorAnimEnd = TRUE;
		Mesh.bRootMotionModeChangeNotify = TRUE;
	}
		
	if (Snd != None)
		PlaySound(Snd, TRUE);
		
	CustomAnimator.PlayCustomAnim(A,1.0);
}

// Let root motion take over
simulated event RootMotionModeChanged(SkeletalMeshComponent SkelComp)
{
   if( SkelComp.RootMotionMode == RMM_Translate )
   {
      Velocity = Vect(0.f, 0.f, 0.f);
      Acceleration = Vect(0.f, 0.f, 0.f);
   }

   // Disable notification
   Mesh.bRootMotionModeChangeNotify = false;
}

// Finished playing a root anim
simulated event OnAnimEnd(AnimNodeSequence SeqNode, float PlayedTime, float ExcessTime)
{
   // Discard root motion. So mesh stays locked in place.
   CustomSeq.SetRootBoneAxisOption(RBA_Discard, RBA_Discard, RBA_Discard);

   // Tell mesh to stop using root motion
   Mesh.RootMotionMode = RMM_Ignore;
   
   CustomSeq.bCauseActorAnimEnd = FALSE;
   
   super.OnAnimEnd(SeqNode, PlayedTime, ExcessTime);
}

// When we touch the ground, stop lunging
event Landed(vector HitNormal, Actor FloorActor)
{
	if (Role == ROLE_Authority)
		bIsLunging=false;
		
	super.Landed(HitNormal, FloorActor);
}

// When we touch another actor, stop lunging
event Bump(Actor Other, PrimitiveComponent OtherComp, Vector HitNormal)
{
	if ( Role == ROLE_Authority && bIsLunging && Pawn(Other)!=None && Controller!=None && Other == ToxikkMonsterController(Controller).Target )
	{
		bIsLunging = false;
		Pawn(Other).TakeDamage(LungeDamage, Controller, Other.Location, HitNormal, None);
	}
	Super.Bump(Other, OtherComp, HitNormal);
}

// Animnotify, play a footstep sound
function PlayFootstep()
{
	if (Health > 0 && WorldInfo.NetMode != NM_DedicatedServer)
	{
		PlaySound(FootstepSound, TRUE);
		ScreenShake(ShakeDamage, ShakeDistance);
	}
}

// Damage enemy (Called from notify)
simulated function MeleeDamage()
{
	local vector V;
	
	if (ToxikkMonsterController(Controller).Target != None && ROLE == ROLE_Authority)
	{
		if (VSize(ToxikkMonsterController(Controller).Target.Location - Location) <= AttackDistance)
			ToxikkMonsterController(Controller).Target.TakeDamage(PunchDamage, Controller, ToxikkMonsterController(Controller).Target.Location, V, None);
	}
}

// Called from notify, shoot a projectile
simulated function ShootProjectile()
{
	if (Role == ROLE_Authority)
		DoShot(TipBone);
		
	if (FireSound != None)
		PlaySound(FireSound,TRUE);
}

// Same, but for left bone
simulated function ShootProjectileLeft()
{
	if (Role == ROLE_Authority)
		DoShot(TipBoneLeft);
		
	if (FireSound != None)
	PlaySound(FireSound,TRUE);
}

// Same, but for right bone
simulated function ShootProjectileRight()
{
	if (Role == ROLE_Authority)
		DoShot(TipBoneRight);
		
	if (FireSound != None)
	PlaySound(FireSound,TRUE);
}

// SHOOT A PROJECTILE FROM A BONE
reliable server function DoShot(name BoneName)
{
	local Vector FinalLoc;
	local Rotator SocketRotation, FinalRotation;
	local Projectile Proj;
	
	// Find a socket if we can
	if (Mesh.GetSocketWorldLocationAndRotation(BoneName, FinalLoc, SocketRotation, 0)) {}
	// Otherwise, find the bone
	else
		FinalLoc = Mesh.GetBoneLocation(BoneName);
	
	// Once we figure out the starting positions, shoot projectiles toward the player
	FinalRotation = rotator(Normal(ToxikkMonsterController(Controller).Target.Location - FinalLoc));
	
	// SPAWN THE ACTUAL PROJECTILE
	Proj = Spawn(MissileClass,Controller,,FinalLoc,FinalRotation);
	Proj.Damage *= ProjDamageMult;
	// Proj.Speed = 50;
	if (CRZProjectile(Proj) != None)
		CRZProjectile(Proj).CRZInit(vector(FinalRotation),vector(FinalRotation),-1);
}

// New target acquired
reliable server function SeenSomething()
{
	PlaySound(SightSound, TRUE);
}

// Spawn some blood and do hitmarker, plus pain
event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local vector BloodMomentum;

	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);

	// lock to attacker
	if (InstigatedBy != None && InstigatedBy.Pawn != None)
	{
		ToxikkMonsterController(Controller).LockOnTo(InstigatedBy.Pawn);
		SetDesiredRotation(Rotator(InstigatedBy.Pawn.Location - Location));
	}

	if ( Damage <= 0 )
		return;

	// hitsounds/hitmarkers for player
	if ( CRZPlayerController(InstigatedBy) != None )	
		CRZPlayerController(InstigatedBy).ConfirmHit(Damage);//send to client

	// say "ouch"
	if ( FRand() >= PainSoundChance )
		PlaySound(PainSound, TRUE);

	// spill some blood
	BloodMomentum = Momentum;
	if ( BloodMomentum.Z > 0 )
		BloodMomentum.Z *= 0.5;
}

DefaultProperties
{
	BossYaw=32768
	ShakeDamage=0
	ShakeDistance=1500
	
    Begin Object Name=CollisionCylinder
        CollisionHeight=+44.000000
    End Object
	
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
        bEnabled=TRUE
		AmbientGlow=(R=0.01,G=0.01,B=0.01,A=1)
    End Object
	LEC = MyLightEnvironment
 
	// SKELETAL MESH
    Begin Object Class=SkeletalMeshComponent Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Boney.boney_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Boney.boney_animset'
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
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Boney.boney_mesh_Physics'
		PhysicsWeight=0.0
    End Object
    Mesh=MainMesh
	
	FakeComponent=MainMesh
    Components.Add(MainMesh)
	Components.Add(MyLightEnvironment)
	
	ControllerClass=class'Infekkted.ToxikkMonsterController'

	// Monsters can't jump
    bJumpCapable=false
    bCanJump=false
	
	DrawScale=1.25
	
	// How fast we run
    GroundSpeed=100.0
	// Fall by default
	Physics=PHYS_Falling
	
	//--THESE PARAMETERS CAN BE CHANGED--------------------------------

	PainSoundChance=0.25
	
	FootstepSound=SoundCue'Doom3Monsters.Boney.VP.zombie_step_cue'
	PainSound=SoundCue'Doom3Monsters.Boney.VP.boney_pain_cue'
	SightSound=SoundCue'Doom3Monsters.Boney.VP.boney_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Boney.VP.boney_death_cue'
	AttackSound=SoundCue'Doom3Monsters.Boney.VP.boney_attack_cue'
	ChatterSound=SoundCue'Doom3Monsters.Boney.VP.boney_chatter_cue'
	
	bHasMelee=true
	bHasRanged=false
	
	MeleeAttackAnims(0)=MeleeAttack01
	MeleeAttackAnims(1)=MeleeAttack02
	MeleeAttackAnims(2)=MeleeAttack03
	MeleeAttackAnims(3)=MeleeAttack04
	
	PunchDamage=10

	ProjDamageMult=1.0
	
	AttackDistance=92
	
	RunningAnim=Walk
	
	SightChance=0.25
	
	SightAnims(0)=Sight
	
	SightRadius=500000
	
	RangedDelay=2.0
	
	PreRotateModifier=2.0
	
	TorsoName=Default
	bUseAimOffset=true
}
