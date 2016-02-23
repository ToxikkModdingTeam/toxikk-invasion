class CRZMutator_Invasion extends UTMutator 
	config (Invasion);

//---------------------------------------------
var				int				CurrentWave;
var				int				WaveTimer, WaveMonsters;
var				bool			bCountingDown, bInWave, bGameStarted;

var config		int				MaxOnScreen;
var config		float			SpawnTime;

var config		array<String>					MonsterTypes;
var config		array<String>					BossTypes;
var 			array< Class<CRZMonster> >		RealMonsterTypes;
var 			array< Class<CRZMonster> >		RealBossTypes;
var config		bool							bForceBoss;

var()			array<FakeAttach>				SpawnPoints;

//---------------------------------------------

simulated function SetupSpawns()
{
	local CRZWeaponPickupFactory PF;
	local PlayerStart PS;
	
	ForEach AllActors(Class'PlayerStart',PS)
	{
		SpawnPoints.Add(1);
		SpawnPoints[SpawnPoints.Length-1] = Spawn(Class'FakeAttach',,,PS.Location,PS.Rotation);
	}
	
	ForEach AllActors(Class'CRZWeaponPickupFactory',PF)
	{
		SpawnPoints.Add(1);
		SpawnPoints[SpawnPoints.Length-1] = Spawn(Class'FakeAttach',,,PF.Location,PF.Rotation);
	}
}

simulated function MessageToAll(string MSG)
{
	local PlayerController PC;
	
	ForEach DynamicActors(Class'PlayerController',PC)
		PC.ClientMessage(MSG);
}

simulated function ForcefulSpawn()
{
	local CRZMonster CRZ;
	local bool bSuccess;
	local int i,l;
	
	i = Rand(BossTypes.Length);
	
	for (l=0; l<Spawnpoints.Length; l++)
	{
		if (!bSuccess)
		{
			CRZ = Spawn(RealBossTypes[i],,,Spawnpoints[l].Location,Spawnpoints[l].Rotation);
			if (CRZ != None)
			{
					bSuccess=true;
					break;
			}
		}
	}
	
	if (CRZ == None)	
		`Log("COULD NOT SPAWN!");
}

simulated function PostBeginPlay()
{
	local int l;
	
	for (l=0; l<MonsterTypes.Length; l++)
	{
		RealMonsterTypes[l] = Class<CRZMonster>(DynamicLoadObject(MonsterTypes[l], Class'Class'));
	}
	
	for (l=0; l<BossTypes.Length; l++)
	{
		RealBossTypes[l] = Class<CRZMonster>(DynamicLoadObject(BossTypes[l], Class'Class'));
	}
	
	SetupSpawns();
}

simulated function ModifyPlayer (Pawn Other)
{
	if (!bGameStarted)
	{
		bGameStarted=true;
		WaveTimer = 11;
		SetTimer(1.0,false,'DecreaseTimer');
	}
}

// Decrease wave timer
simulated function DecreaseTimer()
{
	// Start next wave
	if (WaveTimer-1 <= 0)
		StartWave();
	else
	{
		WaveTimer --;
		SetTimer(1.0,false,'DecreaseTimer');
		MessageToAll("Wave starting in"@string(WaveTimer)$"...");
	}
}

// ACTUALLY START THE WAVE
simulated function StartWave()
{
	bCountingDown=false;
	bInWave=true;
	WaveMonsters=0;
	
	if (bForceBoss)
	{
		ForcefulSpawn();
	}
	else
	{
		SetTimer(SpawnTime,true,'SpawnMonsters');
		SpawnMonsters();
	}
}

// SPAWN THE MONSTERS
simulated function SpawnMonsters()
{
	local CRZMonster CRZ;
	local int Total;
	local int i,l;
	
	// Get total number of monsters
	ForEach DynamicActors(Class'CRZMonster',CRZ)
	{
		Total ++;
	}
	
	// If we already hit limit then don't spawn more
	if (Total >= MaxOnScreen)
		return;
		
	for (l=0; l<Spawnpoints.Length; l++)
	{
		if (Total+1 <= MaxOnScreen)
		{
			CRZ = Spawn(RealMonsterTypes[i],,,SpawnPoints[l].Location,SpawnPoints[l].Rotation);
			if (CRZ != None)
			{
				i = Rand(RealMonsterTypes.Length);
				Total++;
			}
		}
	}
}