Class ToxikkMonster_Flying extends ToxikkMonster;

// Keeps the monster from circling around targets
var				float				CircularPrevention;

simulated function bool ReachedDestination(Actor Goal)
{
	local float DD;
	local Vector V1,V2;
	
	V1 = Goal.Location;
	V2 = Location;
	V1.Z = 0;
	V2.Z = 0;
	
	DD = VSize(V1 - V2) - CylinderComponent(CollisionComponent).CollisionRadius;
	
	if (DD <= CircularPrevention && !FastTrace(V1,V2))
		return true;
	
	return super.ReachedDestination(Goal);
}

simulated function Tick(float Delta)
{
	super.Tick(Delta);
	
	if (ROLE == ROLE_Authority)
	{
		if (Physics != PHYS_Flying && Health > 0)
			SetPhysics(PHYS_Flying);
	}
}

defaultproperties
{
	Physics=PHYS_Flying
	JumpZ=999999.0
	AirSpeed=100.0
	ControllerClass=Class'ToxikkMonsterController_Flying'
	bCanFly = true
	bAvoidLedges = false
	bCanWalkOffLedges = true
	
	CircularPrevention = 40
}