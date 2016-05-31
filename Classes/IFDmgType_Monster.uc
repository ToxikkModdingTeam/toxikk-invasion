//================================================================
// Infekkted.IFDmgType_Monster
// ----------------
// Base class for monster damagetypes
// ----------------
// by Chatouille
//================================================================
class IFDmgType_Monster extends CRZDamageType;

//FIX to avoid logs because monster (instigator) has no PRI
static function LinearColor GetDamageBodyMatColor(CRZPlayerReplicationInfo InstigatorPRI)
{
	return default.DamageBodyMatColor;
}

defaultproperties
{
	//defaults
	DamageOverlayTime=0
	VehicleDamageScaling=1.0
	VehicleMomentumScaling=1.0
	KDamageImpulse=3000
	GibTrail=ParticleSystem'Gore_HeadShot.Particles.P_Gore_Head_Movement'

	//common properties
	bComplainFriendlyFire=false
	bUseTeamBodyColor=false
	DamageWeaponClass=None
	KillStatsName=""
	DeathStatsName=""
	SuicideStatsName=""
}
