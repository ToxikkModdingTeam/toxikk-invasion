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


/** Waves configuration */
var config array<String> Waves;
/** Loaded waves */
var array<WaveConfig> LoadedWaves;


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
/** Increase difficulty with playercount. Unspecified playercounts inherit from the nearest lower playercount setting */
var config array<sPlayerCountAdjuster> PerPlayerDifficultyAdjusters;


/** Whether to use the multiplicative formula (harder) or the additive one (easier) when adjusting difficulty */
var config bool bMultiplicativeAdjusters;


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
/** Maps can specify some adjusters as well (monsters count) because mapsize can change a lot */
var config array<sMapAdjuster> MapAdjusters;


/** If current map is unspecified, the gamemode will try to calculate an average map size and can adjust automatically based on that */
var config sMapAdjuster AutoMapAdjuster;


/** Friendly fire scale for players */
var config float TeamDamageDirect;
/** Friendly fire retaliation for players */
var config float TeamDamageRetaliate;


/** Orb drop rate definition */
struct sOrbDropRate
{
	var int MinHP;
	var float MinChance;
	var int MaxHP;
	var float MaxChance;
};
/** Orb drop rates - each element defines a chance for an orb to drop from a monster */
var config array<sOrbDropRate> OrbDropRates;


/** Orb colors */
enum eOrbColor
{
	ORB_Red,
	ORB_Yellow,
	ORB_Green,
	ORB_Orange,
	ORB_Purple,
};

/** Orb group definition */
struct StrictConfig sOrbGroup
{
	var config eOrbColor Color;
	var config int MinHP;
	var config float Chance;

	var int Count;
};
/** Orb groups - every time an orb drops, groups are rolled in reverse order until success. Then orb becomes one of this group (picked unirandomly) */
var config array<sOrbGroup> OrbGroups;


/** Actual orb definition */
struct StrictConfig sOrb
{
	var config int Group;
	var config String Class;
	var config String Value;
	var config String Extras;

	var class<LootOrb> LoadedClass;
};
/** Actual droppable orbs */
var config array<sOrb> Orbs;
/** Loaded droppable orbs */
var array<sOrb> LoadedOrbs;


function Init()
{
	local array<String> AllWaves;
	local int i, j;
	local WaveConfig Wave;

	// Sort Playercount difficulty adjusters
	PerPlayerDifficultyAdjusters.Sort(CompareAdjusters);

	// Load waves
	class'WaveConfig'.static.GetWavesList(AllWaves);
	for ( i=0; i<Waves.Length; i++ )
	{
		// find wave in waves list
		for ( j=0; j<AllWaves.Length; j++ )
			if ( AllWaves[j] ~= Waves[i] )
				break;
		if ( j < AllWaves.Length)
		{
			// load wave object (invalid config will return None)
			Wave = class'WaveConfig'.static.LoadWave(AllWaves[j], false);
			if ( Wave != None )
			{
				Wave.LoadMonsters();
				LoadedWaves.AddItem(Wave);
			}
			else
				`Log("[Infekkted] Wave " $ i $ " '" $ Waves[i] $ "' has invalid configuration - skipping");
		}
		else
			`Log("[Infekkted] Wave " $ i $ " '" $ Waves[i] $ "' not found - skipping");
	}
	if ( LoadedWaves.Length == 0 )
		`Log("[Infekkted] ERROR: Game doesn't have any waves!");

	// Load orbs
	for ( i=0; i<Orbs.Length; i++ )
	{
		if ( Orbs[i].Group >= 0 || Orbs[i].Group < OrbGroups.Length )
		{
			Orbs[i].LoadedClass = class<LootOrb>(DynamicLoadObject(Orbs[i].Class, class'Class', true));
			if ( Orbs[i].LoadedClass != None )
			{
				LoadedOrbs.AddItem(Orbs[i]);
				OrbGroups[LoadedOrbs[i].Group].Count += 1;
			}
			else
				`Log("[Infekkted] Failed to load class '" $ Orbs[i].Class $ "' for Orb " $ i $ " - skipping");
		}
		else
			`Log("[Infekkted] Orb " $ i $ " has invalid Group - skipping");
	}

	// Fix orb drop rates
	for ( i=0; i<OrbDropRates.Length; i++ )
	{
		if ( OrbDropRates[i].MaxHP <= OrbDropRates[i].MinHP )
		{
			OrbDropRates[i].MaxHP = OrbDropRates[i].MinHP + 1;
			OrbDropRates[i].MinChance = FMax(OrbDropRates[i].MinChance, OrbDropRates[i].MaxChance);
			OrbDropRates[i].MaxChance = OrbDropRates[i].MinChance;
		}
		else if ( OrbDropRates[i].MaxChance < OrbDropRates[i].MinChance )
			OrbDropRates[i].MaxChance = 1.0;
	}

	`Log("[Infekkted] Config available in UDKInfekkted.ini");
}

static function int CompareAdjusters(sPlayerCountAdjuster A, sPlayerCountAdjuster B)
{
	return (B.NumPlayers - A.NumPlayers);
}


defaultproperties
{
}
