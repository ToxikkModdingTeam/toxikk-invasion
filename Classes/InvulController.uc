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
		if ( RangedCounter >= MaxFreeRanged || FRand() <= SummonChance )
			GotoState('Summon');
	}
	else if ( FRand() <= StompChance )
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
	MaxFreeRanged=4
	// have shield initially ready
	RangedCounter=4
	// 25% chance to summon (shield) before reaching MaxFreeRanged
	SummonChance=0.25
	// 25% chance to stomp (kill shield)
	StompChance=0.25
}