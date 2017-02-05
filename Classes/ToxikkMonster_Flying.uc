Class ToxikkMonster_Flying extends ToxikkMonster;

defaultproperties
{
	Physics=PHYS_Flying
	JumpZ=999999.0
	AirSpeed=100.0
	ControllerClass=Class'ToxikkMonsterController_Flying'
	bCanFly = true
	bAvoidLedges = false
	bCanWalkOffLedges = true
}