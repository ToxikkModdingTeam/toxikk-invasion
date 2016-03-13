//================================================================
// Infekkted.InfekktedPRI
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class InfekktedPRI extends CRZPlayerReplicationInfo;

var int TotalDamage;

function AddDamage(int Dmg)
{
	TotalDamage += Dmg;
	RecalcScore();
}

function RecalcScore()
{
	Score = TotalDamage / 100.0;
}

// Workaround to get rid of Intro/Lobby screen
// Because PC.ClientGotoState() is blocked in state Introduction
reliable client function ClientForceSpectate()
{
	if ( PlayerController(Owner) != None )
		Owner.GotoState('Spectating');
}

defaultproperties
{
}
