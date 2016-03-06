//================================================================
// Infekkted.InfekktedSquad
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class InfekktedSquad extends CRZBLSquad;

function bool SetEnemy(UTBot B, Pawn NewEnemy)
{
	return ( CRZPawn(NewEnemy) == None && Super.SetEnemy(B, NewEnemy) );
}

function bool FriendlyToward(Pawn Other)
{
	return ( CRZPawn(Other) != None );
}

defaultproperties
{
}
