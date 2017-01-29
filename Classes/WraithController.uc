//------------------------------------------------------------------
Class WraithController extends ToxikkMonsterController;

// How long between each teleport
var			int			TeleportDelayMin, TeleportDelayMax;
// How close a path point has to be near us in order to teleport
var			float		TeleportDistance;
var			vector		OldLocation;
var			bool		bWaitingToTeleport, bLatentTeleport, bUseLatentTeleports;
// Chances of doing a latent teleport instead of an instant one
var			float		LatentTeleportChance, LatentTeleportTime, LatentRadiusMultiply;

function bool CanTeleport() {return false;}

state ChasePlayer
{	
	function bool CanTeleport() {return true;}
	
	event BeginState (name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		SetTimer(RandRange(TeleportDelayMin,TeleportDelayMax),false,'TryTeleport');
	}
}

simulated function ForceTeleport() {bWaitingToTeleport = false;}

// Do nothing basically, latent teleport state
state Invisible
{
	function bool CanTeleport() {return true;}
	
	Begin:
		while (bWaitingToTeleport)
		{
			sleep(0.01);
		}
		
		DoTeleport();
		GotoState('ChasePlayer');
}

simulated function TryTeleport()
{
	// Do a delayed teleport
	// TODO: ADD PARTICLE EFFECTS
	if (FRand() >= LatentTeleportChance && bUseLatentTeleports)
	{
		bLatentTeleport=true;
		bWaitingToTeleport = true;
		SetTimer(LatentTeleportTime,false,'ForceTeleport');
		GotoState('Invisible');
		Wraith(Pawn).SetCloaked(true);
	}
	else
		DoTeleport();
}

// SERVERSIDE, TELEPORT
simulated function DoTeleport()
{
	local vector TelDes;
	
	// PAWN IS DEAD, DO NOTHING
	if (Pawn.Health <= 0 || !CanTeleport())
		return;
		
	SetTimer(RandRange(TeleportDelayMin,TeleportDelayMax),false,'TryTeleport');
	
	// Actually teleport
	if (bLatentTeleport)
		TelDes = FindTeleportDestination(Target,TeleportDistance*LatentRadiusMultiply);
	else
		TelDes = FindTeleportDestination(Target,TeleportDistance);
	
	if (TelDes != Pawn.Location)
	{
		if ( bLatentTeleport )
		{
			Wraith(Pawn).SetLocation(TelDes);
			Wraith(Pawn).SetCloaked(false);
			bLatentTeleport = false;
		}
		else
		{
			Wraith(Pawn).TeleportBeam(Pawn.Location,TelDes);
			Wraith(Pawn).SetLocation(TelDes);
		}

		if (Target != None)
			GotoState('ChasePlayer');
		else
			GotoState('Wander');
	}
}

// Find a teleport destination
// -- TODO: MAYBE ADD A FASTTRACE CHECK TO CHECK THROUGH WALLS
// -- TODO: MAKE SURE TELEPORTING TO THIS POINT DOES NOT PUT US IN A WALL
function vector FindTeleportDestination(Actor Targ, float Rad)
{
	local NavigationPoint FinalPoint, NP;
	local float TargetDist;
	
	TargetDist = 999999.0;
	
	ForEach WorldInfo.RadiusNavigationPoints(class'NavigationPoint',NP,Pawn.Location,Rad * 2.0)
	{
		// Yes, we're close enough to this path point
		if (VSize(NP.Location - Pawn.Location) <= Rad)
		{
			// Find the closest point to our target that's still within our radius
			if (abs(VSize(Target.Location - NP.Location)) < TargetDist)
			{
				TargetDist = abs(VSize(Target.Location - NP.Location));
				FinalPoint = NP;
			}
		}
	}
	
	if (FinalPoint != None)
		return FinalPoint.Location;
		
	return Pawn.Location;
}

defaultproperties
{
	TeleportDelayMin = 3
	TeleportDelayMax = 10
	
	LatentTeleportTime=5.0
	
	// We want to simulate the wraith moving around while invisible, so he can teleport farther
	LatentRadiusMultiply=5.0
	
	TeleportDistance = 500
	
	// Make this relatively low, latent teleports are more "powerful"
	LatentTeleportChance=0.8
	
	// USE LATENT TELEPORTS
	// If true, it mimics Doom 3's actual behavior where wraiths go invis for a bit before teleporting
	
	bUseLatentTeleports=true
}