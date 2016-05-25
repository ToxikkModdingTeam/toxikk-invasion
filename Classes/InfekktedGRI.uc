//================================================================
// Infekkted.InfekktedGRI
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class InfekktedGRI extends CRZGameReplicationInfo;

/** Server Replicated - Calculated average map size (for radar distance) */
var float AvgMapSize;

/** Server Replicated - Current wave index */
var byte CurrentWave;

/** Server Replicated - Name of the new/current wave */
var RepNotify String WaveName;

/** Server Replicated - Whether we are currently in pre-wave countdown */
var bool bPreWaveCountdown;

Replication
{
	if ( bNetInitial )
		AvgMapSize;

	if ( bNetInitial || bNetDirty )
		CurrentWave, WaveName, bPreWaveCountdown;
}

function SetRemainingTime(int NewTime)
{
	RemainingTime = NewTime;
	// force dirty >> update clients
	if ( RemainingMinute == RemainingTime )
		RemainingMinute = RemainingTime-1;
	else
		RemainingMinute = RemainingTime;
}

simulated function Timer()
{
	local int TimerMessageIndex;
	local PlayerController PC;

	//Super.Timer();
	// Override to send a different message for the "next wave" countdown
	//COPY CRZGameReplicationInfo
	if ( (WorldInfo.Game == None && bMatchHasBegun && !bMatchIsOver ) || (WorldInfo.Game!=none && WorldInfo.Game.MatchIsInProgress()) )
		ElapsedTime++;
	if ( WorldInfo.NetMode == NM_Client )
	{
		if ( RemainingMinute != 0 )
		{
			RemainingTime = RemainingMinute;
			RemainingMinute = 0;
		}
	}
	if ( RemainingTime > 0 && !bStopCountDown )
	{
		RemainingTime--;
		if ( WorldInfo.NetMode != NM_Client && RemainingTime % 60 == 0 )
			RemainingMinute = RemainingTime;
	}
	SetTimer(WorldInfo.TimeDilation, true);
	if ( WorldInfo.NetMode == NM_Client && bWarmupRound && RemainingTime > 0 )
		RemainingTime--;
	if (WorldInfo.NetMode != NM_DedicatedServer && (bMatchHasBegun || bWarmupRound) && !bStopCountDown && !bMatchIsOver && Winner == None)
	{
		switch (RemainingTime)
		{
			case 300: TimerMessageIndex = 16; break;
			case 180: TimerMessageIndex = 15; break;
			case 120: TimerMessageIndex = 14; break;
			case 60: TimerMessageIndex = 13; break;
			case 30: TimerMessageIndex = 12; break;
			//case 20: TimerMessageIndex = 11; break;
			default:
				if (RemainingTime <= 10 && RemainingTime > 0)
					TimerMessageIndex = RemainingTime;
				break;
		}
		if (TimerMessageIndex != 0)
		{
			foreach LocalPlayerControllers(class'PlayerController', PC)
				PC.ReceiveLocalizedMessage(class'InfekktedTimerMessage', TimerMessageIndex,,, Self);
		}
	}
	//ENDCOPY

	if ( Role == ROLE_Authority )
	{
		if ( RemainingTime <= 0 && !bStopCountDown )
			InfekktedGame(WorldInfo.Game).TimeUp();
	}
}

function SendNewWaveName(String NewWaveName)
{
	// force dirty >> update clients
	if ( NewWaveName ~= WaveName )
		WaveName = "$"$NewWaveName;
	else
		WaveName = NewWaveName;

	if ( WorldInfo.NetMode == NM_Standalone )
		ReplicatedEvent('WaveName');
}

simulated event ReplicatedEvent(Name VarName)
{
	local PlayerController PC;

	if ( VarName == 'WaveName' )
	{
		if ( Left(WaveName, 1) == "$" )
			WaveName = Mid(WaveName, 1);

		PC = GetALocalPlayerController();
		if ( PC != None && CRZHud(PC.myHUD) != None )
		{
			if ( WaveName != "" )
				CRZHud(PC.myHUD).LocalizedCRZMessage(class'InfekktedMessage', None, None, "Wave " $ (CurrentWave+1) $ ": " $ WaveName, 0);
			else
				CRZHud(PC.myHUD).LocalizedCRZMessage(class'InfekktedMessage', None, None, "Wave " $ (CurrentWave+1), 0);
		}
	}
}

defaultproperties
{
}
