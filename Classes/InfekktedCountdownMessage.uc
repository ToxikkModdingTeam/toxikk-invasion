//================================================================
// Infekkted.InfekktedCountdownMessage
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class InfekktedCountdownMessage extends CRZSubCenterMessage;

static simulated function ClientReceive(PlayerController PC, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
    Super.ClientReceive(PC, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

	if ( Switch > 0 && Switch <= 4 && PC != None )
		PC.PlayBeepSound();
}

static function SoundNodeWave AnnouncementSound(int MessageIndex, Object OptionalObject, PlayerController PC)
{
    return None; 
}

static function string GetCRZString(optional int Switch, optional PlayerController P, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if ( Switch > 0 && (Switch <= 10 || (Switch%10) == 0) )
		return "... Next wave in " $ Switch $ " ...";

	return "";
}

defaultproperties
{
	bLongOpen=true
	AnnouncementPriority=100    // priority over the "spectator" subcentermessage
}
