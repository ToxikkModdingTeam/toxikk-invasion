//--CLASSIC DOOM CONTROLLER
//------------------------------------------------------------------
Class CDoomController extends ToxikkMonsterController;

var				float				TotalRangedTime;

// Switch to certain sprite states when things begin
simulated function BeginNotify(string StateName)
{
	if (CDoomMonster(Pawn) == None)
		return;
		
	if (StateName ~= "ChasePlayer" || StateName ~= "Wander")
		CDoomMonster(Pawn).SetSpriteState("walk");
}

state Paining
{
	Begin:
		Pawn.Acceleration = vect(0,0,1);
		BeginNotify("Paining");
		CDoomMonster(Pawn).SetSpriteState("pain");
		TotalRangedTime = CDoomMonster(Pawn).CalcStateTime("PAIN");
		Sleep(TotalRangedTime);
		if (Pawn(Target) != None)
			GotoState('ChasePlayer');
		else
			GotoState('Wander');
}

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
	}
	
	Begin:
		BeginNotify("RangedAttack");
		TotalRangedTime = CDoomMonster(Pawn).CalcStateTime("FIRE");
		CDoomMonster(Pawn).SetSpriteState("fire");
		
		LastTimeSomethingHappened = WorldInfo.TimeSeconds;
		
		DesiredRot = Rotator(Target.Location - Pawn.Location);
		Pawn.Acceleration = vect(0,0,1);

		Sleep(TotalRangedTime);
		TotalRangedTime=0.0;
		RangedTimer = 0.0;
	
		if (Pawn(Target) != None)
			GotoState('ChasePlayer');
		else
			GotoState('Wander');
}

DefaultProperties
{
}
