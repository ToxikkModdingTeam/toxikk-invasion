//--TOXIKK INVASION MONSTER CONTROLLER------------------------------
//------------------------------------------------------------------

Class ToxikkMonsterController extends AIController;

// Pawn we're following
var Actor Target, RoamTarget;
var Vector TempDest;
var vector nextlocation;

// How far the player can go before we lose sight of him
var float PerceptionDistance;
var float DistanceToPlayer;
var rotator DesiredRot;
var bool bCanRanged;
var float RangedTimer;

// timestamp to relocate monster when nothing happens for too long
var float LastTimeSomethingHappened;

// local state vars - made global because they crash the game goddamnit!!!!!!
var int tmp_i;
var Vector tmp_V, tmp_PL, tmp_VL;
var float tmp_Timer, tmp_TimerGoal, tmp_Dist;

function vector PosPlusHeight(vector Pos)
{
	local float CR, CH;
	
	GetBoundingCylinder (CR, CH);
	
	Pos.Z += CH/2;
	
	return Pos;
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

// Acquire a new target
simulated function LockOnTo(Pawn Seen)
{
	if (Target != Seen)
	{
		// Never lock onto other monsters, or ourselves
		if (ToxikkMonster(Seen) != None || Seen == Pawn)
			return;
			
		Target = Seen;
		ToxikkMonster(Pawn).SeenSomething();

		LastTimeSomethingHappened = WorldInfo.TimeSeconds;

		if (FRand() >= ToxikkMonster(Pawn).SightChance)
			GotoState('Sight');
		else
			GotoState('ChasePlayer');
	}
}

//--ROTATING TOWARD OUR TARGET AND PREPARING FOR AN ATTACK, USED FOR RANGED
state PreAttack
{
	Begin:
		BeginNotify("PreAttack");
		Pawn.Acceleration = vect(0,0,1);
		
		// Make our pawn rotate twice as quickly
		Pawn.RotationRate.Yaw = Pawn.default.RotationRate.Yaw * ToxikkMonster(Pawn).PreRotateModifier;
		//`Log(Pawn.RotationRate.Yaw);
		
		while ((GetInFront(Pawn, Target) == 0.0 || GetInFront(Pawn, Target) < 0.0) && FastTrace(Target.Location, PosPlusHeight(Pawn.Location)) && VSize(Target.Location - Pawn.Location) <= ToxikkMonster(Pawn).SightRadius)
		{
			Pawn.Acceleration = vect(0,0,1);
			
			if (Target == None)
				GotoState('Wander');
				
			SetFocalPoint(Target.Location);
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
	simulated function Tick(float Delta)
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
	simulated function Tick(float Delta)
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
		
		ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).SightAnims[tmp_i],ToxikkMonster(Pawn).SightSound);
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
	
	simulated function Tick(float Delta)
	{
		super.Tick(Delta);
		
		if (Target != None)
			LockOnTo(Pawn(Target));
	}
	
	Begin:
		BeginNotify("Idling");
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
		
		Target = FindPathToward(RoamTarget);
		
		if (Target != None)
		{
			// `Log("Moving toward roam destination.");
			MoveToward(Target);
		}
		else
		{
			RoamTarget = FindRandomDest();
			// `Log("Finding new target.");
		}
		
		//Sleep(0.5);
		Sleep(5.0);
		
	if (Pawn(Target) == None)
		GotoState('Wander');
}


//--MONSTER IS DOING A MELEE ATTACK----------------------------------------------------------------
state Attacking
{
	simulated function Tick(float Delta)
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
		ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).MeleeAttackAnims[tmp_i],ToxikkMonster(Pawn).AttackSound);
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

simulated function RangedException();

//--MONSTER IS DOING A RANGED ATTACK----------------------------------------------------------------
state RangedAttack
{	
	simulated function Tick(float Delta)
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

state ChasePlayer
{	
	simulated function Tick(float Delta)
	{
		super.Tick(Delta);
		RangedTimer += Delta;
	}
	
  Begin:
	BeginNotify("ChasePlayer");
    Pawn.Acceleration = vect(0,0,1);
	
    While (Pawn != none && Target != None)
    {
		// Allow trace too, because that means we're pretty much on the same level
		// Run some Z checks just to be sure they're not up on a ledge or something
		if (NavigationHandle.ActorReachable(Target) || ActorReachable(Target) || (FastTrace(Target.Location,Pawn.Location) && Target.Location.Z < Pawn.Location.Z+100 && Target.Location.Z > Pawn.Location.Z - 25))
		{
			DistanceToPlayer = VSize(Target.Location - Pawn.Location);
			
			// CAN WE MELEE ATTACK?
			if (DistanceToPlayer <= ToxikkMonster(Pawn).AttackDistance && GetInFront(Pawn, Target) > 0.0 && ToxikkMonster(Pawn).bHasMelee)
			{
				GotoState('Attacking');
				break;
			}
			// OTHERWISE, CAN WE RANGED ATTACK?
			else if (DistanceToPlayer <= ToxikkMonster(Pawn).RangedAttackDistance && ToxikkMonster(Pawn).bHasRanged && FastTrace(Target.Location, PosPlusHeight(Pawn.Location)) && RangedTimer >= ToxikkMonster(Pawn).RangedDelay && ExtraRangedException())
			{
				GotoState('PreAttack');
				break;
			}
			else
				MoveToward(Target, Target, 20.0f);
		}
		// Otherwise, use pathfinding
		else
		{
			MoveTarget = FindPathToward(Target,,PerceptionDistance + (PerceptionDistance/2));
			if (MoveTarget != none)
			{
				//Worldinfo.Game.Broadcast(self, "Moving toward Player");

				DistanceToPlayer = VSize(MoveTarget.Location - Pawn.Location);
				tmp_Dist = VSize(Target.Location - Pawn.Location);
				
				// CAN WE MELEE ATTACK?
				if (tmp_Dist <= ToxikkMonster(Pawn).AttackDistance && GetInFront(Pawn, Target) > 0.0 && ToxikkMonster(Pawn).bHasMelee)
				{
					GotoState('Attacking');
					break;
				}
				// OTHERWISE, CAN WE RANGED ATTACK?
				else if (tmp_Dist <= ToxikkMonster(Pawn).RangedAttackDistance && GetInFront(Pawn, Target) > 0.0 && ToxikkMonster(Pawn).bHasRanged && FastTrace(Target.Location, Pawn.Location) && RangedTimer >= ToxikkMonster(Pawn).RangedDelay && ExtraRangedException())
				{
					GotoState('RangedAttack');
					break;
				}
				else
				{
					if (tmp_Dist < 200)
						MoveToward(Target, Target, 20.0f);
					else if (DistanceToPlayer < 200)
						MoveToward(MoveTarget, Target, 20.0f);
					else
						MoveToward(MoveTarget, MoveTarget, 20.0f);	
				}
			}
		}
		
		if (Target != None)
		{
			// If the target dies then find a new one
			if (Pawn(Target).Health <= 0)
				Target = None;
		}

		Sleep(0.01);
		
		// NO TARGET? Idle
		if (Target == None)
			GotoState('Wander');
    }
}

// Optional things can be done when a state begins
function BeginNotify(string StateName);

defaultproperties
{
	PerceptionDistance=10000
}
