//================================================================
// Infekkted.InvasionGame
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class InfekktedGame extends CRZGame
	Config(Infekkted)
	DependsOn(WaveConfig);


//================================================
// Config
//================================================

var InfekktedConfig Conf;

//================================================
// Global variables
//================================================

//internal
var InfekktedGRI GRI;
var array<WaveConfig> LoadedWaves;
var bool bPlayersWon;

// adjusters
CONST MAPSIZE_REFERENCE = 2000;
var sMapAdjuster MapAdjuster;
var sPlayerCountAdjuster PlayercountAdjuster;
var bool bNeedRecalcPCAdjuster;

// wave
var WaveConfig CurrentWave;
var bool bCanSpawnMidWave;
var int AdjustedTotalMonsters;
var int AdjustedMaxDensity;
var float AdjustedSpawnRate;
var int MonstersListTotalWeight;
var float MonstersToSpawn;
var int SpawnedMonsters;

// overtime penalty
var ePenaltyMode CurrentPenalty;
var int PenaltyCount;

//================================================
// Game init
//================================================

function PostBeginPlay()
{
	Super.PostBeginPlay();

	// force some values
	GoalScore = 0;
	bForceRespawn = true;
	TimeLimit = 0;

	// team damage
	//FriendlyFireScale = 1.0;  // only if we extend TeamGame

	Conf = new class'InfekktedConfig';
	Conf.Init();

	CalcMapAdjusters();

	Conf.PerPlayerDifficultyAdjusters.Sort(CompareAdjusters);

	LoadWaves();
}

static function int CompareAdjusters(sPlayerCountAdjuster A, sPlayerCountAdjuster B)
{
	return (B.NumPlayers - A.NumPlayers);
}

function LoadWaves()
{
	local array<String> AllWaves;
	local int i, j;
	local WaveConfig Wave;

	class'WaveConfig'.static.GetWavesList(AllWaves);

	for ( i=0; i<Conf.Waves.Length; i++ )
	{
		// find wave in waves list
		for ( j=0; j<AllWaves.Length; j++ )
			if ( AllWaves[j] ~= Conf.Waves[i] )
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
				`Log("[Infekkted] Wave " $ i $ " '" $ Conf.Waves[i] $ "' has invalid configuration - skipping");
		}
		else
			`Log("[Infekkted] Wave " $ i $ " '" $ Conf.Waves[i] $ "' not found - skipping");
	}
		
	if ( LoadedWaves.Length == 0 )
		`Log("[Infekkted] ERROR: Game doesn't have any waves!");
}

function CalcMapAdjusters()
{
	local int i;
	local float Size, SizeDiff;

	i = Conf.MapAdjusters.Find('Map', WorldInfo.GetMapName(true));
	if ( i != INDEX_None )
		MapAdjuster = Conf.MapAdjusters[i];
	else
	{
		`Log("[DEBUG] Using fallback AutoMapAdjuster");
		Size = CalcAvgMapSize();
		`Log("[DEBUG] Calculated avg mapsize: " $ Size);
		SizeDiff = Size / MAPSIZE_REFERENCE;
		`Log("[DEBUG] SizeDiff = " $ SizeDiff);
		MapAdjuster.TotalMonsters = SizeDiff * Conf.AutoMapAdjuster.TotalMonsters;
		MapAdjuster.SpawnRate = SizeDiff * Conf.AutoMapAdjuster.SpawnRate;
		MapAdjuster.MaxDensity = SizeDiff * Conf.AutoMapAdjuster.MaxDensity;
	}
}

function InitGameReplicationInfo()
{
    Super.InitGameReplicationInfo();

    GRI = InfekktedGRI(GameReplicationInfo);
	GRI.CurrentWave = 0;
	GRI.TimeLimit = 1;  // Set TimeLimit to non-zero so HUD displays RemainingTime and not ElapsedTime
}


//================================================
// General
//================================================

function UpdateGlobalAdjusters()
{
	AdjustedTotalMonsters = CurrentWave.TotalMonsters * MapAdjuster.TotalMonsters * PlayercountAdjuster.TotalMonsters;
	AdjustedSpawnRate = CurrentWave.SpawnRate * MapAdjuster.SpawnRate * PlayercountAdjuster.SpawnRate;
	AdjustedMaxDensity = CurrentWave.MaxDensity * MapAdjuster.MaxDensity * PlayercountAdjuster.MaxDensity;
}


//================================================
// Game states & logic
//================================================

function StartCountdown()
{
	// done in PreWaveCountdown
}

// Called by GRI when RemainingTime reaches 0
function TimeUp()
{
	// done in ze States
}

State PreWaveCountdown
{
	function BeginState(Name PrevStateName)
	{
		local Controller C;
		local int i;

		// Setup new wave
		CurrentWave = LoadedWaves[GRI.CurrentWave];

		if ( bNeedRecalcPCAdjuster )
			RecalcPlayercountAdjuster();
		else
			UpdateGlobalAdjusters();

		// Respawn all dead players
		foreach WorldInfo.AllControllers(class'Controller', C)
		{
			if ( InfekktedPRI(C.PlayerReplicationInfo) != none && !C.PlayerReplicationInfo.bOnlySpectator && C.Pawn == None )
			{
				C.PlayerReplicationInfo.bOutOfLives = false;
				C.PlayerReplicationInfo.bReadyToPlay = true;

				if ( PlayerController(C) != None )
					C.GotoState('PlayerWaiting');

				RestartPlayer(C);
			}
		}

		MonstersListTotalWeight = 0;
		for ( i=0; i<CurrentWave.LoadedMonsters.Length; i++ )
			MonstersListTotalWeight += CurrentWave.LoadedMonsters[i].Frequency;

		// reset wave values
		bCanSpawnMidWave = true;
		PenaltyCount = 0;
		CurrentPenalty = PNLTY_None;
		MonstersToSpawn = 0.0;
		SpawnedMonsters = 0;

		// delay stuff a bit for smoothness
		GRI.bStopCountDown = true;
		SetTimer(3.0, false, 'StartCountdown');
	}

	function StartCountdown()
	{
		GRI.SetRemainingTime(CurrentWave.PreWaveCountdown);
		GRI.bStopCountDown = false;
	}

	function TimeUp()
	{
		GRI.SendNewWaveName(CurrentWave.FriendlyName);
		GotoState('MatchInProgress');
	}

	function InitActivePlayer(Controller C)
	{
		Global.InitActivePlayer(C);

		if ( C.PlayerReplicationInfo != None )
		{
			C.PlayerReplicationInfo.bOutOfLives = false;
			// force spawn
			C.PlayerReplicationInfo.bReadyToPlay = true;
			RestartPlayer(C);
		}
	}

	function bool MatchIsInProgress()
	{
		return true;
	}
}

State MatchInProgress
{
	function BeginState(Name PrevStateName)
	{
		if ( PrevStateName == 'PendingMatch' )
		{
			Super.BeginState(PrevStateName);    // sets up a bunch of stuff
			GotoState('PreWaveCountdown');
			return;
		}

		GRI.SetRemainingTime(CurrentWave.WaveTimeLimit);
	}

	function InitActivePlayer(Controller C)
	{
		Global.InitActivePlayer(C);

		if ( C.PlayerReplicationInfo != None )
		{
			if ( bCanSpawnMidWave )
			{
				C.PlayerReplicationInfo.bOutOfLives = false;
				// force spawn
				C.PlayerReplicationInfo.bReadyToPlay = true;
				RestartPlayer(C);
			}
			else
			{
				C.PlayerReplicationInfo.bOutOfLives = true;
				// do not send to spec yet, let the client experience the Intro - send to spec in RestartPlayer()
			}
		}
	}

	function TimeUp()
	{
		CurrentPenalty = CurrentWave.WaveOvertimePenalty;
	}

	function Timer()
	{
		local PlayerController PC;
		local CRZPawn P;

		if ( SpawnedMonsters < AdjustedTotalMonsters )
			SpawnMonsters();
		else
			ApproachingEndOfWave();

		// force respawn failsafe
		if ( bCanSpawnMidWave )
		{
			foreach WorldInfo.AllControllers(class'PlayerController', PC)
			{
				if ( PC.Pawn == None && !PC.PlayerReplicationInfo.bOnlySpectator && !PC.IsTimerActive('DoForcedRespawn') )
					PC.ServerRestartPlayer();
			}
		}

		if ( NeedPlayers() )
			AddBot();

		if ( CurrentPenalty != PNLTY_None )
		{
			// hurt only once every 3 secs, otherwise it "spams" too much
			PenaltyCount ++;
			if ( PenaltyCount >= 3 )
			{
				PenaltyCount = 0;
				Switch (CurrentPenalty)
				{
					case PNLTY_Degen:
						foreach WorldInfo.AllPawns(class'CRZPawn', P)
						{
							if ( P.Health > 1 )
								P.TakeDamage(Min(10, P.Health-1), None, P.Location, Vect(0,0,0), class'IFDmgType_Overtime');
						}
						break;

					case PNLTY_DegenKill:
						foreach WorldInfo.AllPawns(class'CRZPawn', P)
						{
							P.TakeDamage(10, None, P.Location, Vect(0,0,0), class'IFDmgType_Overtime');
						}
						break;

					case PNLTY_Death:
						foreach WorldInfo.AllPawns(class'CRZPawn', P)
						{
							//TODO: I'd love a lightning strike FX for this!!
							P.Died(None, class'IFDmgType_Overtime', P.Location);
							break;
						}
						break;
				}
			}
		}
	}

	/** Called every second as long as there are monsters to spawn */
	function SpawnMonsters()
	{
		local ToxikkMonster M;
		local int Count;

		// do not accumulate monsters in the to-spawn list if the spawning is currently blocked
		if ( MonstersToSpawn < 1.0 )
			MonstersToSpawn += AdjustedSpawnRate / 60.f;

		// no monster to spawn at this time
		if ( MonstersToSpawn < 1.0 )
			return;

		// check density
		foreach WorldInfo.AllPawns(class'ToxikkMonster', M)
			Count++;
		if ( Count >= AdjustedMaxDensity )
			return;

		// spawn monsters
		while ( MonstersToSpawn >= 1.0 && SpawnedMonsters < AdjustedTotalMonsters )
		{
			if ( SpawnMonster() )
			{
				MonstersToSpawn -= 1.0;
				SpawnedMonsters++;
			}
			else
				break;
		}
	}

	/** Summon a monster for the current wave. True if success */
	function bool SpawnMonster()
	{
		local int rng, i, pick;
		local Controller C;
		local NavigationPoint StartSpot;
		local Pawn M;

		rng = Rand(MonstersListTotalWeight);
		for ( i=0; i<CurrentWave.LoadedMonsters.Length; i++ )
		{
			rng -= CurrentWave.LoadedMonsters[i].Frequency;
			if ( rng < 0 )
			{
				pick = i;
				break;
			}
		}

		C = Spawn(CurrentWave.LoadedMonsters[pick].LoadedClass.default.ControllerClass);
		if ( C != None )
		{
			StartSpot = FindMonsterStart(C);
			if ( StartSpot != None )
			{
				M = Spawn(CurrentWave.LoadedMonsters[pick].LoadedClass,,, StartSpot.Location, StartSpot.Rotation);
				if ( M != None )
				{
					ApplyAdjustements(M, CurrentWave.LoadedMonsters[pick]);
					C.Possess(M, false);
					return true;
				}
			}
			C.Destroy();
		}
		return false;
	}

	function ApplyAdjustements(Pawn M, sMonsterDef MonsterDef)
	{
		// without adjusters
		M.SetDrawScale(MonsterDef.Scale);
		M.GroundSpeed *= MonsterDef.Speed;
		// with adjusters
		//TODO: see about the formula: param *= (MonsterDef.param + Adjuster.param - 1.0)
		M.Health = MonsterDef.Health * PlayercountAdjuster.Health;
		if ( M.IsA('ToxikkMonster') )
		{
			ToxikkMonster(M).PunchDamage *= MonsterDef.MeleeDamage * PlayercountAdjuster.MeleeDamage;
			ToxikkMonster(M).LungeDamage *= MonsterDef.RangeDamage * PlayercountAdjuster.RangeDamage;
			ToxikkMonster(M).ProjDamageMult *= MonsterDef.RangeDamage * PlayercountAdjuster.RangeDamage;
		}
	}

	/** When there are no more monsters to spawn, start counting towards end of wave.
	 * Here we will decide when it is a good time to spawn the Boss, if any.
	 * We will also add logic for respawning the last monsters when they are unfindable.
	 */
	function ApproachingEndOfWave()
	{
		local ToxikkMonster M;
		local int Count;

		if ( CurrentWave.Boss.LoadedClass != None )
		{
			// Check if we should go into BossInProgress
			foreach WorldInfo.AllPawns(class'ToxikkMonster', M)
				Count++;

			if ( Count <= 0.2*AdjustedMaxDensity )
				GotoState('BossInProgress');
		}
		else
			CheckLastMonsters();
	}

	// Relocate "unreachable" monsters - we are just checking if anything happened past the last X seconds
	// If no monsters left, end of wave
	//NOTE: maybe we should run the relocation checks during the whole wave, instead of only when approaching end ?
	function CheckLastMonsters()
	{
		local ToxikkMonster M;
		local int Count;

		foreach WorldInfo.AllPawns(class'ToxikkMonster', M)
		{
			Count++;
			if ( ToxikkMonsterController(M.Controller) != None
			&& WorldInfo.TimeSeconds - ToxikkMonsterController(M.Controller).LastTimeSomethingHappened > 30
			&& RelocateMonster(M) )
			{
				ToxikkMonsterController(M.Controller).LastTimeSomethingHappened = WorldInfo.TimeSeconds;
				// `Log("[DEBUG] Monster " $ String(M.Name) $ " was relocated!");
			}
		}

		if ( Count == 0 )
			EndOfWave();
	}

	function bool RelocateMonster(ToxikkMonster M)
	{
		local NavigationPoint Spot;

		Spot = FindMonsterStart(M.Controller);
		if ( Spot != None && M.SetLocation(Spot.Location) )
		{
			M.Velocity = Vect(0,0,0);
			M.SetRotation(Spot.Rotation);
			M.SetPhysics(PHYS_Falling);
			return true;
		}
		return false;
	}

	function Killed(Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> damageType)
	{
		Global.Killed(Killer, KilledPlayer, KilledPawn, damageType);

		if ( KilledPlayer != None && InfekktedPRI(KilledPlayer.PlayerReplicationInfo) != None )
		{
			if ( UTPlayerController(KilledPlayer) != None )
				SendToSpec(UTPlayerController(KilledPlayer));

			// cannot spawn new players anymore after first died
			bCanSpawnMidWave = false;

			PlayerIsOut(KilledPlayer, Killer);
		}
	}

	function SendToSpec(UTPlayerController PC)
	{
		PC.ClearTimer('SetDroneViewToKiller');
		PC.ServerSpectate();
		InfekktedPRI(PC.PlayerReplicationInfo).ClientForceSpectate();
	}

	function EndOfWave()
	{
		if ( GRI.CurrentWave+1 < LoadedWaves.Length )
		{
			BroadcastLocalizedMessage(class'InfekktedMessage', 3);
			GRI.CurrentWave += 1;
			GotoState('PreWaveCountdown');
		}
		else
			GameOver(true);
	}
}

// Almost same as MatchInProgress
State BossInProgress extends MatchInProgress
{
	function BeginState(Name PrevStateName)
	{
		CurrentPenalty = PNLTY_None;
		PenaltyCount = 0;
		bCanSpawnMidWave = false;   // still not sure

		GRI.SetRemainingTime(CurrentWave.BossTimeLimit);
		// We don't want to count down the remaining time until boss is actually spawned.
		GRI.bStopCountDown = true;
	}

	// We have to inhibit Timer until the boss is spawned otherwise CheckLastMonsters will end the wave.
	// We put boss spawn in Timer because spawning can fail sometimes (bad collision checks etc).
	function Timer()
	{
		if ( GRI.bStopCountDown )
		{
			if ( SpawnBoss() )
				GRI.bStopCountDown = false;
		}
		else
			Super.Timer();
	}

	function TimeUp()
	{
		CurrentPenalty = CurrentWave.BossOvertimePenalty;
	}

	// If we don't set bCanSpawnMidwave=false for BossInProgress, if somebody joins after boss spawn,
	// fall again into (SpawnedMonsters < AdjustedTotalMonsters) so we must inhibit SpawnMonsters
	function SpawnMonsters()
	{
		ApproachingEndOfWave();
	}

	// Similar to SpawnMonster
	function bool SpawnBoss()
	{
		local Controller C;
		local NavigationPoint StartSpot;
		local Pawn M;

		C = Spawn(CurrentWave.Boss.LoadedClass.default.ControllerClass);
		if ( C != None )
		{
			StartSpot = FindMonsterStart(C);
			if ( StartSpot != None )
			{
				M = Spawn(CurrentWave.Boss.LoadedClass,,, StartSpot.Location, StartSpot.Rotation);
				if ( M != None )
				{
					ApplyAdjustements(M, CurrentWave.Boss);
					if ( ToxikkMonster(M) != None )
						ToxikkMonster(M).SetMonsterIsBoss();
					C.Possess(M, false);
					return true;
				}
			}
			C.Destroy();
		}
		return false;
	}

	function ApproachingEndOfWave()
	{
		CheckLastMonsters();
	}

	// When boss dies, kill all remaining minions to end wave immediately
	function Killed(Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> damageType)
	{
		local ToxikkMonster M;

		Super.Killed(Killer, KilledPlayer, KilledPawn, damageType);

		if ( ToxikkMonster(KilledPawn) != None && ToxikkMonster(KilledPawn).bIsBossMonster && KilledPawn.Class == CurrentWave.Boss.LoadedClass )
		{
			foreach WorldInfo.AllPawns(class'ToxikkMonster', M)
			{
				if ( M != KilledPawn )
					M.Suicide();
			}
		}
	}
}


//================================================
// End game
//================================================

function GameOver(bool bWinner)
{
	bPlayersWon = bWinner;
	GRI.Winner = GRI.GetCurrentBestPlayer();    // always set even if loss, to avoid log flood
	EndGame(PlayerReplicationInfo(GRI.Winner), "triggered");
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
	local ToxikkMonster M;
	local Controller C;
	local Vehicle V;

	if ( Reason ~= "triggered" )
	{
		EndTime = WorldInfo.TimeSeconds + EndTimeDelay;

		if ( bPlayersWon )
		{
			EndGameFocus = Controller(Winner.Owner).Pawn;
			if ( EndGameFocus == None && Controller(Winner.Owner) != None )
			{
				RestartPlayer(Controller(Winner.Owner));
				EndGameFocus = Controller(Winner.Owner).Pawn;
			}
			// redirect to owner if using remote controlled vehicle (e.g. Redeemer)
			V = Vehicle(EndGameFocus);
			if (V != None && !V.bAttachDriver && V.Driver != None)
				EndGameFocus = V.Driver;
		}
		else
		{
			foreach WorldInfo.AllPawns(class'ToxikkMonster', M)
			{
				if ( M.bIsBossMonster )
				{
					EndGameFocus = M;
					break;
				}
				else if ( EndGameFocus == None )
					EndGameFocus = M;
			}
		}

		if ( EndGameFocus != None )
			EndGameFocus.bAlwaysRelevant = true;

		foreach WorldInfo.AllControllers(class'Controller', C)
		{
			if ( InfekktedPRI(C.PlayerReplicationInfo) != None )
				C.GameHasEnded(EndGameFocus, bPlayersWon);
			else
				C.GameHasEnded(EndGameFocus, !bPlayersWon);
		}

		return true;
	}
	return false;
}

function PlayEndOfMatchMessage()
{
	local UTPlayerController PC;

	foreach WorldInfo.AllControllers(class'UTPlayerController', PC)
	{
		if ( PC.PlayerReplicationInfo != None && !PC.PlayerReplicationInfo.bOnlySpectator )
		{
			//PC.ClientPlayAnnouncement(CRZVictoryMessageClass, bPlayersWon ? 2 : 3);
			PC.ReceiveLocalizedMessage(CRZVictoryMessageClass, bPlayersWon ? 2 : 3);
		}
	}
}


//================================================
// Player login, spawn, logout
//================================================

event PostLogin(PlayerController NewPlayer)
{
	Super.PostLogin(NewPlayer);

	if ( NewPlayer.PlayerReplicationInfo != None && !NewPlayer.PlayerReplicationInfo.bOnlySpectator )
		InitActivePlayer(NewPlayer);
}

function bool AllowBecomeActivePlayer(PlayerController PC)
{
	InitActivePlayer(PC);
	return true;
}

function InitializeBot(UTBot NewBot, UTTeamInfo BotTeam, const out CharacterInfo BotInfo)
{
	Super.InitializeBot(NewBot, BotTeam, BotInfo);

	InitActivePlayer(NewBot);
}

/** Grouped function for PostLogin, AllowBecomeActivePlayer, and InitializeBot */
function InitActivePlayer(Controller C)
{
	bNeedRecalcPCAdjuster = true;
	// rest done in ze States
}

// This is called when player wants to spawn, when he clicks while in Intro/lobby
// If he joined late, he's already OUT and must be sent to spec instead
function RestartPlayer(Controller NewPlayer)
{
	if ( UTPlayerController(NewPlayer) != None && NewPlayer.PlayerReplicationInfo != None && NewPlayer.PlayerReplicationInfo.bOutOfLives )
		SendToSpec(UTPlayerController(NewPlayer));
	else
		Super.RestartPlayer(NewPlayer);
}

function SetPlayerDefaults(Pawn PlayerPawn)
{
	Super.SetPlayerDefaults(PlayerPawn);

	if ( CRZPawn(PlayerPawn) == None )
		return;

    // remove behind view in case we were just spectating
	if ( UTPlayerController(PlayerPawn.Controller) != None )
		UTPlayerController(PlayerPawn.Controller).SetBehindView(false);

	if ( bNeedRecalcPCAdjuster )
		RecalcPlayercountAdjuster();
}

function Logout(Controller Exiting)
{
	if ( GRI.bMatchHasBegun && !GRI.bMatchIsOver )
	{
		if ( Exiting != None && Exiting.PlayerReplicationInfo != None && !Exiting.PlayerReplicationInfo.bOnlySpectator )
		{
			if ( !Exiting.PlayerReplicationInfo.bOutOfLives )
				PlayerIsOut(Exiting);

			bNeedRecalcPCAdjuster = true;
		}
	}
	Super.Logout(Exiting);
}

function RecalcPlayercountAdjuster()
{
	local int i, Count, j, cur;

	for ( i=0; i<GRI.PRIArray.Length; i++ )
	{
		if ( InfekktedPRI(GRI.PRIArray[i]) != None && !GRI.PRIArray[i].bOnlySpectator )
			Count++;
	}

	for ( i=2; i<=Count; i++ )
	{
		// find the right adjuster for each progressive playercount
		cur = INDEX_NONE;
		for ( j=0; j<Conf.PerPlayerDifficultyAdjusters.Length; j++ )
		{
			if ( Conf.PerPlayerDifficultyAdjusters[j].NumPlayers > i )
				break;
			cur = j;
		}
		if ( cur != INDEX_NONE )
		{
			if ( Conf.bMultiplicativeAdjusters )
			{
				PlayercountAdjuster.TotalMonsters *= Conf.PerPlayerDifficultyAdjusters[cur].TotalMonsters;
				PlayercountAdjuster.SpawnRate *= Conf.PerPlayerDifficultyAdjusters[cur].SpawnRate;
				PlayercountAdjuster.MaxDensity *= Conf.PerPlayerDifficultyAdjusters[cur].MaxDensity;
				PlayercountAdjuster.Health *= Conf.PerPlayerDifficultyAdjusters[cur].Health;
				PlayercountAdjuster.MeleeDamage *= Conf.PerPlayerDifficultyAdjusters[cur].MeleeDamage;
				PlayercountAdjuster.RangeDamage *= Conf.PerPlayerDifficultyAdjusters[cur].RangeDamage;
			}
			else
			{
				PlayercountAdjuster.TotalMonsters += Conf.PerPlayerDifficultyAdjusters[cur].TotalMonsters - 1.0;
				PlayercountAdjuster.SpawnRate += Conf.PerPlayerDifficultyAdjusters[cur].SpawnRate - 1.0;
				PlayercountAdjuster.MaxDensity += Conf.PerPlayerDifficultyAdjusters[cur].MaxDensity - 1.0;
				PlayercountAdjuster.Health += Conf.PerPlayerDifficultyAdjusters[cur].Health - 1.0;
				PlayercountAdjuster.MeleeDamage += Conf.PerPlayerDifficultyAdjusters[cur].MeleeDamage - 1.0;
				PlayercountAdjuster.RangeDamage += Conf.PerPlayerDifficultyAdjusters[cur].RangeDamage - 1.0;
			}
		}
	}
	bNeedRecalcPCAdjuster = false;
	UpdateGlobalAdjusters();

	`Log("[DEBUG] New PCAdjuster:"
		@ "Total=" $ PlayercountAdjuster.TotalMonsters
		@ "Spawn=" $ PlayercountAdjuster.SpawnRate
		@ "Dens=" $ PlayercountAdjuster.MaxDensity
		@ "HP=" $ PlayercountAdjuster.Health
		@ "Melee=" $ PlayercountAdjuster.MeleeDamage
		@ "Range=" $ PlayercountAdjuster.RangeDamage);
}


//================================================
// Damage and kills
//================================================

function ReduceDamage(out int Damage, Pawn Injured, Controller InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	Super.ReduceDamage(Damage, injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

	// Take care of team-damage !
	// Since all players are on team 255, FriendlyFireScale must not have been taken into account (we forced it to 1.0 anyways)
	// What is the best way to check players are not monster ? CRZPawn ?? CRZPRI ???
	if ( Damage > 0
		&& Injured != None && InfekktedPRI(Injured.PlayerReplicationInfo) != None
		&& InstigatedBy != None && InfekktedPRI(InstigatedBy.PlayerReplicationInfo) != None
		&& Injured != InstigatedBy.Pawn )
	{
		// retaliate
		if ( InstigatedBy.Pawn != None )
			InstigatedBy.Pawn.TakeDamage(Damage * Conf.TeamDamageRetaliate, InstigatedBy, Injured.Location, Vect(0,0,0), DamageType);

		// reduce
		Damage *= Conf.TeamDamageDirect;
	}
}

function Killed(Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> damageType)
{
	//TODO: override all this shit later
	Super.Killed(Killer, KilledPlayer, KilledPawn, damageType);
}

function ScoreKill(Controller Killer, Controller Other)
{
	//TODO: see if there's anything to do here
}

function PlayerIsOut(Controller OutPlayer, optional Controller Killer=None)
{
	local int i, Count;
	local PlayerReplicationInfo LastSurvivor;
	local PlayerController PC;

	OutPlayer.PlayerReplicationInfo.bOutOfLives = true;

	for ( i=0; i<GRI.PRIArray.Length; i++ )
	{
		if ( GRI.PRIArray[i] != None && !GRI.PRIArray[i].bOnlySpectator && !GRI.PRIArray[i].bOutOfLives )
		{
			Count++;
			LastSurvivor = GRI.PRIArray[i];
		}
	}
	if ( Count == 0 )
	{
		GameOver(false);
	}
	else if ( Count == 1 )
	{
		// Last survivor
		BroadcastLocalizedMessage(class'InfekktedMessage', 2, LastSurvivor);
	}
	else
	{
		foreach WorldInfo.AllControllers(class'PlayerController', PC)
		{
			// Player is OUT
			if ( PC != OutPlayer && PC != Killer )
				PC.ReceiveLocalizedMessage(class'InfekktedMessage', 1, OutPlayer.PlayerReplicationInfo);
		}
	}
}

function SendToSpec(UTPlayerController PC)
{
	// done in MatchInProgress
}


//================================================
// Skill class and XP
//================================================

function float CalcMatchSkillForPlayer(CRZPlayerController PC)
{
	`Log("[TODO] CalcMatchSkillForPlayer");

	return Super.CalcMatchSkillForPlayer(PC);
}

function int CalcMatchXPForPlayer(CRZPlayerController PC)
{
	`Log("[TODO] CalcMatchXPForPlayer");

	return Super.CalcMatchXPForPlayer(PC);
}


//================================================
// Misc
//================================================

function float CalcAvgMapSize()
{
	local NavigationPoint P;
	local float Weight, Total;
	local Vector Center;
	local float AvgDist;

	// calc center
	Total = 0;
	foreach WorldInfo.AllNavigationPoints(class'NavigationPoint', P)
	{
		Weight = WeightForNavPoint(P);
		if ( Weight > 0 )
		{
			Center = (Total / (Total+Weight))*Center + (Weight / (Total+Weight))*P.Location;
			Total += Weight;
		}
	}

	if ( Total == 0 )
	{
		`Log("[Infekkted] Warning: map has no navigation!");
		return MAPSIZE_REFERENCE;
	}

	// calc average distance from center (with less importance along Z axis)
	AvgDist = 0.0;
	foreach WorldInfo.AllNavigationPoints(class'NavigationPoint', P)
	{
		AvgDist += (WeightForNavPoint(P) / Total) * VSize( (P.Location - Center)*Vect(1.0,1.0,0.5) );
	}
	return AvgDist;
}

//TODO: add more types
static function float WeightForNavPoint(NavigationPoint P)
{
	if ( P.IsA('PlayerStart') ) return 3;
	if ( P.IsA('PathNode') ) return 1;
	return 0;
}

function NavigationPoint FindMonsterStart(Controller C)
{
	local NavigationPoint P;
	local float BestRating, NewRating;
	local array<NavigationPoint> BestList;

	// allow GameRulesModifiers to override playerstart selection
	if ( BaseMutator != None )
	{
		P = BaseMutator.FindPlayerStart(C);
		if ( P != None )
			return P;
	}

	foreach WorldInfo.AllNavigationPoints(class'NavigationPoint', P)
	{
		NewRating = RateMonsterStart(P, C);
		if ( NewRating > BestRating )
		{
			BestRating = NewRating;
			BestList.Length = 0;
			BestList.AddItem(P);
		}
		else if ( NewRating == BestRating )
			BestList.AddItem(P);
	}
	if ( BestRating < 0 || BestList.Length == 0 )
		return None;

	return BestList[Rand(BestList.Length)];
}

function float RateMonsterStart(NavigationPoint P, Controller C)
{
	local float Score;
	local Pawn Other;
	local CRZPawn OtherPlayer;
	local float Dist;

	if ( P.Base == None )
		return -1;
	if ( P.NetworkID == -1 )    // Is this actually right ???
		return -1;

	// PathNodes are more desireable
	if ( P.IsA('PathNode') )
		Score = 100;
	else if ( P.IsA('PlayerStart') )
		Score = 90;
	else
		Score = 80;

	if ( P.bDestinationOnly )
		Score -= 20;

	foreach WorldInfo.AllPawns(class'Pawn', Other)
	{
		// avoid overlap
		if ( Abs(Other.Location.Z - P.Location.Z) < P.CylinderComponent.CollisionHeight + Other.CylinderComponent.CollisionHeight
		&& VSize2D(Other.Location - P.Location) < P.CylinderComponent.CollisionRadius + Other.CylinderComponent.CollisionRadius )
			return -1;

		// avoid players
		OtherPlayer = CRZPawn(Other);
		if ( OtherPlayer != None )
		{
			Dist = VSize(OtherPlayer.Location - P.Location);

			// avoid spawning with a direct line of sight
			if ( FastTrace(P.Location, OtherPlayer.Location+Vect(0,0,1)*OtherPlayer.CylinderComponent.CollisionHeight) )
			{
				// avoid spawning in front
				if ( ((P.Location - OtherPlayer.Location) / Dist) Dot Vector(OtherPlayer.Rotation) > 0.42 )
					Score -= FMax((100.0 - Dist*0.05), 0);  // dist 2000
				else if ( Dist < 2000 )
					Score -= FMax((50.0 - Dist*0.05), 0);   // dist 1000
			}
			else
				Score -= FMax((25.0 - Dist*0.05), 0);       // dist 500

			if ( Score < 0 )
				return -1;
		}
	}

	return Score;
}

function bool WantsPickups(UTBot B)
{
	return true;
}

defaultproperties
{
	Acronym="IF"
	MapPrefixes[0]="BL"
	MapPrefixes[1]="CC"
	MapPrefixes[2]="AD"
	MapPrefixes[3]="IF"

	PlayerReplicationInfoClass=class'InfekktedPRI'
	GameReplicationInfoClass=class'InfekktedGRI'

	// Default set of options to publish to the online service
	OnlineGameSettingsClass=class'CRZGameSettingsBL'
	// Deathmatch games don't care about teams for voice chat
	bIgnoreTeamForVoiceChat=true
	bGivePhysicsGun=false
	OnlineStatsWriteClass=Class'CRZStatsWriteBL'
}
