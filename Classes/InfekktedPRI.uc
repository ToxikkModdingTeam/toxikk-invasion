//================================================================
// Infekkted.InfekktedPRI
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class InfekktedPRI extends CRZPlayerReplicationInfo;



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
