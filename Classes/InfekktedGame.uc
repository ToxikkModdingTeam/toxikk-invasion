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

// Gameplay stuff
var bool bCanSpawnMidWave;
var WaveConfig CurrentWave;
var int PenaltyCount;
var int RemainingMonsters;
var int AdjustedMaxDensity;
var float AdjustedSpawnRate;
var float MonstersToSpawn;
var int MonstersListTotalWeight;
var ePenaltyMode CurrentPenalty;
var bool bPlayersWon;

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
	//FriendlyFireScale = 1.0;  // only if TeamGame

	Conf = new class'InfekktedConfig';
	Conf.Init();

	LoadWaves();
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

function InitGameReplicationInfo()
{
    Super.InitGameReplicationInfo();

    GRI = InfekktedGRI(GameReplicationInfo);
	GRI.CurrentWave = 0;
	GRI.TimeLimit = 1;  // Set TimeLimit to non-zero so HUD displays RemainingTime and not ElapsedTime
}


//================================================
// Game states & logic
//================================================

auto State PendingMatch
{
	function InitActivePlayer(Controller C)
	{
		if ( C.PlayerReplicationInfo != None )
		{
			C.PlayerReplicationInfo.bReadyToPlay = false;
			C.PlayerReplicationInfo.bWaitingPlayer = true;
		}
	}
}

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
		local int i;

		// Setup new wave
		CurrentWave = LoadedWaves[GRI.CurrentWave];

		// TODO: add adjusters!!!
		RemainingMonsters = CurrentWave.TotalMonsters;
		AdjustedSpawnRate = CurrentWave.SpawnRate;
		AdjustedMaxDensity = CurrentWave.MaxDensity;

		MonstersListTotalWeight = 0;
		for ( i=0; i<CurrentWave.LoadedMonsters.Length; i++ )
			MonstersListTotalWeight += CurrentWave.LoadedMonsters[i].Frequency;

		// reset wave values
		bCanSpawnMidWave = true;
		PenaltyCount = 0;
		MonstersToSpawn = 0.0;
		CurrentPenalty = PNLTY_None;

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

		if ( RemainingMonsters > 0 )
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
								P.TakeDamage(Min(10, P.Health-1), None, P.Location, Vect(0,0,0), None);   //TODO: dmgType
						}
						break;

					case PNLTY_DegenKill:
						foreach WorldInfo.AllPawns(class'CRZPawn', P)
						{
							P.TakeDamage(10, None, P.Location, Vect(0,0,0), None);    //TODO: dmgType
						}
						break;

					case PNLTY_Death:
						foreach WorldInfo.AllPawns(class'CRZPawn', P)
						{
							P.Died(None, None, P.Location);     //TODO: dmgType
							//TODO: I'd love a lightning strike FX for this - see about reusing Bullrush'skyrocket
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
		while ( MonstersToSpawn >= 1.0 && RemainingMonsters > 0 )
		{
			if ( SpawnMonster() )
			{
				MonstersToSpawn -= 1.0;
				RemainingMonsters--;
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
		//TODO: apply all the adjusters!
		M.SetDrawScale(MonsterDef.Scale);
		M.Health = MonsterDef.Health; // * CurrentHealthMultiplier;
		M.GroundSpeed *= MonsterDef.Speed;
		if ( M.IsA('ToxikkMonster') )
		{
			ToxikkMonster(M).PunchDamage *= MonsterDef.MeleeDamage; // * CurrentMeleeMultiplier;
			ToxikkMonster(M).LungeDamage *= MonsterDef.RangeDamage; // * CurrentRangeMultiplier;
			ToxikkMonster(M).ProjDamageMult *= MonsterDef.RangeDamage; // * CurrentRangeMultiplier;
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

			if ( Count <= AdjustedMaxDensity / 20.f )
				GotoState('BossInProgress');
		}
		else
			CheckLastMonsters();
	}

	// Very basic for now, but this is where we'll have to teleport unreachable monsters.
	//TODO: each monster pawn should hold a timer, if he hasn't seen shit in 30-60 seconds he should be teleported somewhere else
	function CheckLastMonsters()
	{
		local ToxikkMonster M;

		foreach WorldInfo.AllPawns(class'ToxikkMonster', M)
		{
			return;
		}

		EndOfWave();
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
		// bCanSpawnMidWave = false; // shall we ?
		PenaltyCount = 0;

		GRI.SetRemainingTime(CurrentWave.BossTimeLimit);
		GRI.bStopCountDown = true;
	}

	// We have to inhibit Timer until the boss is spawned otherwise CheckLastMonsters will end the wave.
	// Also we don't want to count down the remaining time until boss is actually spawned.
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

	// This is pretty much duplicate of SpawnMonster, but we leave room for boss-specific adjustements
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

	//TODO: When boss dies, kill all remaining minions to end wave immediately
}

function GameOver(bool bWinner)
{
	bPlayersWon = bWinner;
	GRI.Winner = GRI.GetCurrentBestPlayer();    // always set even if loss, to avoid log flood
	EndGame(PlayerReplicationInfo(GRI.Winner), "triggered");
}

// WIN <=> Winner != None
// LOSE <=> Winner == None
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
	// done in ze States
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
}

function Logout(Controller Exiting)
{
	if ( GRI.bMatchHasBegun && !GRI.bMatchIsOver )
	{
		if ( Exiting != None && Exiting.PlayerReplicationInfo != None && !Exiting.PlayerReplicationInfo.bOnlySpectator && !Exiting.PlayerReplicationInfo.bOutOfLives )
		{
			PlayerIsOut(Exiting);
		}
	}
	Super.Logout(Exiting);
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
	`Log("[Infekkted] Error: call to SendToSpec() outside of wave states!");
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
		Score /= 2;

	// avoid players
	foreach WorldInfo.AllPawns(class'Pawn', Other)
	{
		// avoid overlap
		if ( Abs(Other.Location.Z - P.Location.Z) < P.CylinderComponent.CollisionHeight + Other.CylinderComponent.CollisionHeight
		&& VSize2D(Other.Location - P.Location) < P.CylinderComponent.CollisionRadius + Other.CylinderComponent.CollisionRadius )
			return -1;

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
