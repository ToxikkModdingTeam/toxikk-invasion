//================================================================
// ModularScoreboard.ModularRoster
// ----------------
// Modders should not have to extend Roster,
// since this one redirects updates to the Board class.
// ----------------
// by Chatouille
//================================================================
class InfekktedRoster extends GFxCRZRoster;

var InfekktedScoreboard Board;

struct sb_Field
{
	var int ColIndex;   // reference the column containing this field - in BL it should be the same as own index in Row.Fields
	var GFxObject TF;
	var String CachedValue;
};

struct sb_Row
{
	var GFxObject Container;
	var GFxObject Background;
	var array<sb_Field> Fields;
};

/** Red or non-team players */
var array<sb_Row> RedPlayers;
/** Blue players (only team games) */
var array<sb_Row> BluePlayers;

var bool myTeamGame;


function InitRosterContainer(bool TeamGame, GFxCRZUIScoreboardBase sb, out String GameModeString, out String GameModeDescString)
{
	Super.InitRosterContainer(TeamGame, sb, GameModeString, GameModeDescString);

	myTeamGame = TeamGame;
	Board = InfekktedScoreboard(sb);
}

// Create|Update rows
function SetRow(byte RosterID, byte InfoIndex, CRZPlayerReplicationInfo PRI)
{
	local sb_Row PRow;

	if ( PlayerInfoContainers[RosterID] == None )
		return;

	if ( RosterID == 0 )
	{
		if ( RedPlayers.Length <= InfoIndex )
		{
			CreateNewPlayerRow(PlayerInfoContainers[0], RedPlayers.Length, RosterID, PRow);
			RedPlayers.AddItem(PRow);
		}
		else
			PRow = RedPlayers[InfoIndex];
	}
	else
	{
		if ( BluePlayers.Length <= InfoIndex )
		{
			CreateNewPlayerRow(PlayerInfoContainers[1], BluePlayers.Length, RosterID, PRow);
			BluePlayers.AddItem(PRow);
		}
		else
			PRow = BluePlayers[InfoIndex];
	}

	// delegate to Board so modders don't have to extend Roster
	Board.UpdateRow(PRow, PRI);
}

// Remove rows here when players disconnect
function SetMaxRedPlayers(byte Num)
{
	MySetMaxPlayers(RedPlayers, Num);
}
function SetMaxBluePlayers(byte Num)
{
	MySetMaxPlayers(BluePlayers, Num);
}
function MySetMaxPlayers(out array<sb_Row> Players, byte Num)
{
	local array<ASValue> args;
	local ASValue asval;
	local int i;

	if ( Players.Length <= Num )
		return;

	asval.Type = AS_Boolean;
	asval.b = true;
	args[0] = asval;

	for ( i=Num; i<Players.Length; i++ )
	{
		if ( Players[i].Container != None )
			Players[i].Container.Invoke("removeMovieClip", args);
	}
	Players.Remove(Num, Players.Length-Num);
}

// Create new row for player
function CreateNewPlayerRow(GFxObject Container, byte RowIndex, byte RosterID, out sb_Row PRow)
{
	local float PosY;
	local GFxObject RowCont;
	local int i, j;

	if ( Container == None )
		return;

	PosY = Container.GetFloat("_height");

	if ( myTeamGame )
		RowCont = Container.AttachMovie("TeamScorePlayerInfoEmpty", "ScorePlayerInfo"$RowIndex);
	else
		RowCont = Container.AttachMovie("ScorePlayerInfoEmpty", "ScorePlayerInfo"$RowIndex);
	if ( RowCont == None )
		return;

	// Get builtin elements
	PRow.Container = RowCont;
	PRow.Background = RowCont.GetObject("Background");

	// Create fields
	PRow.Fields.Length = 0;
	j = 0;
	for ( i=0; i<Board.Columns.Length; i++ )
	{
		// Only use the right columns (RosterID=0 for non-team or red, RosterID=1 for blue)
		if ( Board.Columns[i].TeamIndex == RosterID )
		{
			PRow.Fields.Length = j+1;
			PRow.Fields[j].ColIndex = i;

			// create field
			// WARNING: these elements are relative to the left of the row, and not to the center of the board like headers
			PRow.Fields[j].TF = CreateTextfield(RowCont,
					Board.Columns[i].Name,
					Board.Columns[i].bFieldsHTML ? "Jupiter" : "Twode",
					Board.Columns[i].PosX + Board.Columns[i].FieldsOffset.X,
					Board.GetAutoSize(Board.Columns[i].Align),
					Board.Columns[i].Color,
					Board.GetPosY(i, false)
			);

			j++;
		}
	}

	// Initializations
	PRow.Container.SetPosition(0, PosY);
	// delegate other initializations to Board
	Board.InitializeRow(PRow);
}

defaultproperties
{
}
