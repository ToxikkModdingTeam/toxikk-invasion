//--DOOM 3 HELL KNIGHT
//------------------------------------------------------------------
Class InvulController extends ToxikkMonsterController;

// How many ranged attacks we should do before we toggle invincibility
var	int MaxFreeRanged, RangedCounter;
// Chance of going invincible before MaxFreeRanged
var float SummonChance;
// Chance of going vincible
var float StompChance;

//--------------------------------------------------------------------

// Stomp or summon
simulated function RangedException()
{
	if ( !InvulHunter(Pawn).bInvincible )
	{
		RangedCounter++;
		if ( RangedCounter >= MaxFreeRanged || FRand() > 1.0-SummonChance )
			GotoState('Summon');
	}
	else if ( FRand() > 1.0-StompChance )
	{
		RangedCounter = 0;
		GotoState('Stomp');
	}
}

// STOMPING
state Stomp
{
	`DEBUG_MONSTER_STATE_DECL

Begin:
	InvulHunter(Pawn).PlaySound(InvulHunter(Pawn).FireballCue,TRUE);
	InvulHunter(Pawn).PlayForcedAnim(InvulHunter(Pawn).StompAnim);
	Sleep(Pawn.Mesh.GetAnimLength(InvulHunter(Pawn).StompAnim));
	GotoState('ChasePlayer');
}

// SUMMONING
state Summon
{
	`DEBUG_MONSTER_STATE_DECL

Begin:
	InvulHunter(Pawn).PlayForcedAnim(InvulHunter(Pawn).InvulAnim);
	Sleep(Pawn.Mesh.GetAnimLength(InvulHunter(Pawn).InvulAnim));
	GotoState('ChasePlayer');
}

defaultproperties
{
	MaxFreeRanged=3
	// have shield initially ready
	RangedCounter=3
	// 25% chance to summon (shield) before reaching MaxFreeRanged
	SummonChance=0.25
	// 25% chance to stomp (kill shield)
	StompChance=0.25
}