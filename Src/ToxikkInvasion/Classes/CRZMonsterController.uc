//--TOXIKK INVASION MONSTER CONTROLLER------------------------------
//------------------------------------------------------------------

Class CRZMonsterController extends AIController;

// Pawn we're following
var Actor Target;
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
	
	if (CRZMonster(inPawn).bForceInitialTarget)
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
		if (CRZMonster(Seen) != None || Seen == Pawn)
			return;
			
		Target = Seen;
		CRZMonster(Pawn).SeenSomething();
	 
		if (FRand() >= CRZMonster(Pawn).SightChance)
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
		Pawn.RotationRate.Yaw = Pawn.default.RotationRate.Yaw * CRZMonster(Pawn).PreRotateModifier;
		`Log(Pawn.RotationRate.Yaw);
		
		while ((GetInFront(Pawn, Target) == 0.0 || GetInFront(Pawn, Target) < 0.0) && FastTrace(Target.Location, PosPlusHeight(Pawn.Location)) && VSize(Target.Location - Pawn.Location) <= CRZMonster(Pawn).SightRadius)
		{
			Pawn.Acceleration = vect(0,0,1);
			
			if (Target == None)
				GotoState('Idling');
				
			SetFocalPoint(Target.Location);
			Sleep(0.01);
		}
		
		DistanceToPlayer = VSize(Target.Location - Pawn.Location);
		
		Pawn.RotationRate.Yaw = Pawn.default.RotationRate.Yaw;

		// MELEE ATTACK?
		if (DistanceToPlayer <= CRZMonster(Pawn).AttackDistance && CRZMonster(Pawn).bHasMelee)
				GotoState('Attacking');
		// OTHERWISE, CAN WE RANGED ATTACK?
		else if (DistanceToPlayer <= CRZMonster(Pawn).RangedAttackDistance && CRZMonster(Pawn).bHasRanged && FastTrace(Target.Location, Pawn.Location))
				GotoState('RangedAttack');
		else
		{
				if (Target != None)
					GotoState('ChasePlayer');
				else
					GotoState('Idling');
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
		CRZMonster(Pawn).PlayForcedAnim(CRZMonster(Pawn).LungeStartAnim);
		Sleep(CRZMonster(Pawn).Mesh.GetAnimLength(CRZMonster(Pawn).LungeStartAnim));
		
		// MID-LUNGE
		V = Normal(Target.Location-Pawn.Location) * CRZMonster(Pawn).LungeSpeed;
		V.Z += 260;
		Pawn.Velocity = V;
		Pawn.SetPhysics(PHYS_Falling);
		CRZMonster(Pawn).PlayForcedAnim(CRZMonster(Pawn).LungeMidAnim);
		CRZMonster(Pawn).bIsLunging = true;
		
		while (CRZMonster(Pawn).bIsLunging)
		{
			Sleep(0.01);
		}
		
		// POST-LUNGE
		CRZMonster(Pawn).PlayForcedAnim(CRZMonster(Pawn).LungeEndAnim);
		Sleep(CRZMonster(Pawn).Mesh.GetAnimLength(CRZMonster(Pawn).LungeEndAnim));
		
		RangedTimer=0.0;
		
		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Idling');
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
		
		if (CRZMonster(Pawn).bIsBossMonster)
			CRZMonster(Pawn).SetBossCamera(true);
		
		i = Rand(CRZMonster(Pawn).SightAnims.Length);
		
		// `Log("Playing sight anim"@string(i)$"...");
		
		CRZMonster(Pawn).PlayForcedAnim(CRZMonster(Pawn).SightAnims[i],CRZMonster(Pawn).SightSound);
		Sleep(CRZMonster(Pawn).Mesh.GetAnimLength(CRZMonster(Pawn).SightAnims[i]));
		
		if (CRZMonster(Pawn).bIsBossMonster)
			CRZMonster(Pawn).SetBossCamera(false);
		
		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Idling');
}

// IN THIS STATE, WE'RE DOING NOTHING
auto state Idling
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
				if (CRZMonster(Pawn).bWalkingAttack)
					DesiredRot = Rotator(Target.Location - Pawn.Location);
			}
		}
		
		StateTimer += Delta;
	}
	
	Begin:
		DesiredRot = Rotation;
		StateTimer = 0.0;
		Pawn.Acceleration = vect(0,0,1);
		
		i = Rand(CRZMonster(Pawn).MeleeAttackAnims.Length);
		CRZMonster(Pawn).PlayForcedAnim(CRZMonster(Pawn).MeleeAttackAnims[i],CRZMonster(Pawn).AttackSound);
		TimerGoal = CRZMonster(Pawn).Mesh.GetAnimLength(CRZMonster(Pawn).MeleeAttackAnims[i]);
		
		while (StateTimer < TimerGoal)
		{
			if (Target != None && CRZMonster(Pawn).bWalkingAttack)
				MoveToward(Target, Target, 20.0f);
				
			Sleep(0.01);
		}
		
		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Idling');
}

//--MONSTER IS DOING A RANGED ATTACK----------------------------------------------------------------
state RangedAttack
{
	local int i;
	local float StateTimer, TimerGoal;
	
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
				if (CRZMonster(Pawn).bWalkingRanged)
					DesiredRot = Rotator(Target.Location - Pawn.Location);
			}
		}
		
		StateTimer += Delta;
	}
	
	Begin:
		if (FRand() >= CRZMonster(Pawn).LungeChance && CRZMonster(Pawn).bHasLunge)
			GotoState('Lunging');
			
		// Face the player
		StateTimer = 0.0;
		DesiredRot = Rotator(Target.Location - Pawn.Location);
		Pawn.Acceleration = vect(0,0,1);
		
		i = Rand(CRZMonster(Pawn).RangedAttackAnims.Length);
		CRZMonster(Pawn).PlayForcedAnim(CRZMonster(Pawn).RangedAttackAnims[i]);
		TimerGoal = CRZMonster(Pawn).Mesh.GetAnimLength(CRZMonster(Pawn).RangedAttackAnims[i]);
		
		while (StateTimer < TimerGoal)
		{
			if (Target != None && CRZMonster(Pawn).bWalkingRanged)
				MoveToward(Target, Target, 20.0f);
				
			Sleep(0.01);
		}
		
		RangedTimer=0.0;
		
		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Idling');
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
		if (ActorReachable(Target) || (FastTrace(Target.Location,Pawn.Location) && Target.Location.Z < Pawn.Location.Z+100 && Target.Location.Z > Pawn.Location.Z - 25))
		{
			DistanceToPlayer = VSize(Target.Location - Pawn.Location);
			
			// CAN WE MELEE ATTACK?
			if (DistanceToPlayer <= CRZMonster(Pawn).AttackDistance && GetInFront(Pawn, Target) > 0.0 && CRZMonster(Pawn).bHasMelee)
			{
				GotoState('Attacking');
				break;
			}
			// OTHERWISE, CAN WE RANGED ATTACK?
			else if (DistanceToPlayer <= CRZMonster(Pawn).RangedAttackDistance && CRZMonster(Pawn).bHasRanged && FastTrace(Target.Location, PosPlusHeight(Pawn.Location)) && RangedTimer >= CRZMonster(Pawn).RangedDelay)
			{
				GotoState('PreAttack');
				break;
			}
			else
				MoveToward(Target, Target, 20.0f);
		}
		else
		{
			MoveTarget = FindPathToward(Target,,PerceptionDistance + (PerceptionDistance/2));
			if (MoveTarget != none)
			{
				//Worldinfo.Game.Broadcast(self, "Moving toward Player");

				DistanceToPlayer = VSize(MoveTarget.Location - Pawn.Location);
				PDistance = VSize(Target.Location - Pawn.Location);
				
				// CAN WE MELEE ATTACK?
				if (PDistance <= CRZMonster(Pawn).AttackDistance && GetInFront(Pawn, Target) > 0.0 && CRZMonster(Pawn).bHasMelee)
				{
					GotoState('Attacking');
					break;
				}
				// OTHERWISE, CAN WE RANGED ATTACK?
				else if (PDistance <= CRZMonster(Pawn).RangedAttackDistance && GetInFront(Pawn, Target) > 0.0 && CRZMonster(Pawn).bHasRanged && FastTrace(Target.Location, Pawn.Location) && RangedTimer >= CRZMonster(Pawn).RangedDelay)
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
			GotoState('Idling');
    }
}

defaultproperties
{
	PerceptionDistance=10000
}
