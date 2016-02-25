//================================================================
// Infekkted.InfekktedConfig
// ----------------
// Separate class to have different ini sections
// Because I hate having it mixed with the usual GameInfo configs
// ----------------
// by Chatouille
//================================================================
class InfekktedConfig extends Object
	Config(Infekkted);


/** Per player difficulty adjuster definition */
Struct sPlayerCountAdjuster
{
	var byte NumPlayers;
	var float TotalMonsters;
	var float SpawnRate;
	var float MaxDensity;
	var float Health;
	var float MeleeDamage;
	var float RangeDamage;

	structdefaultproperties
	{
		TotalMonsters=1.0
		SpawnRate=1.0
		MaxDensity=1.0
		Health=1.0
		MeleeDamage=1.0
		RangeDamage=1.0
	}
};


/** Per map difficulty adjuster definition */
Struct sMapAdjuster
{
	var String Map;
	var float TotalMonsters;
	var float SpawnRate;
	var float MaxDensity;

	structdefaultproperties
	{
		TotalMonsters=1.0
		SpawnRate=1.0
		MaxDensity=1.0
	}
};


/** Waves configuration */
var config array<String> Waves;

/** Increase difficulty with playercount. Unspecified playercounts inherit from the nearest lower playercount setting */
var config array<sPlayerCountAdjuster> PerPlayerDifficultyAdjusters;

/** Whether to use the multiplicative formula (harder) or the additive one (easier) when adjusting difficulty */
var config bool bMultiplicativeAdjusters;

/** Maps can specify some adjusters as well (monsters count) because mapsize can change a lot */
var config array<sMapAdjuster> MapAdjusters;

/** If current map is unspecified, the gamemode will try to calculate an average map size and can adjust automatically based on that */
var config sMapAdjuster AutoMapAdjuster;


/** Friendly fire scale for players */
var config float TeamDamageDirect;
/** Friendly fire retaliation for players */
var config float TeamDamageRetaliate;


function Init()
{
	// init config - generate first time ini for server admins
	if ( Waves.Length == 0 )
		InitConfig();

	`Log("[Infekkted] Config available in UDKInfekkted.ini");
}

function InitConfig()
{
	//TODO: generate example waves config

	Waves.Length = 2;
	Waves[0] = "MyWave1";
	Waves[1] = "MyWave2";

	PerPlayerDifficultyAdjusters.Length = 1;
	PerPlayerDifficultyAdjusters[0].NumPlayers = 2;
	PerPlayerDifficultyAdjusters[0].TotalMonsters = 1.3;
	PerPlayerDifficultyAdjusters[0].SpawnRate = 1.3;
	PerPlayerDifficultyAdjusters[0].MaxDensity = 1.2;
	PerPlayerDifficultyAdjusters[0].Health = 1.1;
	PerPlayerDifficultyAdjusters[0].MeleeDamage = 1.1;
	PerPlayerDifficultyAdjusters[0].RangeDamage = 1.1;

	bMultiplicativeAdjusters = false;

	MapAdjusters.Length = 1;
	MapAdjusters[0].Map = "BL-Foundation";

	AutoMapAdjuster.TotalMonsters = 0.75;
	AutoMapAdjuster.SpawnRate = 0.75;
	AutoMapAdjuster.MaxDensity = 0.75;

	TeamDamageDirect = 0.0;
	TeamDamageRetaliate = 0.25;

	SaveConfig();
}


defaultproperties
{
}
