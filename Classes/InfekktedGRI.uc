//================================================================
// Infekkted.InfekktedGRI
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class InfekktedGRI extends CRZGameReplicationInfo;

/** Server Replicated - Current wave index */
var byte CurrentWave;

/** Server Replicated - Name of the new/current wave */
var RepNotify String WaveName;

Replication
{
	if ( bNetInitial || bNetDirty )
		CurrentWave, WaveName;
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
	Super.Timer();

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
		if ( PC != None && CRZHudWrapper(PC.myHUD) != None )
		{
			if ( WaveName != "" )
				CRZHudWrapper(PC.myHUD).LocalizedCRZMessage(class'InfekktedMessage', None, None, "Wave " $ (CurrentWave+1) $ ": " $ WaveName, 0);
			else
				CRZHudWrapper(PC.myHUD).LocalizedCRZMessage(class'InfekktedMessage', None, None, "Wave " $ (CurrentWave+1), 0);
		}
	}
}

defaultproperties
{
}
