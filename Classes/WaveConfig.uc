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

/* Target config

[WaveConfig1 PerObjectConfig]
; Total monsters count for this wave, before any of the adjustements
TotalMonsters=60
; Number of monsters to spawn per minute. Average.
SpawnRate=30
; Maximum monsters count on map at any given time. If this amount is reached no more monster will spawn until some die.
Density=30
; Monsters to spawn for this wave. Frequency defines the chance for a monster to spawn compared to others.
; It's all about probabilities, so numbers like 1 vs 100 may end up not spawning at all.
Monsters[0]=(Frequency=5, Class="pkg.class1", Scale=1.0, Health=50, Speed=1.0, MeleeDamage=1.0, RangedDamage=1.0, Extras=)
Monsters[1]=(Frequency=1, Class="pkg.class2", Scale=1.0, Health=500, Speed=1.0, MeleeDamage=1.0, RangedDamage=1.0, Extras=)
; Time limit to finish the wave OR to reach the boss if there is one (boss time not counted in that limit)
WaveTimeLimit=300
; Overtime penalty, when wave is not finished in time
; PNLTY_None : no penalty, game continues, as if no time limit
; PNLTY_Degen : players life drain over time, down to 1
; PNLTY_DegenKill : players life drain over time, until death
; PNLTY_Death : players instantly die, end of game
WaveOvertimePenalty=PNLTY_None
; Boss to summon at the end of this wave
Boss=
; Time limit to kill the boss (seconds)
BossTimeLimit=180
; Overtime penalty, when boss is not killed in time (same values as above)
BossOvertimePenalty=PNLTY_None

[WaveConfig2 PerObjectConfig]
TotalMonsters=80
SpawnRate=40
Density=40
Monsters[0]=(Frequency=3, Class="pkg.class1", Scale=1.0, Health=50, Speed=1.0, MeleeDamage=1.0, RangedDamage=1.0, Extras=)
Monsters[1]=(Frequency=1, Class="pkg.class2", Scale=1.0, Health=500, Speed=1.0, MeleeDamage=1.0, RangedDamage=1.0, Extras=)
WaveTimeLimit=300
WaveOvertimePenalty=PNLTY_Degen
Boss=(Class="pkg.class", Scale=5.0, Health=5000, Speed=0.5, MeleeDamage=5.0, RangedDamage=3.0, Extras=)
BossTimeLimit=180
BossOvertimePenalty=PNLTY_DegenKill

*/


/** Monster definition */
Struct sMonsterDef
{
	/** Defines the chance for a monster to spawn compared to others. It's all about probabiliies, so number like 1 vs 100 may end up not spawning at all. */
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

/** Monsters to spawn for this wave. Frequency defines the chance for a monster to spawn compared to others.
	It's all about probabilities, so number like 1 vs 100 may end up not spawning at all. */
var config array<sMonsterDef> Monsters;

/** Time limit to finish the wave OR to reach the boss if there is one (boss time not included) */
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
