//--TOXIKK INVASION MONSTER CONTROLLER------------------------------
//------------------------------------------------------------------

Class ToxikkMonsterController extends AIController;

// Pawn we're following
var Actor Target, RoamTarget, TempTarget;
var Vector TempDest;
var vector nextlocation;
// How far the player can go before we lose sight of him
var float PerceptionDistance;
var float DistanceToPlayer;
var rotator DesiredRot;
var bool bCanRanged;
var float RangedTimer;
var actor LastReached;			// When we generate a new path, node 0 MUST NOT be the last one reached

var bool bUseDetours;
var int o;

// timestamp to relocate monster when nothing happens for too long
var float LastTimeSomethingHappened;

// local state vars - made global because they crash the game goddamnit!!!!!!
var int tmp_i;
var Vector tmp_V, tmp_PL, tmp_VL;
var float tmp_Timer, tmp_TimerGoal, tmp_Dist;

// UGLY HACK
var			float			SmallBoxSize;
var			UDKJumpPad		PreviousPad;				// The jump pad that we just touched
var			bool			bExitPadState;				// If true, we need to go back to roaming

function vector PosPlusHeight(vector Pos)
{
	local float CR, CH;
	
	GetBoundingCylinder (CR, CH);
	
	Pos.Z += CH/2;
	
	return Pos;
}

static function vector PosCenter(Pawn P)
{
	local Vector V;
	
	V = P.Location;
	V.Z += P.CylinderComponent.CollisionHeight/2;
	
	return V;
}

event PostBeginPlay()
{
	// local CRZJumpPad Pad;
	
    super.PostBeginPlay();
 
    NavigationHandle = new(self) class'NavigationHandle';
	
	`Log("TRYING TO INCREASE PAD HEIGHT");
	
	// HACK, INCREASE JUMP Z
	/*
	forEach AllActors(Class'CRZJumpPad',Pad)
	{
		Pad.JumpVelocity *= 1.25;
		`Log("INCREASED PAD HEIGHT");
	}
	*/
}

// Possess a pawn
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	local CRZPawn CRZ;
	local int Attempts;
	
    super.Possess(inPawn, bVehicleTransition);

    Pawn.SetMovementPhysics();

	LastTimeSomethingHappened = WorldInfo.TimeSeconds;

	if (ToxikkMonster(inPawn).bForceInitialTarget)
	{
		do
		{
			ForEach DynamicActors(Class'CRZPawn',CRZ)
			{
				if (FRand() >= 0.6)
				{
					LockOnTo(CRZ);
					Attempts = 16;
					break;
				}
			}
			
			Attempts ++;
		} until (Target != None || Attempts > 15);
	}
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

// Are we using a jump pad?
function bool IsUsingPad() {return false;}

// Acquire a new target
function bool LockOnTo(Pawn Seen)
{
	local Vector MyRot;
	local float Dist1, Dist2, Dot1, Dot2;

	// Uncomment to force this monster into wander
	//return;
	
	if (Seen == None)
		return false;
		
	if (Target != Seen)
	{
		// Never lock onto other monsters, or ourselves
		if (ToxikkMonster(Seen) != None || Seen == Pawn)
			return false;

		// Don't change target if current Target is better/easier than Seen
		if ( Pawn(Target) != None && LineOfSightTo(Target) )
		{
			if ( LineOfSightTo(Seen) )
			{
				// Both have LoS, check which one is most in front, but also favor closer target
				MyRot = Vector( Pawn.Rotation.yaw*Rot(0,1,0) );
				Dist1 = VSize(Target.Location - Pawn.Location);
				Dist2 = VSize(Seen.Location - Pawn.Location);
				Dot1 = 3.0 + (MyRot Dot (Target.Location-Pawn.Location)/Dist1);
				Dot2 = 3.0 + (MyRot Dot (Seen.Location-Pawn.Location)/Dist2);
				if ( Dot1/Sqrt(Dist1) > Dot2/Sqrt(Dist2) )
					return false;
			}
			// Target has LoS but not Seen, keep Target
			else
				return false;
		}
		// Neither have LoS, keep the most recent (==Seen)

		Target = Seen;
		ToxikkMonster(Pawn).SeenSomething();

		LastTimeSomethingHappened = WorldInfo.TimeSeconds;

		if (FRand() >= ToxikkMonster(Pawn).SightChance)
			GotoState('Sight');
		else
			GotoState('ChasePlayer');
	}
	return true;
}

//--ROTATING TOWARD OUR TARGET AND PREPARING FOR AN ATTACK, USED FOR RANGED
state PreAttack
{
	`DEBUG_MONSTER_STATE_DECL
	Begin:
		BeginNotify("PreAttack");
		Pawn.Acceleration = vect(0,0,1);
		
		// Make our pawn rotate twice as quickly
		Pawn.RotationRate.Yaw = Pawn.default.RotationRate.Yaw * ToxikkMonster(Pawn).PreRotateModifier;
		//`Log(Pawn.RotationRate.Yaw);
		
		while ((GetInFront(Pawn, Target) == 0.0 || GetInFront(Pawn, Target) < 0.0) && FastTrace(Target.Location, PosPlusHeight(Pawn.Location)) && VSize(Target.Location - Pawn.Location) <= ToxikkMonster(Pawn).SightRadius)
		{
			Pawn.Acceleration = vect(0,0,1);
			
			// Lost a target, go back to roaming around
			if (Target == None)
				GotoState('Wander');
				
			//SetFocalPoint(Target.Location);
			
			DesiredRot.Pitch = Pawn.Rotation.Pitch;
			DesiredRot.Roll = Pawn.Rotation.Roll;
			DesiredRot.Yaw = Pawn.Rotation.Yaw + ToxikkMonster(Pawn).FaceRate;
			Pawn.SetRotation(DesiredRot);
			Sleep(0.01);
		}
		
		DistanceToPlayer = VSize(Target.Location - Pawn.Location);
		
		Pawn.RotationRate.Yaw = Pawn.default.RotationRate.Yaw;

		// MELEE ATTACK?
		if (DistanceToPlayer <= ToxikkMonster(Pawn).AttackDistance && ToxikkMonster(Pawn).bHasMelee)
				GotoState('Attacking');
		// OTHERWISE, CAN WE RANGED ATTACK?
		else if (DistanceToPlayer <= ToxikkMonster(Pawn).RangedAttackDistance && ToxikkMonster(Pawn).bHasRanged && FastTrace(Target.Location, Pawn.Location))
				GotoState('RangedAttack');
		else
		{
			if (Target != None)
				GotoState('ChasePlayer');
			else
				GotoState('Wander');
		}
}

//--DOING OUR LUNGE ATTACK---------------------------
state Lunging
{
	`DEBUG_MONSTER_STATE_DECL

	function Tick(float Delta)
	{
		super.Tick(Delta);
		SetRotation(DesiredRot);
	}
	
	Begin:
		BeginNotify("Lunging");
		DesiredRot = Rotation;
		Pawn.Acceleration = vect(0,0,1);
		// `Log("Preparing to lunge...");
		
		// PRE-LUNGE
		ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).LungeStartAnim);
		Sleep(ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).LungeStartAnim));
		
		// MID-LUNGE
		tmp_V = Normal(Target.Location-Pawn.Location) * ToxikkMonster(Pawn).LungeSpeed;
		tmp_V.Z += 260;
		Pawn.Velocity = tmp_V;
		Pawn.SetPhysics(PHYS_Falling);
		ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).LungeMidAnim);
		ToxikkMonster(Pawn).bIsLunging = true;
		
		while (ToxikkMonster(Pawn).bIsLunging)
		{
			Sleep(0.01);
		}
		
		// POST-LUNGE
		ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).LungeEndAnim);
		Sleep(ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).LungeEndAnim));
		
		// Don't crawl anymore
		ToxikkMonster(Pawn).SetCrawling(false);
		
		RangedTimer=0.0;
		
		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Wander');
}


// PLAYING SIGHT ANIM
state Sight
{
	`DEBUG_MONSTER_STATE_DECL

	function Tick(float Delta)
	{
		super.Tick(Delta);
		SetRotation(DesiredRot);
	}
	
	Begin:
		BeginNotify("Sight");
		DesiredRot = Rotation;
		Pawn.Acceleration = vect(0,0,1);
		
		if (ToxikkMonster(Pawn).bIsBossMonster)
			ToxikkMonster(Pawn).SetBossCamera(true);
		
		tmp_i = Rand(ToxikkMonster(Pawn).SightAnims.Length);
		
		// `Log("Playing sight anim"@string(i)$"...");
		
		ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).SightAnims[tmp_i]);
		Pawn.PlaySound(ToxikkMonster(Pawn).SightSound);
		Sleep(ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).SightAnims[tmp_i]));
		
		if (ToxikkMonster(Pawn).bIsBossMonster)
			ToxikkMonster(Pawn).SetBossCamera(false);
		
		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Wander');
}


// IN THIS STATE, WE'RE DOING NOTHING
state Idling
{
	`DEBUG_MONSTER_STATE_DECL

	// Change targets if we actually see the player in front of us
	event SeePlayer(Pawn Seen)
	{
		super.SeePlayer(Seen);
		LockOnTo(Seen);
	}
	
	// If the player shoots then see him
	event HearNoise(float Loudness, Actor NoiseMaker, optional name NoiseType)
	{
		if (CRZPawn(Noisemaker) != None)
			LockOnTo(Pawn(NoiseMaker));
		if (Weapon(NoiseMaker) != None)
			LockOnTo(Weapon(NoiseMaker).Instigator);
	}
	
	function Tick(float Delta)
	{
		super.Tick(Delta);
		
		if (Target != None)
			LockOnTo(Pawn(Target));
	}
	
	Begin:
		BeginNotify("Idling");
}

// -- DISGUSTING PATH HACK - Forces the pathfinding system to find a path
// -- This should only be used in "blind walk" mode, AKA if the monster ABSOLUTELY CANNOT find a path
// -- TODO: CHECK ALL PATH NODES IN ROUTECACHE TO SEE IF THIS PAWN WILL RUN INTO A WALL
simulated function Actor HackPath(Actor Toward, optional bool bDetour, optional int MaxLength, optional bool bPartial)
{
	local Actor MT;
	local float OldRadius, OldHeight;
	local float SubDistance;

	//1. backup monster values that will be modified
	OldRadius = ToxikkMonster(Pawn).CylinderComponent.CollisionRadius;
	OldHeight = ToxikkMonster(Pawn).CylinderComponent.CollisionHeight;

	//2. modify monster for better pathfinding
	ToxikkMonster(Pawn).CylinderComponent.SetCylinderSize(SmallBoxSize,SmallBoxSize);
	Pawn.bCanPickupInventory = true;

	//3. Call pathfinding
	MT = FindPathToward(Toward,bDetour,MaxLength,bPartial);
	
	//4. Restore values
	ToxikkMonster(Pawn).CylinderComponent.SetCylinderSize(OldRadius,OldHeight);
	Pawn.bCanPickupInventory = false;
	
	// -- DELETE THE FUCKIN FIRST NODE IF WE'RE ALREADY CLOSE TO IT, might prevent getting stuck
	if (RouteCache.Length > 1)
	{
		SubDistance = VSize(RouteCache[0].Location - Pawn.Location) - CylinderComponent(Pawn.CollisionComponent).CollisionRadius;
		if (SubDistance <= 30 && ActorReachable(RouteCache[0]))
		{
			//`Log("REMOVED CACHE 0");
			RouteCache.RemoveItem(RouteCache[0]);
			MT = RouteCache[0];
		}
	}
	
	return MT;
}

// ROAM AND LOOK FOR A PLAYER
auto state Wander
{
	// Change targets if we actually see the player in front of us
	event SeePlayer(Pawn Seen)
	{
		super.SeePlayer(Seen);
		LockOnTo(Seen);
	}
	
	// If the player shoots then see him
	event HearNoise(float Loudness, Actor NoiseMaker, optional name NoiseType)
	{
		if (CRZPawn(Noisemaker) != None)
			LockOnTo(Pawn(NoiseMaker));
		if (Weapon(NoiseMaker) != None)
			LockOnTo(Weapon(NoiseMaker).Instigator);
	}
	
	Begin:
		BeginNotify("Wander");
		// `Log("Begin wander");
		if (RoamTarget == None || Pawn.ReachedDestination(RoamTarget))
			RoamTarget = FindRandomDest();
		
		// Don't use HackPath here, it's okay if we can't use jump pads
		Target = FindPathToward(RoamTarget,bUseDetours);
		
		if (Target != None)
		{
			// `Log("Moving toward roam destination.");
			MoveToward(Target);
		}
		else
		{
			RoamTarget = FindRandomDest();
			if (RouteCache.length > 0)
				MoveToward(RouteCache[0]);

			// `Log("Finding new target.");
		}
		
		//Sleep(0.5);
		Sleep(0.1);
		
	if (Pawn(Target) == None)
		GotoState('Wander');
}


//--MONSTER IS DOING A MELEE ATTACK----------------------------------------------------------------
state Attacking
{
	`DEBUG_MONSTER_STATE_DECL

	function Tick(float Delta)
	{
		super.Tick(Delta);

		SetRotation(DesiredRot);
		if (Target != None)
		{
			if (Pawn(Target).Health <= 0)
				Target = None;
			else
			{
				if (ToxikkMonster(Pawn).bWalkingAttack)
					DesiredRot = Rotator(Target.Location - Pawn.Location);
			}
		}

		tmp_Timer += Delta;
	}
	
	Begin:
		BeginNotify("Attacking");
		LastTimeSomethingHappened = WorldInfo.TimeSeconds;
		
		DesiredRot = Rotation;
		Pawn.Acceleration = vect(0,0,1);
		
		tmp_i = Rand(ToxikkMonster(Pawn).MeleeAttackAnims.Length);
		ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).MeleeAttackAnims[tmp_i]);
		
		if (ToxikkMonster(Pawn).AttackSound != None)
			Pawn.PlaySound(ToxikkMonster(Pawn).AttackSound);
		
		tmp_TimerGoal = ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).MeleeAttackAnims[tmp_i]);
		tmp_Timer = 0;
		while (tmp_Timer < tmp_TimerGoal)
		{
			if (Target != None && ToxikkMonster(Pawn).bWalkingAttack)
				MoveToward(Target, Target, 20.0f);
				
			Sleep(0.01);
		}
		
		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Wander');
}

function RangedException();

//--MONSTER IS DOING A RANGED ATTACK----------------------------------------------------------------
state RangedAttack
{
	`DEBUG_MONSTER_STATE_DECL

	function Tick(float Delta)
	{
		super.Tick(Delta);
		SetRotation(DesiredRot);
		Pawn.SetDesiredRotation(DesiredRot);
		if (Target != None)
		{
			if (Pawn(Target).Health <= 0)
				Target = None;
			else
			{
				if (ToxikkMonster(Pawn).bWalkingRanged)
					DesiredRot = Rotator(Target.Location - Pawn.Location);
			}
		}
		
		tmp_Timer += Delta;
	}
	
	Begin:
		BeginNotify("RangedAttack");
		LastTimeSomethingHappened = WorldInfo.TimeSeconds;
		
		RangedException();
		
		if (FRand() >= ToxikkMonster(Pawn).LungeChance && ToxikkMonster(Pawn).bHasLunge)
		{
			// If the monster has lunge while crouched then check if they're crouched

			if ( !ToxikkMonster(Pawn).bLungeIfCrouched || ToxikkMonster(Pawn).bIsCrawling )
				GotoState('Lunging');
		}

		// Face the player
		DesiredRot = Rotator(Target.Location - Pawn.Location);
		Pawn.Acceleration = vect(0,0,1);
		
		if (ToxikkMonster(Pawn).CrouchedRangedAnims.Length > 0 && ToxikkMonster(Pawn).bIsCrawling)
			tmp_i = Rand(ToxikkMonster(Pawn).CrouchedRangedAnims.Length);
		else
			tmp_i = Rand(ToxikkMonster(Pawn).RangedAttackAnims.Length);
			
		if (ToxikkMonster(Pawn).CrouchedRangedAnims.Length > 0 && ToxikkMonster(Pawn).bIsCrawling)
		{
			ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).CrouchedRangedAnims[tmp_i]);
			tmp_TimerGoal = ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).CrouchedRangedAnims[tmp_i]);
		}
		else
		{
			ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).RangedAttackAnims[tmp_i]);
			tmp_TimerGoal = ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).RangedAttackAnims[tmp_i]);
		}
		tmp_Timer = 0;
		while (tmp_Timer < tmp_TimerGoal)
		{
			if (Target != None && ToxikkMonster(Pawn).bWalkingRanged)
				MoveToward(Target, Target, 20.0f);
				
			Sleep(0.01);
		}
		
		RangedTimer = 0.0;
		
		// Decide if we should go into crawl mode or not
		if (FRand() >= 1.0-ToxikkMonster(Pawn).CrawlChance)
			ToxikkMonster(Pawn).SetCrawling(true);
		
		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Wander');
}

function bool ExtraRangedException()
{
	return true;
}

// Returns whether or not two actors are on the same level
static function bool OnSameLevel(Actor Parent, Actor Targ)
{
	if (Pawn(Targ) != None)
		return Pawn(Parent).Controller.CanSee(Pawn(Targ)) && Targ.Location.Z < Parent.Location.Z+100 && Targ.Location.Z > Parent.Location.Z - 25;
	else
		return Parent.FastTrace(Targ.Location,Parent.Location) && Targ.Location.Z < Parent.Location.Z+100 && Targ.Location.Z > Parent.Location.Z - 25;
}

// Whether or not we should do a melee attack
static function bool CanDoMelee(Pawn Parent, Pawn Targ)
{
	local float DistDifference;
	
	// Both have to be actual existing pawns
	if (Parent == None || Targ == None || ToxikkMonster(Parent) == None)
		return false;
		
	DistDifference = VSize(Targ.Location - Parent.Location);
	return DistDifference <= ToxikkMonster(Parent).AttackDistance && /*Class'ToxikkMonster'.Static.GetInFront(Parent, Targ) > 0.0*/ Parent.Controller.CanSee(Targ) && ToxikkMonster(Parent).bHasMelee;
}

// Whether or not we should do a ranged attack
static function bool CanDoRanged(Pawn Parent, Pawn Targ)
{
	local float DistDifference;
	
	if (ToxikkMonster(Parent).bHeadless && ToxikkMonster(Parent).bNoHeadlessRanged)
		return false;
	
	// Both have to be actual existing pawns
	if (Parent == None || Targ == None || ToxikkMonster(Parent) == None)
		return false;
		
	DistDifference = VSize(Targ.Location - Parent.Location);
	return DistDifference <= ToxikkMonster(Parent).RangedAttackDistance && /*Class'ToxikkMonster'.Static.GetInFront(Parent, Targ) > 0.0 &&*/ ToxikkMonster(Parent).bHasRanged && Parent.FastTrace(Class'ToxikkMonsterController'.Static.PosCenter(Parent),Class'ToxikkMonsterController'.Static.PosCenter(Targ)) && ToxikkMonsterController(Parent.Controller).RangedTimer >= ToxikkMonster(Parent).RangedDelay && ToxikkMonsterController(Parent.Controller).ExtraRangedException();
}

// WE GO TO THIS STATE AFTER WE HIT A JUMP PAD
// Basically ensure that the monster reaches its destination properly
state PadAir
{
	`DEBUG_MONSTER_STATE_DECL

	function bool IsUsingPad() {return true;}
	
	Begin:
		While (PreviousPad != None && !bExitPadState)
		{
			// IF WE CAN SEE THE PLAYER AND HE'S BELOW US THEN JUST MOVE TOWARD HIM
			// Helps on some maps like Novus where monsters can only fall onto a pad
			if (Pawn(Target) != None && FastTrace(PosCenter(Pawn),PosCenter(Pawn(Target))) && Target.Location.Z <= Pawn.Location.Z)
				MoveTo(Target.Location,Target);
			else
				MoveTo(PreviousPad.JumpTarget.Location,PreviousPad.JumpTarget);
				
			sleep(0.01);
		}
		
		// -- CLEAR OUR PATHS SO WE HAVE TO RECALCULATE
		RoamTarget = None;
		MoveTarget = None;
		TempTarget = None;
		
		bExitPadState=false;
		PreviousPad = None;
		
		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Wander');
}

state ChasePlayer
{
	`DEBUG_MONSTER_STATE_DECL

	function Tick(float Delta)
	{
		super.Tick(Delta);

		RangedTimer += Delta;
	}
	
  Begin:
	BeginNotify("ChasePlayer");
    Pawn.Acceleration = vect(0,0,1);
	
    While (Pawn != none && Target != None)
    {
		//class'NavmeshPath_Toward'.static.TowardGoal(NavigationHandle,Target);
        //class'NavMeshGoal_At'.static.AtLocation(NavigationHandle,Target.Location);
		ToxikkMonster(Pawn).bUsingStraightPath=false;
		ToxikkMonster(Pawn).bBlindWalk=false;
				
		// The player is directly in our line of sight and on the same level, so use them as a target and walk toward them

		//NOTE: This needs to be reworked - the line of sight should be separate from the "on same level" check.
		// For ranged attacks, you need to check line of sight, but we don't care if it is on same level or not.
		// The "on same level" check is only relevant for melee and for MoveToward.

		if (ActorReachable(Target) && OnSameLevel(Pawn,Target))
		{
			//`Log("BOTH CONDITIONS ARE TRUE");
			DistanceToPlayer = VSize(Target.Location - Pawn.Location);
			ToxikkMonster(Pawn).bUsingStraightPath=true;
			
			// CAN WE MELEE ATTACK?
			if ( CanDoMelee(Pawn,Pawn(Target)) )
			{
				GotoState('Attacking');
				break;
			}
			// OTHERWISE, CAN WE RANGED ATTACK?
			else if ( CanDoRanged(Pawn,Pawn(Target)) )
			{
				RangedTimer = 0;
				GotoState('PreAttack');
				break;
			}
			else
			{
				if (!IsUsingPad())
				{
					//`Log("MOVING TOWARD IN BOTH...");
					MoveToward(Target, Target, 20.0f);
				}
			}
		}
		// Otherwise, use pathfinding
		else
		{
			//NOTE: Same thing here, if we can ranged attack, we don't care about the MoveTarget being none or not.
			// The attacking checks should be done in priority, and only then, do the pathing/movement IF we were not able to attack...

			// -- FIRST START WITH HACK PATH
			MoveTarget = HackPath(Target,bUseDetours,PerceptionDistance + (PerceptionDistance/2));
			
			if (LastReached != MoveTarget)
				LastReached = MoveTarget;
			else if (RouteCache.Length > 1)
			{
				RouteCache.RemoveItem(RouteCache[0]);
				MoveTarget = RouteCache[0];
				LastReached = MoveTarget;
				//`Log("OVERRODE LASTREACHED");
			}

			// -- DOES A JUMP PAD EXIST?
			if (MoveTarget != None)
			{
				for (o=0; o<RouteCache.length; o++)
				{
					if (UDKJumpPad(RouteCache[o]) != None)
					{
						TempTarget = FindPathToward(RouteCache[o],bUseDetours,PerceptionDistance + (PerceptionDistance/2));
						
						// Could not reach this jump pad
						if (TempTarget == None)
						{
							MoveTarget = None;
							break;
						}
						
						// We can reach the jump pad, set that to our end target
						else
							MoveTarget = TempTarget;
					}
				}
			}
			
			// If the jump pad route didn't work, then let's do a failsafe
			if (MoveTarget == None)
			{
				Target = None;
				GotoState('Wander');
			}
			
				//MoveTarget = FindPathToward(Target,bUseDetours,PerceptionDistance + (PerceptionDistance/2));
				
				//Target = None;
				//GotoState('Wander');
				//MoveTarget = HackPath(Target,bUseDetours,PerceptionDistance + (PerceptionDistance/2));
			
			`Log("WE MADE IT THIS FAR");
			
			if (VSize(MoveTarget.Location - Pawn.Location) <= Pawn.CylinderComponent.CollisionRadius)
			{
				`Log("SWAPPED TO CACHE 1");
				MoveTarget = RouteCache[1];
			}
			
			if (MoveTarget != none)
			{
				DistanceToPlayer = VSize(MoveTarget.Location - Pawn.Location);
				tmp_Dist = VSize(Target.Location - Pawn.Location);
				
				// CAN WE MELEE ATTACK?
				if ( CanDoMelee(Pawn,Pawn(Target)) )
				{
					GotoState('Attacking');
					break;
				}
				// OTHERWISE, CAN WE RANGED ATTACK?
				else if ( CanDoRanged(Pawn,Pawn(Target)) )
				{
					GotoState('RangedAttack');
					break;
				}
				else
				{
					// If the player's within 200 units AND ON THE SAME LEVEL then just move toward them
					if (tmp_Dist < 200 && OnSameLevel(Pawn,Target))
					{
						`Log("MOVING STRAIGHT TOWARD IT");
						MoveToward(Target, Target, 20.0f);
					}
						
					// If the movement target's destination is less than 200
					// WHY WAS THIS ADDED I DON'T GET IT
					//else if (DistanceToPlayer < 200)
					//{
						//if (!IsUsingPad())
							//MoveToward(MoveTarget, Target, 20.0f);
					//}
					
					// Otherwise just move normally
					else
					{
						// -- THIS IS WHERE IT GETS STUCK WHEN THE POINT IS RIGHT IN FRONT OF IT - WHY? CHECK REACHEDDESTINATION --
						if (!IsUsingPad())
						{
							`Log("VERY BOTTOM STUCK POINT");
							MoveToward(MoveTarget, MoveTarget, 20.0f);	
						}
					}
				}
			}
			else
			{
				`Log("BLIND WALK");
				ToxikkMonster(Pawn).bBlindWalk=true;
				if (!IsUsingPad())
					MoveToward(Target, Target, 20.0f);
			}
		}
		
		if (Target != None)
		{
			// If the target dies then find a new one
			if (Pawn(Target).Health <= 0)
				Target = None;
		}

		Sleep(0.1);
		
		// NO TARGET? Idle
		if (Target == None)
			GotoState('Wander');
    }
	
	// NO TARGET? Idle
	if (Target == None)
		GotoState('Wander');
}

// Optional things can be done when a state begins
function BeginNotify(string StateName);

defaultproperties
{
	PerceptionDistance=10000
	bCanDoSpecial=true
	
	SmallBoxSize = 8.0
	
	bUseDetours=false
}
