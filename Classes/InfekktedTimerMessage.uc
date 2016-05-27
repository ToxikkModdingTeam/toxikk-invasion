//================================================================
// Infekkted.InfekktedTimerMessage
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class InfekktedTimerMessage extends CRZTimerMessage;

// Fix issue that prevents initial countdown from being played
//TODO: remove when fixed by Reakktor
/* I think it's done (26/05/2016 hotfix patch)
static simulated function ClientReceive(PlayerController P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if ( UTPlayerController(P).Announcer.AnnouncerSoundCue.Duration == 0 )
		UTPlayerController(P).Announcer.AnnouncerSoundCue.Duration = 1.0;

	Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}
*/

static function string GetCRZString(optional int Switch, optional PlayerController P, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if ( InfekktedGRI(OptionalObject) != None && InfekktedGRI(OptionalObject).bPreWaveCountdown )
		return "NEXT WAVE IN " $ Switch $ " ...";

	return Super.GetCRZString(Switch, P, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

defaultproperties
{
}
