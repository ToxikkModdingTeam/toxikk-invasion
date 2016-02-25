//================================================================
// Infekkted.WaveConfig
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class WaveConfig extends Object
	Config(Infekkted)
	PerObjectConfig;


/** Monster definition */
Struct sMonsterDef
{
	/** Defines the chance for a monster to spawn compared to others */
	var float Frequency;
	/** Class name as String (not loaded) */
	var String Class;
	/** Mesh scale multiplier */
	var float Scale;
	/** Base HP (before difficulty adjustements) */
	var int Health;
	/** Speed multiplier */
	var float Speed;
	/** Melee damage multiplier */
	var float MeleeDamage;
	/** Ranged damage multiplier */
	var float RangeDamage;
	/** Extra options to provide more options for specific monsters (a weapon, enabling a special ability, ...) */
	var String Extras;

	/** Loaded class */
	var class<Pawn> LoadedClass;

	structdefaultproperties
	{
		Frequency=1
		Scale=1.0
		Health=100
		Speed=1.0
		MeleeDamage=1.0
		RangeDamage=1.0
		LoadedClass=None
	}
};


/** Overtime penalty when wave/boss are not done in time */
enum ePenaltyMode
{
	PNLTY_None,
	PNLTY_Degen,
	PNLTY_DegenKill,
	PNLTY_Death
};

/** Countdown before wave actually starts, to let players respawn */
var config int PreWaveCountdown;

/** Name displayed on screen when the wave starts */
var config String FriendlyName;

/** Total monsters count for this wave, before any adjustements/difficulty multipliers */
var config int TotalMonsters;

/** Average number of monsters to spawn per minute */
var config int SpawnRate;

/** Maximum monsters count on map at any given time. If this amount is reached no more monster will spawn until some die */
var config int MaxDensity;

/** Monsters types to spawn for this wave */
var config array<sMonsterDef> Monsters;

/** Time limit to finish the wave OR to reach the boss if there is one */
var config int WaveTimeLimit;

/** Overtime penalty, when wave is not finished in time */
var config ePenaltyMode WaveOvertimePenalty;

/** Boss to summon at end of wave */
var config sMonsterDef Boss;

/** Time limit to kill the boss */
var config int BossTimeLimit;

/** Overtime penalty, when boss is not killed in time */
var config ePenaltyMode BossOvertimePenalty;


/** Actual loaded monsters list */
var array<sMonsterDef> LoadedMonsters;


static function GetWavesList(out array<String> Waves)
{
	local int i, j;

	GetPerObjectConfigSections(default.Class, Waves);
	for ( i=0; i<Waves.length; i++ )
	{
		j = InStr(Waves[i], " ");
		if ( j != -1 )
			Waves[i] = Left(Waves[i], j);
	}
}

static function WaveConfig LoadWave(String WaveName, optional bool bCreateNew=false)
{
	local WaveConfig Wave;

	Wave = new(None, WaveName) class'WaveConfig'(None);
	// check valid TODO: more checks?
	if ( !bCreateNew && (Wave.Monsters.Length == 0) )
		return None;

	return Wave;
}


function LoadMonsters()
{
	local int i;
	local class<Pawn> MonsterClass;

	for ( i=0; i<Monsters.Length; i++ )
	{
		MonsterClass = class<Pawn>(DynamicLoadObject(Monsters[i].Class, class'Class', true));
		if ( MonsterClass != None )
		{
			LoadedMonsters.AddItem(Monsters[i]);
			LoadedMonsters[LoadedMonsters.Length-1].LoadedClass = MonsterClass;
		}
		else
			`Log("[WaveConfig:" $ Name $ "] Failed to load class '" $ Monsters[i].Class $ "' - skipping monster");
	}

	if ( Boss.Class != "" )
	{
		Boss.LoadedClass = class<Pawn>(DynamicLoadObject(Boss.Class, class'Class', true));
		if ( Boss.LoadedClass == None )
			`Log("[WaveConfig:" $ Name $ "] Failed to load class '" $ Boss.Class $ "' - skipping boss");
	}
}


defaultproperties
{
}
