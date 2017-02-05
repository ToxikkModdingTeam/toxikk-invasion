//--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
// -- FLYING MONSTER CONTROLLER
//--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
Class ToxikkMonsterController_Flying extends ToxikkMonsterController;

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
				MoveToward(Target, Target, 20.0f);
		}
		
		// PLAYER ISN'T DIRECTLY SEEN? USE "PATHFINDING"
		// This might be kinda hacky because of flying
		
		else
		{
			//NOTE: Same thing here, if we can ranged attack, we don't care about the MoveTarget being none or not.
			// The attacking checks should be done in priority, and only then, do the pathing/movement IF we were not able to attack...

			// -- FIRST START WITH HACK PATH
			MoveTarget = HackPath(Target,bUseDetours,PerceptionDistance + (PerceptionDistance/2));
			
			// -- CHECKS TO PREVENT IT FROM GETTING STUCK --
			if (LastReached != MoveTarget)
				LastReached = MoveTarget;
			else if (RouteCache.Length > 1)
			{
				RouteCache.RemoveItem(RouteCache[0]);
				MoveTarget = RouteCache[0];
				LastReached = MoveTarget;
			}
			
			// If we can't reach the target then just go back to wander
			// -- TODO: Flying pawns can really reach the target pretty much anywhere, maybe forcefully find a way?
			if (MoveTarget == None)
			{
				Target = None;
				GotoState('Wander');
			}
			
			//MoveTarget = FindPathToward(Target,bUseDetours,PerceptionDistance + (PerceptionDistance/2));
				
			//Target = None;
			//GotoState('Wander');
			//MoveTarget = HackPath(Target,bUseDetours,PerceptionDistance + (PerceptionDistance/2));
			
			//`Log("WE MADE IT THIS FAR");
			
			if (VSize(MoveTarget.Location - Pawn.Location) <= Pawn.CylinderComponent.CollisionRadius)
			{
				`Log("SWAPPED TO CACHE 1");
				MoveTarget = RouteCache[1];
			}
			
			// We have a move target
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
					// Otherwise just move normally
					else
					{
						// -- THIS IS WHERE IT GETS STUCK WHEN THE POINT IS RIGHT IN FRONT OF IT - WHY? CHECK REACHEDDESTINATION --
						`Log("VERY BOTTOM STUCK POINT");
						MoveToward(MoveTarget, MoveTarget, 20.0f);	
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

defaultproperties
{
}