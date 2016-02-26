//================================================================
// Infekkted.InfekktedMessage
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class InfekktedMessage extends CRZRewardMessage;

/** Switch:
 * 0 = name of the wave starting
 * 1 = Player is OUT
 * 2 = Last survivor
 * 3 = end of wave
 */

static function SoundNodeWave AnnouncementSound(int MessageIndex, Object OptionalObject, PlayerController PC)
{
    return None; 
}

static function string GetCRZString(optional int Switch, optional PlayerController P, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	Switch (Switch)
	{
		case 0:
			return "";  // string sent directly to HUD

		case 1:
			return class'CRZHudWrapper'.static.GetHTMLPlayerNameFromPRI(RelatedPRI_1, true) $ " IS OUT!";

		case 2:
			if ( P != None && P.PlayerReplicationInfo == RelatedPRI_1 )
				return "<font color='#FF0000'>LAST SURVIVOR!</font>";
			else
				return class'CRZHudWrapper'.static.GetHTMLPlayerNameFromPRI(RelatedPRI_1, true) $ " IS THE LAST SURVIVOR!";

		case 3:
			return "END OF WAVE!";
	}
	return "";
}

defaultproperties
{
}
