//================================================================
// Infekkted.ToxikkMonster
// ----------------
// ...
// ----------------
// by ZedekThePD & Chatouille
//================================================================
Class ToxikkMonster extends UDKPawn;

//NOTE:
// Rewrote variables declarations to include the intellisense description correctly,
// and regrouped them by type so they are easier to find in that unreadable mess...


var		LightEnvironmentComponent		LEC;
var		SkeletalMeshComponent			FakeComponent;

// How quickly we face the player
var		int								FaceRate;

var		string							MonsterName;

//=============================================================================
//--DEBUG----------------------------------------------------------------------

var		bool							bUsingStraightPath;				// We're not using pathfinding, just a straight path to the player
var		bool							bBlindWalk;						// We're trying to use pathfinding but there's no MoveTarget
var		bool							bUsingJumpPad;					// Walking toward a jump pad

//=============================================================================
//--ATTACKING------------------------------------------------------------------

/** Monster can lunge (imp, trite, etc.) */
var bool bHasLunge;
/** Monster is currently lunging (mid-air) */
var bool bIsLunging;
/** Monster can only lunge while crouched */
var bool bLungeIfCrouched;
/** Monster is currently crawling */
var bool bIsCrawling;

/** How close we have to be to start attacking melee-wise */
var float AttackDistance;
/** Distance the monster must be to attack the player with projs */
var float RangedAttackDistance;
/** Chance to lunge at the player */
var float LungeChance;
/** How close the player has to be to lunge */
var float LungeDistance;
/** Chance to start crawling after we're standing and do a ranged attack */
var float CrawlChance;
/** Minimum time between ranged attacks before the next can occur */
var float RangedDelay;
/** How much force is applied when we lunge toward the player */
var float LungeSpeed;

/** How much damage melee attacks do */
var int PunchDamage;
/** Front check for punch attack (0-180) */
var int PunchDegrees;
/** Momentum of the punch attack */
var int PunchMomentum;
/** How much damage lunge attack does */
var int LungeDamage;


/** Projectile to spawn for ranged attack */
var Class<Projectile> MissileClass;

/** Bones / sockets that projectiles / tracers come out of */
var name TipBone, TipBoneLeft, TipBoneRight;

/** Damage multiplier for projectiles - used by Gamemode adjusters */
var float ProjDamageMult;


//=============================================================================
//--SOUNDS---------------------------------------------------------------------

/** Played when the monster finds a target and it's idling */
var SoundCue SightSound;
/** Played when the monster dies */
var SoundCue DeathSound;
/** Footstep sounds obviously */
var SoundCue FootstepSound;
/** Periodically played in the idle state */
var SoundCue IdleSound;
/** Same as idle, but when the monster has a target */
var SoundCue ChatterSound;
/** Called when the monster is hurt */
var SoundCue PainSound;
/** Done when the monster melees / shoots */
var SoundCue AttackSound;
/** Done when monster shoots */
var SoundCue FireSound;
/** FRand() must be greater than this to play pain sounds */
var float PainSoundChance;
/** Time (in seconds) between idle / combat chatter noises */
var float ChatterTime;


//=============================================================================
//--ANIMATIONS-----------------------------------------------------------------

var AnimNodePlayCustomAnim  CustomAnimator, WalkSwitch;
var AnimNodeBlend CrawlBlender, DeathBlender;

/** Monster has a melee attack */
var bool bHasMelee;
/** Monster has a ranged attack */
var bool bHasRanged;
/** Monster continues to walk when meleeing */
var bool bWalkingAttack;
/** Monster continues to walk when doing ranged attack */
var bool bWalkingRanged;

/** Animations to play when attacking */
var array<Name> MeleeAttackAnims;
/** Animations to play when shooting / ranged */
var array<Name> RangedAttackAnims;
/** Animations to play when shooting / crouched (crawling?) */
var array<Name> CrouchedRangedAnims;
/** Anims to play when we get a new target */
var array<Name> SightAnims;
/** Anims to play when we get hurt */
var array<Name> PainAnims;

/** This monster's run anim */
var name RunningAnim;
/** Lunge animations */
var name LungeStartAnim, LungeMidAnim, LungeEndAnim;

/** Chance to play sight anim */
var float SightChance;
/** Amount to speed up our rotation rate when we're prepping ranged attacks */
var float PreRotateModifier;

/** Replicate custom anims to clients (attack, sight...) */
struct sRepAnimInfo
{
	/** Switch to force-replicate if it is the same anim as before */
	var bool bSwitch;
	var Name AnimName;
};
/** Replicate custom anims to clients (attack, sight...) */
var RepNotify sRepAnimInfo ForcedAnim;


//=============================================================================
//--BOSS STUFF-----------------------------------------------------------------
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
//--DYING, RAGDOLL, GIBS-------------------------------------------------------

/** Time at which this pawn entered the dying state */
var float DeathTime;
/** Max duration of ragdoll */
var float RagdollLifespan;
/** Track damage accumulated during a tick - used for gibbing determination */
var float AccumulateDamage;
/** Tick time for which damage is being accumulated */
var float AccumulationTime;

/** Set when pawn died on listen server, but was hidden rather than ragdolling (for replication purposes) */
var bool bHideOnListenServer;
/** whether or not we have been gibbed already */
var bool bGibbed;

/** Gib sounds */
var SoundCue GibSound, CrushedSound;

/** Blood stuff */
var MaterialInstance BloodSplatterDecalMaterial;
/** Blood stuff */
var array<DistanceBasedParticleTemplate> BloodEffects;
/** Blood stuff */
var class<UTEmit_HitEffect> BloodEmitterClass;

/** Bone gibs */
var array<GibInfo> Gibs;
/** Gib explosion particlesystem */
var ParticleSystem GibExplosionTemplate;


//=============================================================================
//--REPLICATION----------------------------------------------------------------

replication
{
	if ( bNetInitial )
		bIsBossMonster;

	if (bNetDirty || bNetInitial)
		bIsCrawling;

	if ( bNetDirty && !bNetInitial )
		ForcedAnim;
}


//================================================
// Init
//================================================

simulated function PostBeginPlay()
{
	// local NavigationPoint NP;
	
	Super.PostBeginPlay();
	
	// KEEP THE MODEL FROM LOOKING BLACK
	//note: pls spare resources of dedicated servers
	if ( WorldInfo.NetMode != NM_DedicatedServer )
	{
		FakeComponent.LightEnvironment.SetEnabled(true); // just in case init the mesh light environment
		LEC.SetEnabled(true); // now the dynamic light component

		SetTimer(0.01, false, 'PostNetBeginPlay');  // a bit hacky - ideally it would be the first tick after PostBeginPlay
	}

	if (Role == ROLE_Authority)
	{
		SetTimer(1.0, false, 'CheckController');

		SetTimer(ChatterTime, true, 'DoChatter'); //TODO: can we do this on client-side ?
		
		/* debug
		// Spawn an emitter at every pathnode
		ForEach AllActors(Class'NavigationPoint',NP)
		{
			Spawn(Class'PathIndicator',,,NP.Location);
		}
		*/
	}
}

/** Called by gamemode right after spawn (first) */
function SetMonsterIsBoss()
{
	bIsBossMonster = true;
	bForceInitialTarget = true;
	// the boss is always relevant to all players - we could add a big boss health bar on the HUD
	bAlwaysRelevant = true;
	bReplicateHealthToAll = true;
}

/** Adjusters - called by gamemode right after spawn (second) **/
function SetParameters(float Scale, int HP, float Speed, float Melee, float Range, String Extras)
{
	SetDrawScale(Scale);
	HealthMax = HP; // acts as an "initial hp" constant
	Health = HP;
	GroundSpeed *= Speed;
	PunchDamage *= Melee;
	LungeDamage *= Range;
	ProjDamageMult = Range;
}

/** For mapped and manually spawned monsters - give them a controller automatically **/
function CheckController()
{
	if (Controller == None)
		SpawnDefaultController();
}

// Play idle / chatter sounds
// server-side (we access the controller) => replicate sounds
// this could be moved to client-side for better network performance, but we need to replicate the combat/idle state
function DoChatter()
{
	if (Controller == None || Health <= 0)
		return;
		
	if (ToxikkMonsterController(Controller) != None)
	{
		// If we're in combat then play combatchatter
		if (Pawn(ToxikkMonsterController(Controller).Target) != None)
		{
			if ( ChatterSound != None )
				PlaySound(ChatterSound);
		}
		// Else, play idle
		else if ( IdleSound != None )
			PlaySound(IdleSound);
	}
}

/** Called on client when initially replicated variables are ready */
simulated function PostNetBeginPlay()
{
	local PlayerController PC;

	if ( bIsBossMonster )
	{
		foreach WorldInfo.LocalPlayerControllers(class'PlayerController', PC)
		{
			if ( InfekktedHUD(PC.myHUD) != None )
				InfekktedHUD(PC.myHUD).Boss = Self;
		}
	}
}

/** Anim tree is initialized : grab some animation parameters */
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
    super.PostInitAnimTree(SkelComp);

    if (SkelComp == Mesh)
	{
        CustomAnimator = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('CustomPlayer'));
        WalkSwitch = AnimNodePlayCustomAnim(SkelComp.FindAnimNode('WalkSwitch'));
		TorsoAimer = AnimNodeAimOffset(SkelComp.FindAnimNode('AimNode'));
		CustomSeq = AnimNodeSequence(SkelComp.FindAnimNode('CustomSeq'));
		CrawlBlender = AnimNodeBlend(SkelComp.FindAnimNode('CrawlBlend'));
		DeathBlender = AnimNodeBlend(SkelComp.FindAnimNode('DeadBlend'));
		
		// Set default walk anim
		WalkSwitch.PlayCustomAnim(RunningAnim,1.0,,,true);
		TorsoAimer.SetActiveProfileByName(TorsoName);
	}
}


//================================================
// Boss stuff
//================================================

function SetBossCamera(bool bSet)
{
	local Controller C;
	local Vector V;

	//TODO: overhaul this shit!
	return;

	//ifpossible: use the function in UTPawn that picks a "good end-game focus point"
	//then make the camera ghost-travel smoothly to that point
	//animate-interpolate startpoint -> endpoint with ease-in-out
	//animate-interpolate startrot -> endrot with ease-in-out

	//start with linear interpolation for simplicity, see later for the ease-in-out

	//first we need to decouple BossCam from Sight animation in MonsterController
	//the force-target is ok and will trigger the sight animation - we can launch the bosscam from here independently
	//the boss is AlwaysRelevant so we should be able to do that fully client-side
	//maybe we won't see other monsters/players during the travel (because not relevant) but doesn't matter
	//the travel should be very quick : 1sec travel to boss : watch boss 3-4 secs : 1 sec travel back to pawn

	//TODO: when this works, we need to cancel damage done to players during that bosscam-state
	//do that in gamemode, as soon as boss is spawned, enable a timer of 5 secs and give pawns spawnprotection

	//ideally the timers (watchboss and protection) should be based on the duration of the anim, not hardcoded

	if (bDidCamera)
		return;
	
	V = BossVector;
	
	ControllerList.Length = 0;
	
	bIsInSight = bSet;
	
	ForEach WorldInfo.AllControllers(Class'Controller',C)
	{
		if( UTPlayerController(C)!=None )
		{
			ControllerList.AddItem(UTPlayerController(C));
			
			if (bSet)
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

// Force the camera to look at us if we're in boss mode
simulated function Tick(float Delta)
{
	local int l;
	local rotator R, FR, UUR;
	local Vector HL;
	local Vector2D AV;
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

	// If we're crawling, set the crawl blender accordingly
	if (CrawlBlender != None)
	{
		if (bIsCrawling)
			CrawlBlender.SetBlendTarget(1.0,0.0);
		else
			CrawlBlender.SetBlendTarget(0.0,0.0);
	}

	if (Controller == None)
		return;

	// SERVER AND CLIENT BOTH, FOR POSITIONS
	//TODO: Add tween to this that way it doesn't radically snap
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

// Is the actor in front of us?
static function float GetInFront(actor A, actor B)
{
	local vector aFacing,aToB;
	
	// What direction is A facing in?
	aFacing=Normal(Vector(A.Rotation));
	// Get the vector from A to B
	aToB=B.Location-A.Location;
	 
	return(aFacing dot aToB);
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


//================================================
// Misc
//================================================

// Extra fancy debug info
simulated function DisplayDebug(HUD HUD, out float out_YL, out float out_YPos)
{
	local Canvas Canvas;
	local float StartY;
	local float XL, YL;
	
	super.DisplayDebug(HUD,out_YL,out_YPos);
	
	if (HUD.ShouldDisplayDebug('AI'))
	{
		Canvas = HUD.Canvas;
		Canvas.TextSize("HEIGHT BLAH",XL,YL);
		StartY = Canvas.ClipY * 0.35;
		YL = YL + 12; // Add padding
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY,ALIGN_Left,ALIGN_Top,"Viewing"@GetMonsterName(),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+YL,ALIGN_Left,ALIGN_Top,"Straightline path:"@string(bUsingStraightPath),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*2),ALIGN_Left,ALIGN_Top,"Blind walk:"@string(bBlindWalk),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*3),ALIGN_Left,ALIGN_Top,"Using jump pad:"@string(bUsingJumpPad),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		
		// More pathfinding
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*4),ALIGN_Left,ALIGN_Top,"RouteCache Length:"@string(Controller.RouteCache.Length),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*5),ALIGN_Left,ALIGN_Top,"CurrentPath:"@string(Controller.CurrentPath),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*6),ALIGN_Left,ALIGN_Top,"NextRoutePath:"@string(Controller.NextRoutePath),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*7),ALIGN_Left,ALIGN_Top,"MoveTarget:"@string(Controller.MoveTarget),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*8),ALIGN_Left,ALIGN_Top,"DestinationPosition:"@string(Controller.DestinationPosition.Position),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		//class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*9),ALIGN_Left,ALIGN_Top,"GoalList:"@string(Controller.GoalList),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*9),ALIGN_Left,ALIGN_Top,"RouteGoal:"@string(Controller.RouteGoal),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*10),ALIGN_Left,ALIGN_Top,"Target:"@string(ToxikkMonsterController(Controller).Target),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		class'InfekktedHUD'.Static.DrawTextPlus(Canvas,32,StartY+(YL*11),ALIGN_Left,ALIGN_Top,"RoamTarget:"@string(ToxikkMonsterController(Controller).RoamTarget),true,64,255,64,class'CRZHud'.default.GlowFonts[0]);
		
		// Draw stuff on junk
		if (ToxikkMonsterController(Controller).Target != None)
			DrawSymbolOn("T",ToxikkMonsterController(Controller).Target,Canvas,255,255,255,ALIGN_Bottom);
		if (ToxikkMonsterController(Controller).RoamTarget != None)
			DrawSymbolOn("RT",ToxikkMonsterController(Controller).RoamTarget,Canvas,255,255,0,ALIGN_Top);
	}
}

function DrawSymbolOn(string Symbol, Actor A, Canvas Canvas, int R, int G, int B, InfekktedHud.TextAlignType AL)
{
	local vector HP;
	
	HP = Canvas.Project(A.Location);
	class'InfekktedHUD'.Static.DrawTextPlus(Canvas,HP.X,HP.Y,ALIGN_Center,AL,Symbol,true,R,G,B,class'CRZHud'.default.GlowFonts[0]);
}

// Decide whether or not we're crawling (imps / vulgars)
function SetCrawling(bool bCrawl)
{
	bIsCrawling = bCrawl;
}

// Do a radial shake, called on the player viewport
simulated function ScreenShake(int Intensity, float Dist)
{
	local UTPlayerController PC;
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		foreach WorldInfo.LocalPlayerControllers(class'UTPlayerController', PC)
		{
			if ( PC.Pawn != None )
				PC.DamageShake(Intensity * (1.0 -(VSize(PC.Pawn.Location - Location)/Dist)),None);
			else if ( PC.ViewTarget != None )
				PC.DamageShake(Intensity * (1.0 -(VSize(PC.ViewTarget.Location - Location)/Dist)),None);
		}
	}
}


//================================================
// Dying, Ragdoll
//================================================

/** Standard way to play dying sound */
simulated function PlayDyingSound()
{
	if ( WorldInfo.NetMode != NM_DedicatedServer )
		PlaySound(DeathSound, true);
}

/** Responsible for playing any death effects, animations, etc. */
//SMARTCOPY UTPawn
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	local vector ApplyImpulse, ShotDir;
	local TraceHitInfo HitInfo;
	local class<UTDamageType> UTDamageType;

	bCanTeleport = false;
	bReplicateMovement = false;
	bTearOff = true;
	bPlayedDeath = true;
	
	// STOP THE ANIMATION
	DeathBlender.SetBlendTarget(1.0,0.0);

	HitDamageType = DamageType; // these are replicated to other clients
	TakeHitLocation = HitLoc;

	if ( WorldInfo.NetMode == NM_DedicatedServer )
	{
 		UTDamageType = class<UTDamageType>(DamageType);
		// tell clients whether to gib
		bTearOffGibs = (UTDamageType != None && ShouldGib(UTDamageType));
		bGibbed = bGibbed || bTearOffGibs;
		GotoState('Dying');
		return;
	}

	if ( WorldInfo.TimeSeconds - LastRenderTime > 2 )
	{
		if (WorldInfo.NetMode == NM_ListenServer || WorldInfo.IsRecordingDemo())
		{
			if (WorldInfo.Game.NumPlayers + WorldInfo.Game.NumSpectators < 2 && !WorldInfo.IsRecordingDemo())
			{
				Destroy();
				return;
			}
			bHideOnListenServer = true;

			// check if should gib (for clients)
			UTDamageType = class<UTDamageType>(DamageType);
			if (UTDamageType != None && ShouldGib(UTDamageType))
			{
				bTearOffGibs = true;
				bGibbed = true;
			}
			TurnOffPawn();
			return;
		}
		else
		{
			// if we were not just controlling this pawn,
			// and it has not been rendered in 2 seconds, just destroy it.
			Destroy();
			return;
		}
	}

	UTDamageType = class<UTDamageType>(DamageType);
	if (UTDamageType != None && !class'UTGame'.static.UseLowGore(WorldInfo) && ShouldGib(UTDamageType))
	{
		SpawnGibs(UTDamageType, HitLoc);
	}
	else
	{
		CheckHitInfo( HitInfo, Mesh, Normal(TearOffMomentum), TakeHitLocation );

		bBlendOutTakeHitPhysics = false;

		// Turn off hand IK when dead.
		//TODO: Check what this is useful for ??
		//SetHandIKEnabled(false);

		// if we had some other rigid body thing going on, cancel it
		if (Physics == PHYS_RigidBody)
		{
			//@note: Falling instead of None so Velocity/Acceleration don't get cleared
			setPhysics(PHYS_Falling);
		}

		PreRagdollCollisionComponent = CollisionComponent;
		CollisionComponent = Mesh;

		Mesh.MinDistFactorForKinematicUpdate = 0.f;

		// If we had stopped updating kinematic bodies on this character due to distance from camera, force an update of bones now.
		if( Mesh.bNotUpdatingKinematicDueToDistance )
		{
			Mesh.ForceSkelUpdate();
			Mesh.UpdateRBBonesFromSpaceBases(TRUE, TRUE);
		}

		Mesh.PhysicsWeight = 1.0;

		SetPhysics(PHYS_RigidBody);
		Mesh.PhysicsAssetInstance.SetAllBodiesFixed(FALSE);
		SetPawnRBChannels(TRUE);

		if( TearOffMomentum != vect(0,0,0) )
		{
			ShotDir = normal(TearOffMomentum);
			ApplyImpulse = ShotDir * DamageType.default.KDamageImpulse;

			// If not moving downwards - give extra upward kick
			if ( Velocity.Z > -10 )
			{
				ApplyImpulse += Vect(0,0,1)*DamageType.default.KDeathUpKick;
			}
			Mesh.AddImpulse(ApplyImpulse, TakeHitLocation, HitInfo.BoneName, true);
		}

		GotoState('Dying');
	}
}

/** Whether or not we should gib due to damage from the passed in damagetype */
//SMARTCOPY UTPawn
simulated function bool ShouldGib(class<UTDamageType> D)
{
	return (Mesh != None 
		&& (bTearOffGibs 
			// rework UTDamageType.static.ShouldGib(UTPawn P) because we don't have a UTPawn...
			|| ( !D.default.bNeverGibs && (D.default.bAlwaysGibs || (AccumulateDamage > D.default.AlwaysGibDamageThreshold) || ((Health < D.default.GibThreshold) && (AccumulateDamage > D.default.MinAccumulateDamageThreshold))) )
			)
		);
}

//COPY UTPawn
simulated function TurnOffPawn()
{
	// hide everything, turn off collision
	if (Physics == PHYS_RigidBody)
	{
		Mesh.SetHasPhysicsAssetInstance(FALSE);
		Mesh.PhysicsWeight = 0.f;
		SetPhysics(PHYS_None);
	}
	if (!IsInState('Dying')) // so we don't restart Begin label and possibly play dying sound again
	{
		GotoState('Dying');
	}
	SetPhysics(PHYS_None);
	SetCollision(false, false);
	//@warning: can't set bHidden - that will make us lose net relevancy to everyone
	Mesh.SetHidden(true);
}

/** spawns gibs and hides the pawn's mesh */
//SMARTCOPY UTPawn
simulated function SpawnGibs(class<UTDamageType> UTDamageType, vector HitLocation)
{
	local int i;
	local bool bSpawnHighDetail;
	local GibInfo MyGibInfo;

	// make sure client gibs me too
	bTearOffGibs = true;

	if ( !bGibbed )
	{
		if ( WorldInfo.NetMode == NM_DedicatedServer )
		{
			bGibbed = true;
			return;
		}

		// play sound
		if(WorldInfo.TimeSeconds - DeathTime < 0.35) // had to have just died to do a death scream.
		{
			PlaySound(GibSound, true);    //FROM UTPawnSoundGroup
		}
		// the body sounds can go off any time
		PlaySound(CrushedSound,false,true);   //FROM UTPawnSoundGroup

		// gib particles
		if (GibExplosionTemplate != None && EffectIsRelevant(Location, false, 7000))
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(GibExplosionTemplate, Location, Rotation);
			// spawn all other gibs
			bSpawnHighDetail = !WorldInfo.bDropDetail && (Worldinfo.TimeSeconds - LastRenderTime < 1);
			for (i = 0; i < Gibs.length; i++)
			{
				MyGibInfo = Gibs[i];

				if ( bSpawnHighDetail || !MyGibInfo.bHighDetailOnly )
				{
					SpawnGib(MyGibInfo.GibClass, MyGibInfo.BoneName, UTDamageType, HitLocation, true);
				}
			}
		}

		// if standalone or client, destroy here
		if ( WorldInfo.NetMode != NM_DedicatedServer && !WorldInfo.IsRecordingDemo() &&
			((WorldInfo.NetMode != NM_ListenServer) || (WorldInfo.Game.NumPlayers + WorldInfo.Game.NumSpectators < 2)) )
		{
			Destroy();
		}
		else
		{
			TurnOffPawn();
		}

		bGibbed = true;
	}
}

//SMARTCOPY UTPawn
simulated function UTGib SpawnGib(class<UTGib> GibClass, name BoneName, class<UTDamageType> UTDamageType, vector HitLocation, bool bSpinGib)
{
	local UTGib Gib;
	local rotator SpawnRot;
	local int SavedPitch;
	local float GibPerterbation;
	local rotator VelRotation;
	local vector X, Y, Z;

	SpawnRot = QuatToRotator(Mesh.GetBoneQuaternion(BoneName));

	// @todo fixmesteve temp workaround for gib orientation problem
	SavedPitch = SpawnRot.Pitch;
	SpawnRot.Pitch = SpawnRot.Yaw;
	SpawnRot.Yaw = SavedPitch;
	Gib = Spawn(GibClass, self,, Mesh.GetBoneLocation(BoneName), SpawnRot);

	if ( Gib != None )
	{
		// add initial impulse
		GibPerterbation = UTDamageType.default.GibPerterbation * 32768.0;
		VelRotation = rotator(Gib.Location - HitLocation);
		VelRotation.Pitch += (FRand() * 2.0 * GibPerterbation) - GibPerterbation;
		VelRotation.Yaw += (FRand() * 2.0 * GibPerterbation) - GibPerterbation;
		VelRotation.Roll += (FRand() * 2.0 * GibPerterbation) - GibPerterbation;
		GetAxes(VelRotation, X, Y, Z);

		if (Gib.bUseUnrealPhysics)
		{
			Gib.Velocity = Velocity + Z * (FRand() * 400.0 + 400.0);
			Gib.SetPhysics(PHYS_Falling);
			Gib.RotationRate.Yaw = Rand(100000);
			Gib.RotationRate.Pitch = Rand(100000);
			Gib.RotationRate.Roll = Rand(100000);
		}
		else
		{
			Gib.Velocity = Velocity + Z * (FRand() * 50.0);
			Gib.GibMeshComp.WakeRigidBody();
			Gib.GibMeshComp.SetRBLinearVelocity(Gib.Velocity, false);
			if ( bSpinGib )
			{
				Gib.GibMeshComp.SetRBAngularVelocity(VRand() * 50, false);
			}
		}

		// let damagetype spawn any additional effects
		UTDamageType.static.SpawnGibEffects(Gib);
		Gib.LifeSpan = Gib.LifeSpan + (2.0 * FRand());
	}

	return Gib;
}

/** For ragdolls */
//COPY UTPawn
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

/** State Dying */
//SMARTCOPY UTPawn
State Dying
{
ignores OnAnimEnd, Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer, FellOutOfWorld;

	simulated function BeginState(Name Prev)
	{
		Super.BeginState(Prev);

		DeathTime = WorldInfo.TimeSeconds;
		CustomGravityScaling = 1.0;

		CylinderComponent.SetActorCollision(false, false);

		if ( bTearOff && (bHideOnListenServer || (WorldInfo.NetMode == NM_DedicatedServer)) )
			LifeSpan = 1.0;
		else
		{
			if ( Mesh != None )
			{
				Mesh.SetTraceBlocking(true, true);
				Mesh.SetActorCollision(true, false);

				// Move into post so that we are hitting physics from last frame, rather than animated from this
				Mesh.SetTickGroup(TG_PostAsyncWork);
			}
			SetTimer(1.0, false);
			LifeSpan = RagDollLifeSpan;
		}
	}

	event bool EncroachingOn(Actor Other)
	{
		// don't abort moves in ragdoll
		return false;
	}

	event Timer()
	{
		local PlayerController PC;
		local bool bBehindAllPlayers;
		local vector ViewLocation;
		local rotator ViewRotation;

		// let the dead bodies stay if the game is over
		if (WorldInfo.GRI != None && WorldInfo.GRI.bMatchIsOver)
		{
			LifeSpan = 0.0;
			return;
		}

		if ( !PlayerCanSeeMe() )
		{
			Destroy();
			return;
		}
		// go away if not viewtarget
		//@todo FIXMESTEVE - use drop detail, get rid of backup visibility check
		bBehindAllPlayers = true;
		ForEach LocalPlayerControllers(class'PlayerController', PC)
		{
			if ( (PC.ViewTarget == self) || (PC.ViewTarget == Base) )
			{
				if ( LifeSpan < 3.5 )
					LifeSpan = 3.5;
				SetTimer(2.0, false);
				return;
			}

			PC.GetPlayerViewPoint( ViewLocation, ViewRotation );
			if ( ((Location - ViewLocation) dot vector(ViewRotation) > 0) )
			{
				bBehindAllPlayers = false;
				break;
			}
		}
		if ( bBehindAllPlayers )
		{
			Destroy();
			return;
		}
		SetTimer(1.0, false);
	}

	simulated event Landed(vector HitNormal, Actor FloorActor)
	{
		local vector BounceDir;

		if( Velocity.Z < -500 )
		{
			BounceDir = 0.5 * (Velocity - 2.0*HitNormal*(Velocity dot HitNormal));
			TakeDamage( (1-Velocity.Z/30), Controller, Location, BounceDir, class'DmgType_Crushed');
		}
	}

	simulated event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		local Vector shotDir, ApplyImpulse,BloodMomentum;
		local class<UTDamageType> UTDamage;
		local UTEmit_HitEffect HitEffect;

		if ( class'UTGame'.Static.UseLowGore(WorldInfo) )
		{
			if ( !bGibbed )
			{
				UTDamage = class<UTDamageType>(DamageType);
				if (UTDamage != None && ShouldGib(UTDamage))
				{
					bTearOffGibs = true;
					bGibbed = true;
				}
			}
			return;
		}

		if (!bGibbed && (InstigatedBy != None || EffectIsRelevant(Location, true, 0)))
		{
			UTDamage = class<UTDamageType>(DamageType);

			// accumulate damage taken in a single tick
			if ( AccumulationTime != WorldInfo.TimeSeconds )
			{
				AccumulateDamage = 0;
				AccumulationTime = WorldInfo.TimeSeconds;
			}
			AccumulateDamage += Damage;

			Health -= Damage;
			if ( UTDamage != None )
			{
				if ( ShouldGib(UTDamage) )
				{
					if ( bHideOnListenServer || (WorldInfo.NetMode == NM_DedicatedServer) )
					{
						bTearOffGibs = true;
						bGibbed = true;
						return;
					}
					SpawnGibs(UTDamage, HitLocation);
				}
				else if ( !bHideOnListenServer && (WorldInfo.NetMode != NM_DedicatedServer) )
				{
					CheckHitInfo( HitInfo, Mesh, Normal(Momentum), HitLocation );
					UTDamage.Static.SpawnHitEffect(self, Damage, Momentum, HitInfo.BoneName, HitLocation);

					if ( UTDamage.default.bCausesBlood && !class'UTGame'.Static.UseLowGore(WorldInfo)
						&& ((PlayerController(Controller) == None) || (WorldInfo.NetMode != NM_Standalone)) )
					{
						BloodMomentum = Momentum;
						if ( BloodMomentum.Z > 0 )
							BloodMomentum.Z *= 0.5;
						HitEffect = Spawn(BloodEmitterClass,self,, HitLocation, rotator(BloodMomentum));
						HitEffect.AttachTo(Self,HitInfo.BoneName);
					}

					if( (Physics != PHYS_RigidBody) || (Momentum == vect(0,0,0)) || (HitInfo.BoneName == '') )
						return;

					shotDir = Normal(Momentum);
					ApplyImpulse = (DamageType.Default.KDamageImpulse * shotDir);

					if( UTDamage.Default.bThrowRagdoll && (Velocity.Z > -10) )
					{
						ApplyImpulse += Vect(0,0,1)*DamageType.default.KDeathUpKick;
					}
					// AddImpulse() will only wake up the body for the bone we hit, so force the others to wake up
					Mesh.WakeRigidBody();
					Mesh.AddImpulse(ApplyImpulse, HitLocation, HitInfo.BoneName, true);
				}
			}
		}
	}

	/** Tick only if bio death effect */
	simulated event Tick(FLOAT DeltaSeconds)
	{
		Disable('Tick');
	}
}


//================================================
// ReplicatedEvent
//================================================

simulated event ReplicatedEvent(Name VarName)
{
	if ( VarName == 'ForcedAnim' )
		PlayForcedAnim(ForcedAnim.AnimName);
	else
		Super.ReplicatedEvent(VarName);
}


//================================================
// Custom animations (attack, sight...)
//================================================

// Play a single-shot forced anim with optional sound
// Should be done on both client and server
simulated function PlayForcedAnim(Name AnimName)
{
	local int i;

	// skip if wrong state
	if ( CustomAnimator == None || Mesh == None || Len(String(ForcedAnim.AnimName)) == 0 || IsInState('Dying') || Health <= 0 )
		return;

	// force replicate the animation
	if ( Role == ROLE_Authority )
	{
		ForcedAnim.AnimName = AnimName;
		ForcedAnim.bSwitch = !ForcedAnim.bSwitch;
	}

	// Enable root anims if necessary
	for ( i=0; i<RootAnims.Length; i++ )
	{
		if ( RootAnims[i] == AnimName )
		{
			CustomSeq.SetRootBoneAxisOption(RBA_Translate, RBA_Translate, RBA_Translate);
			Mesh.RootMotionMode = RMM_Accel;
			CustomSeq.bCauseActorAnimEnd = true;
			Mesh.bRootMotionModeChangeNotify = true;
			break;
		}
	}

	// play (both on server and client)
	CustomAnimator.PlayCustomAnim(AnimName, 1.0);
}


//================================================
// ...
//================================================

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
		Pawn(Other).TakeDamage(LungeDamage, Controller, Other.Location, HitNormal, class'IFDmgType_Melee');
	}
	Super.Bump(Other, OtherComp, HitNormal);
}

// Animnotify, play a footstep sound
simulated function PlayFootstep()
{
	if (!IsInState('Dying') && Health > 0 && WorldInfo.NetMode != NM_DedicatedServer)
	{
		PlaySound(FootstepSound, TRUE);
		ScreenShake(ShakeDamage, ShakeDistance);
	}
}

// Damage enemy (Called from notify)
function MeleeDamage()
{
	local Actor A;
	
	if ( Role == ROLE_Authority && Pawn(ToxikkMonsterController(Controller).Target) != None )
	{
		/*
		// EXPERIMENT
		foreach WorldInfo.VisibleCollidingActors(class'Actor', A, AttackDistance, Location, true,, true)
		{
			// only hit in front
			if ( A != Self && Normal(A.Location - Location) Dot Normal(Vector(Rotation)) > Cos(DegToRad * PunchDegrees) )
			{
				A.TakeDamage(PunchDamage, Controller, (Location + A.Location)/2, PunchMomentum*Normal(A.Location - Location), class'IFDmgType_Melee');
			}
		}
		*/

		/* old */
		if (VSize(ToxikkMonsterController(Controller).Target.Location - Location) <= AttackDistance)
			ToxikkMonsterController(Controller).Target.TakeDamage(PunchDamage, Controller, ToxikkMonsterController(Controller).Target.Location, Location, None);
		//*/
	}
}

// Called from notify, shoot a projectile
simulated function ShootProjectile()
{
	DoShot(TipBone);
}
simulated function ShootProjectileLeft()
{
	DoShot(TipBoneLeft);
}
simulated function ShootProjectileRight()
{
	DoShot(TipBoneRight);
}

// SHOOT A PROJECTILE FROM A BONE
simulated function DoShot(name BoneName)
{
	local Vector FinalLoc;
	local Rotator SocketRotation, FinalRotation;
	local Projectile Proj;

	if ( IsInState('Dying') || Health <= 0 )
		return;

	if ( Role == ROLE_Authority )
	{
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
	if ( WorldInfo.NetMode != NM_DedicatedServer && FireSound != None )
		PlaySound(FireSound, true);
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
	if ( Controller != None && InstigatedBy != None && InstigatedBy.Pawn != None )
	{
		ToxikkMonsterController(Controller).LockOnTo(InstigatedBy.Pawn);
		SetDesiredRotation(Rotator(InstigatedBy.Pawn.Location - Location));
	}

	if ( Damage <= 0 )
		return;

	// hitsounds/hitmarkers for player
	if ( CRZPlayerController(InstigatedBy) != None )		
		CRZPlayerController(InstigatedBy).ConfirmHit(Damage);

	// say "ouch"
	if ( PainSound != None && FRand() >= PainSoundChance )
		PlaySound(PainSound);

	// spill some blood
	BloodMomentum = Momentum;
	if ( BloodMomentum.Z > 0 )
		BloodMomentum.Z *= 0.5;
}

static function string GetMonsterName()
{
	if (default.MonsterName ~= "")
		return string(default.Class);
	else
		return default.MonsterName;
}

DefaultProperties
{
	BossYaw=32768
	ShakeDamage=0
	ShakeDistance=1500

	RagdollLifespan=6
	GibSound=SoundCue'Snd_Character_Grunts.SoundCues.SFX_Grunt_Male_DeathInstant_Cue'
	CrushedSound=SoundCue'snd_character_general.Damage_Effects.A_Character_DamageEffect_CrushedCue'
	//TODO: get some yellow/green blood and gibs...
	BloodSplatterDecalMaterial=MaterialInstanceTimeVarying'T_FX.DecalMaterials.MITV_FX_OilDecal_Small01'
	GibExplosionTemplate=ParticleSystem'Gore_Explosion.Particles.P_Gore_Explosion'
	BloodEffects[0]=(Template=ParticleSystem'Gore_Impact.Particles.P_Gore_Impact_Near',MinDistance=750.0)//ParticleSystem'T_FX.Effects.P_FX_Bloodhit_Corrupt_Far'
	BloodEffects[1]=(Template=ParticleSystem'Gore_Impact.Particles.P_Gore_Impact_Near',MinDistance=350.0) //ParticleSystem'T_FX.Effects.P_FX_Bloodhit_Corrupt_Mid'
	BloodEffects[2]=(Template=ParticleSystem'Gore_Impact.Particles.P_Gore_Impact_Near',MinDistance=0.0)
	BloodEmitterClass=class'UTGame.UTEmit_BloodSpray'
	Gibs[0]=(BoneName=head, GibClass=class'CRZGib_Bright_Male01_Head', bHighDetailOnly=false)
	//TODO: define more gibs, different for each monster (depending on their bones...)
	/*
	HeadGib=(BoneName=b_Head,			GibClass=class'CRZGib_Bright_Male01_Head',              bHighDetailOnly=true)
	Gibs[0]=(BoneName=b_LeftArm,		GibClass=class'CRZGib_Bright_Male01_LeftArm',           bHighDetailOnly=false)
	Gibs[1]=(BoneName=b_RightForeArm,	GibClass=class'CRZGib_Bright_Male01_RightArm_Lower',    bHighDetailOnly=true)
	Gibs[2]=(BoneName=b_LeftLeg,		GibClass=class'CRZGib_Bright_Male01_LeftLeg_Lower',     bHighDetailOnly=false)
	Gibs[3]=(BoneName=b_LeftLegUpper,	GibClass=class'CRZGib_Bright_Male01_LeftLeg_Upper',     bHighDetailOnly=true)
	Gibs[4]=(BoneName=b_RightLeg,		GibClass=class'CRZGib_Bright_Male01_RightLeg_Lower',    bHighDetailOnly=true)
	Gibs[5]=(BoneName=b_RightLegUpper,	GibClass=class'CRZGib_Bright_Male01_RightLeg_Upper',    bHighDetailOnly=false)
	Gibs[6]=(BoneName=b_Hips,			GibClass=class'CRZGib_Bright_Male01_Hip',               bHighDetailOnly=true)
	Gibs[7]=(BoneName=b_Spine,			GibClass=class'CRZGib_Bright_Male01_Torso',             bHighDetailOnly=true)
	*/
	
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
	
	ControllerClass=class'ToxikkMonsterController'

	// Monsters can't jump
    bJumpCapable=true
    bCanJump=true
	
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
	PunchDegrees=60
	PunchMomentum=1000

	ProjDamageMult=1.0

	AttackDistance=92
	
	RunningAnim=Walk
	
	SightChance=0.25
	
	SightAnims(0)=Sight
	
	SightRadius=500000
	
	RangedDelay=1.0
	
	PreRotateModifier=2.0
	
	TorsoName=Default
	bUseAimOffset=true
	
	// 0% chance
	CrawlChance=0.0
	ChatterTime=10.0
	
	bAvoidLedges=false
	bStopAtLedges=false
	
	FaceRate=1000
	
	MonsterName=""
}
