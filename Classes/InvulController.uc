//--DOOM 3 HELL KNIGHT
//------------------------------------------------------------------
Class InvulController extends ToxikkMonsterController;

// How many ranged attacks we should do before we toggle invincibility
var			int				MaxFreeRanged, RangedCounter;
// Chance of going vincible
var			float			StompChance;

//--------------------------------------------------------------------

// Stomp or summon
simulated function RangedException()
{
	RangedCounter ++;
	
	if (RangedCounter >= MaxFreeRanged && !InvulHunter(Pawn).bInvincible)
	{
		RangedCounter=0;
		GotoState('Summon');
	}
	else
	{
		if (FRand() >= 1.0-StompChance && InvulHunter(Pawn).bInvincible && RangedCounter >= MaxFreeRanged)
		{
			RangedCounter=0;
			GotoState('Stomp');
		}
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
	// 25% chance to stompsummon
	StompChance=0.25
}