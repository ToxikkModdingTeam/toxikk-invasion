//================================================================
// Infekkted.LootOrb_Health
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class LootOrb_Health extends LootOrb;

var int Health;

// Init values from config
function SetParameters(eOrbColor Col, String Value, String Extras)
{
	Super.SetParameters(Col, Value, Extras);

	Health = int(Value);
}

// Give orb to player
function GiveTo(Pawn P)
{
	if ( UTPawn(P) != None && P.Health < UTPawn(P).SuperHealthMax )
		P.Health = Min(P.Health + Health, UTPawn(P).SuperHealthMax);
	else if ( P.Health < P.HealthMax )
		P.Health = Min(P.Health + Health, P.HealthMax);

	//TODO: message (client!!!)

	Super.GiveTo(P);
}

defaultproperties
{
	//PickupSound=SoundCue'Snd_Pickups.Health.SoundCues.A_Pickups_Health_Cue'
	PickupSound=SoundCue'Snd_Pickups.Health.SoundCues.A_Pickups_Health_Respawn_Cue'
}
