//--TOXIKK INVASION MONSTER CONTROLLER------------------------------
//------------------------------------------------------------------

Class ToxikkMonsterController extends AIController;

// Pawn we're following
var Actor Target, RoamTarget;
var() Vector TempDest;
var vector nextlocation;

// How far the player can go before we lose sight of him
var float PerceptionDistance;
var float DistanceToPlayer;
var rotator DesiredRot;
var bool bCanRanged;
var float RangedTimer;

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

event PostBeginPlay()
{
	super.PostBeginPlay();
	NavigationHandle = new(self) class'NavigationHandle';
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
		Pawn.Acceleration = vect(0,0,1);
		
		// Make our pawn rotate twice as quickly
		Pawn.RotationRate.Yaw = Pawn.default.RotationRate.Yaw * ToxikkMonster(Pawn).PreRotateModifier;
		`Log(Pawn.RotationRate.Yaw);
		
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
	local int i;
	local vector V;
	
	simulated function Tick(float Delta)
	{
		super.Tick(Delta);
		SetRotation(DesiredRot);
	}
	
	Begin:
		DesiredRot = Rotation;
		Pawn.Acceleration = vect(0,0,1);
		// `Log("Preparing to lunge...");
		
		// PRE-LUNGE
		ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).LungeStartAnim);
		Sleep(ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).LungeStartAnim));
		
		// MID-LUNGE
		V = Normal(Target.Location-Pawn.Location) * ToxikkMonster(Pawn).LungeSpeed;
		V.Z += 260;
		Pawn.Velocity = V;
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
	local int i;
	
	simulated function Tick(float Delta)
	{
		super.Tick(Delta);
		SetRotation(DesiredRot);
	}
	
	Begin:
		DesiredRot = Rotation;
		Pawn.Acceleration = vect(0,0,1);
		
		if (ToxikkMonster(Pawn).bIsBossMonster)
			ToxikkMonster(Pawn).SetBossCamera(true);
		
		i = Rand(ToxikkMonster(Pawn).SightAnims.Length);
		
		// `Log("Playing sight anim"@string(i)$"...");
		
		ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).SightAnims[i],ToxikkMonster(Pawn).SightSound);
		Sleep(ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).SightAnims[i]));
		
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
		
		Sleep(0.5);
		
	if (Pawn(Target) == None)
		GotoState('Wander');
}

//--MONSTER IS DOING A MELEE ATTACK----------------------------------------------------------------
state Attacking
{
	local int i;
	local float StateTimer, TimerGoal;
	
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
		
		StateTimer += Delta;
	}
	
	Begin:
		DesiredRot = Rotation;
		StateTimer = 0.0;
		Pawn.Acceleration = vect(0,0,1);
		
		i = Rand(ToxikkMonster(Pawn).MeleeAttackAnims.Length);
		ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).MeleeAttackAnims[i],ToxikkMonster(Pawn).AttackSound);
		TimerGoal = ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).MeleeAttackAnims[i]);
		
		while (StateTimer < TimerGoal)
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

//--MONSTER IS DOING A RANGED ATTACK----------------------------------------------------------------
state RangedAttack
{
	local int i;
	local float StateTimer, TimerGoal;
	local bool bCanLunge;
	
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
		
		StateTimer += Delta;
	}
	
	Begin:
		if (FRand() >= ToxikkMonster(Pawn).LungeChance && ToxikkMonster(Pawn).bHasLunge)
		{
			// If the monster has lunge while crouched then check if they're crouched
			if (ToxikkMonster(Pawn).bLungeIfCrouched && ToxikkMonster(Pawn).bIsCrawling)
				bCanLunge=true;
			else if (!ToxikkMonster(Pawn).bLungeIfCrouched)
				bCanLunge=true;
			
			if (bCanLunge)
				GotoState('Lunging');
		}
			
		// Face the player
		StateTimer = 0.0;
		DesiredRot = Rotator(Target.Location - Pawn.Location);
		Pawn.Acceleration = vect(0,0,1);
		
		if (ToxikkMonster(Pawn).CrouchedRangedAnims.Length > 0 && ToxikkMonster(Pawn).bIsCrawling)
			i = Rand(ToxikkMonster(Pawn).CrouchedRangedAnims.Length);
		else
			i = Rand(ToxikkMonster(Pawn).RangedAttackAnims.Length);
			
		if (ToxikkMonster(Pawn).CrouchedRangedAnims.Length > 0 && ToxikkMonster(Pawn).bIsCrawling)
		{
			ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).CrouchedRangedAnims[i]);
			TimerGoal = ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).CrouchedRangedAnims[i]);
		}
		else
		{
			ToxikkMonster(Pawn).PlayForcedAnim(ToxikkMonster(Pawn).RangedAttackAnims[i]);
			TimerGoal = ToxikkMonster(Pawn).Mesh.GetAnimLength(ToxikkMonster(Pawn).RangedAttackAnims[i]);
		}
		
		while (StateTimer < TimerGoal)
		{
			if (Target != None && ToxikkMonster(Pawn).bWalkingRanged)
				MoveToward(Target, Target, 20.0f);
				
			Sleep(0.01);
		}
		
		RangedTimer=0.0;
		
		// Decide if we should go into crawl mode or not
		if (FRand() >= 1.0-ToxikkMonster(Pawn).CrawlChance)
			ToxikkMonster(Pawn).SetCrawling(true);
		
		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Wander');
}

state ChasePlayer
{
	local vector PL, TL;
	local float PDistance;
	
	simulated function Tick(float Delta)
	{
		super.Tick(Delta);
		RangedTimer += Delta;
	}
	
  Begin:
    Pawn.Acceleration = vect(0,0,1);
	
    While (Pawn != none && Target != None)
    {
		PL = Pawn.Location;
		TL = Target.Location;
		
		PL.Z += 10;
		TL.Z += 10;
		
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
			else if (DistanceToPlayer <= ToxikkMonster(Pawn).RangedAttackDistance && ToxikkMonster(Pawn).bHasRanged && FastTrace(Target.Location, PosPlusHeight(Pawn.Location)) && RangedTimer >= ToxikkMonster(Pawn).RangedDelay)
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
				PDistance = VSize(Target.Location - Pawn.Location);
				
				// CAN WE MELEE ATTACK?
				if (PDistance <= ToxikkMonster(Pawn).AttackDistance && GetInFront(Pawn, Target) > 0.0 && ToxikkMonster(Pawn).bHasMelee)
				{
					GotoState('Attacking');
					break;
				}
				// OTHERWISE, CAN WE RANGED ATTACK?
				else if (PDistance <= ToxikkMonster(Pawn).RangedAttackDistance && GetInFront(Pawn, Target) > 0.0 && ToxikkMonster(Pawn).bHasRanged && FastTrace(Target.Location, Pawn.Location) && RangedTimer >= ToxikkMonster(Pawn).RangedDelay)
				{
					GotoState('RangedAttack');
					break;
				}
				else
				{
					if (PDistance < 200)
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

defaultproperties
{
	PerceptionDistance=10000
}
