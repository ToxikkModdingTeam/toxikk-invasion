//================================================================
// ModularScoreboard.ModularScoreboard
// ----------------
// Extend this for custom Scoreboards :
// - override Columns in defaultproperties
// - override InitializeRow()
// - override UpdateRow()
// ----------------
// by Chatouille
//================================================================
class InfekktedScoreboard extends GFxCRZUIScoreBoard;

// Some chars like 'I' and ':' are smaller, but this matches most chars correctly
CONST CHAR_WIDTH = 20;

// Table width is dictated by the Rows container, which is around 1400px, that is 200px smaller than board itself
// There is a 20px padding on the left and a 180px extra space on the right
// And we cannot extend that container on the right because it scales the text up
// If we want to align the headers correctly, we need to know that width beforehand
// I hate to hardcode values, but I would need access to the Rows container in LocalizeContent()
CONST TABLE_WIDTH = 1394;

enum eFieldAlign
{
	ALIGN_Left,
	ALIGN_Center,
	ALIGN_Right
};

struct sb_ColumnConfig
{
	/** Unique name of the column, used for title OR as localization key to find title */
	var String Name;
	/** Text alignment in column */
	var eFieldAlign Align;
	/** Minimum size to allocate for this column (in characters length) - only used if bigger than Title length */
	var int MinSize;
	/** Whether to use HTML font (Jupiter) or not (Twode) for head */
	var bool bHeadHTML;
	/** Whether to use HTML font (Jupiter) or not (Twode) for fields */
	var bool bFieldsHTML;
	/** Extra X,Y offset to adjust the head TF after auto-positioning */
	var Vector2D HeadOffset;
	/** Extra X,Y offset to adjust the fields TF after auto-positioning */
	var Vector2D FieldsOffset;
	/** Field color if no HTML */
	var int Color;
	/** (Team only) Team index */
	var byte TeamIndex;

	/** Column title - if set: will be used as is - if unset: will localize (or use) Name */
	var String Title;

	/** (instance) Calculated column width - the biggest between Title length and MinSize */
	var int ColWidth;
	/** (instance) Calculated pos X - relative to the Left of the row */
	var int PosX;
	/** (instance) Column title object */
	var GFxObject HeadTF;
};

var() array<sb_ColumnConfig> Columns;

function LocalizeContent(string Mode)
{
	Super.LocalizeContent(Mode);

	if ( Mode == "Scoreboard" )
	{
		CreateColumns();
	}
}

function CreateColumns()
{
	local int i;
	local int TableLeft, UsedWidth, FreeWidth, Spacing, CurX;

	// Pre-calculate column sizes and required space
	UsedWidth = 0;
	for ( i=0; i<Columns.Length; i++ )
	{
		DefineColumnTitle(i);

		CalcColumnWidth(i);

		UsedWidth += Columns[i].ColWidth;
	}

	// Check space
	if ( UsedWidth > TABLE_WIDTH )
	{
		for ( i=0; i<4; i++ ) `Warn("ERROR: Scoreboard columns do not fit!!! (" $ UsedWidth $ " / " $ TABLE_WIDTH $ ")");
		return;
	}

	// Calculate remaining space and columns spacing
	FreeWidth = TABLE_WIDTH - UsedWidth;
	Spacing = FFloor(float(FreeWidth) / float(Columns.Length-1));

	// Align the table to the left of the board with 18px padding
	// WARNING: this container's elements are centered - annoying
	TableLeft = (-FFloor(CurPageContent.GetFloat("_width")) / 2) + 18;

	// Calculate columns position and create them
	CurX = 0;
	for ( i=0; i<Columns.Length; i++ )
	{
		// calc position : current X + alignment
		// WARNING: PosX is used for both head and fields, so it does not contain the offset!
		Columns[i].PosX = CurX;
		Switch (Columns[i].Align)
		{
			case ALIGN_Center: Columns[i].PosX += Columns[i].ColWidth / 2; break;
			case ALIGN_Right:  Columns[i].PosX += Columns[i].ColWidth;     break;
		}

		// update current X for next col
		CurX += Columns[i].ColWidth + Spacing;

		// create object
		// WARNING: PosX is relative to the left of the board, but elements are relative to center
		// => TableLeft contains the (negative) offset to reach the left of the table
		Columns[i].HeadTF = CreateTextfield(CurPageContent,
				Columns[i].Name,
				Columns[i].bHeadHTML ? "Jupiter" : "Twode",
				TableLeft + Columns[i].PosX + Columns[i].HeadOffset.X,
				GetAutoSize(Columns[i].Align),
				0xFFFFFF,
				GetPosY(i, true)
		);

		SetTFText(Columns[i].HeadTF, Columns[i].bHeadHTML, Columns[i].Title);
	}
}

// Factor code also used by Team scoreboard
function DefineColumnTitle(int i)
{
	local int j;

	// if no title defined, find one (localize or use Name)
	if ( Columns[i].Title == "" )
	{
		Columns[i].Title = Columns[i].Name;
		for ( j=0; j<LocalizedTextFields.length; j++ )
		{
			if ( LocalizedTextFields[j].LocCodeName ~= Columns[i].Name )
			{
				Columns[i].Title = LocalizedTextFields[j].LocalizedString;
				break;
			}
		}
	}
}

// Factor code also used by Team scoreboard
function CalcColumnWidth(int i)
{
	if ( Columns[i].bHeadHTML )
		Columns[i].ColWidth = Max(Len(StripHTML(Columns[i].Title)), Columns[i].MinSize) * CHAR_WIDTH;
	else
		Columns[i].ColWidth = Max(Len(Columns[i].Title), Columns[i].MinSize) * CHAR_WIDTH;
}

// Hardcoded values again, but whatever...
function float GetPosY(int ColIndex, bool bHead)
{
	local int Y;

	if ( bHead )
	{
		Y = -159 + Columns[ColIndex].HeadOffset.Y;
		if ( ! Columns[ColIndex].bHeadHTML )
			Y -= 4;
	}
	else
	{
		Y = Columns[ColIndex].FieldsOffset.Y;
		if ( ! Columns[ColIndex].bFieldsHTML )
			Y -= 4;
	}
	return Y;
}

// This utility should be relocated (CRZHudWrapper?)
static function String StripHTML(String Str)
{
	local String Res;
	local int i;

	Res = "";
	while (true)
	{
		i = InStr(Str, "<");
		if ( i != INDEX_NONE )
		{
			Res $= Left(Str, i);
			Str = Mid(Str, i+1);
			i = InStr(Str, ">");
			if ( i == INDEX_NONE )
			{
				`Warn("[StripHTML] Error parsing: " $ Str);
				return Str$"{ERR}";
			}
			Str = Mid(Str, i+1);
		}
		else
			break;
	}
	Res $= Str;
	return Res;
}

// It would be nice to have a GFxTextField or something
// it could "remember" whether the current font is HTML or not,
// and override SetText() to use SetString when required (ie. implementing this utility)
// Also, it could implement the caching autonomously (see UpdateField below) to be performance-friendly
static function SetTFText(GFxObject TF, bool bHTML, String Text)
{
	if ( bHTML )
		TF.SetString("htmlText", Text);
	else
		TF.SetText(Text);
}

static function String GetAutoSize(eFieldAlign Align)
{
	Switch (Align)
	{
		case ALIGN_Left: return "left";
		case ALIGN_Center: return "center";
		case ALIGN_Right: return "right";
	}
	return "none";
}

/** Initialize row for player */
function InitializeRow(out sb_Row PRow)
{
	UpdateField(PRow, "FROM", "---");
	UpdateField(PRow, "LVL", "--");
	UpdateField(PRow, "SCORE", class'CRZHud'.static.FormatHTMLHexColor("000", class'CRZHud'.default.UIWhiteHtmlHexColor));
	PRow.Background.SetVisible(false);
}

/** Update row for player */
function UpdateRow(out sb_Row PRow, CRZPlayerReplicationInfo PRI)
{
	if ( PRI == None )
		return;

	// EXAMPLE: Just like stock BL scoreboard

	// Highlight myself - TODO: optimize? Lehnard only stated about the cost of SetText/SetString, not sure about other methods like SetVisible
	if ( PRI.IsLocalPlayerPRI() )
		PRow.Background.SetVisible(true);
	else
		PRow.Background.SetVisible(false);

	UpdateField(PRow, "POS", PRI.bOnlySpectator ? "SPC" : class'CRZHud'.static.FormatInteger(PRI.ScoreboardRank,2) );

	UpdateField(PRow, "ID", Left(PRI.PlayerName,9));

	UpdateField(PRow, "FROM", PRI.bBot ? "---" : Caps(Left(PRI.CountryCode,3)) );

	UpdateField(PRow, "CLAN", PRI.ClanTag == "" ? "---" : Caps(Left(PRI.ClanTag,3)) );

	UpdateField(PRow, "LVL", class'CRZHud'.static.FormatInteger(int(PRI.SkillClass), 2));

	UpdateField(PRow, "STATUS", PRI.bOutOfLives ? class'CRZHud'.static.FormatHTMLHexColor("DEAD",class'CRZHud'.default.UIRedHtmlHexColor) : class'CRZHud'.static.FormatHTMLHexColor("OK",class'CRZHud'.default.UIGreenHtmlHexColor));

	UpdateField(PRow, "SCORE", class'CRZHud'.static.FormatHTMLHexColor( PRI.bOnlySpectator ? "---" : class'CRZHud'.static.FormatInteger(int(PRI.Score)) , class'CRZHud'.default.UIWhiteHtmlHexColor));

	UpdateField(PRow, "DEATH", PRI.bOnlySpectator ? "---" : class'CRZHud'.static.FormatInteger(PRI.Deaths));

	UpdateField(PRow, "MXP", PRI.bOnlySpectator ? "---" : class'CRZHud'.static.FormatInteger(PRI.LXP+PRI.MXP));

	UpdateField(PRow, "TIME", class'CRZHud'.static.FormatTime(FMax(0,CRZGameReplicationInfo(PRI.WorldInfo.GRI).GetElapsedTime() - PRI.StartTime)) );

	UpdateField(PRow, "PING", class'CRZHud'.static.FormatPingHexColor(PRI.GetPing()*1000, true));
}

/** Updates flash TF if required - returns true only if the value actually changed */
function bool UpdateField(out sb_Row PRow, String FieldName, String NewVal)
{
	local int i;

	// This is not very well optimized, but uscript doesn't support (hash)maps, so...
	// To improve performance we could pass directly the index of the Field to UpdateField() (instead of FieldName),
	// and then the coder would have to make sure he uses the right indexes.
	// But that makes the code less readable. UpdateRow() is much prettier as it is right now. And we can swap/rename columns without touching code.
	// The cost is minimal anyways, there are no more than 12 columns.

	// NOTE: We use the Fields[] array of the PRow now, because with Team Scoreboard a PRow doesn't contain all columns
	// and the mirrored columns Name are duplicated (not unique anymore)

	for ( i=0; i<PRow.Fields.Length; i++ )
	{
		if ( Columns[PRow.Fields[i].ColIndex].Name ~= FieldName )
		{
			if ( NewVal == PRow.Fields[i].CachedValue )
				return false;

			SetTFText(PRow.Fields[i].TF, Columns[PRow.Fields[i].ColIndex].bFieldsHTML, NewVal);
			PRow.Fields[i].CachedValue = NewVal;
			return true;
		}
	}
	return false;
}

defaultproperties
{
	WidgetBindings(0)=(WidgetName="RosterContainer",WidgetClass=class'InfekktedRoster')

	// Override stock scoreboard titles
	TFContentScoreboard = ()
	TFContentScoreboard[0]=(TFPath="RosterContainer.TitleTF", LocCodeName="RANKING", FieldName="TitleTF", FondType="JupiterBig", TextPosition=-650, SetAutoSize="right", TextColor=0xFFFFFF, YPosition=-236)

	Columns=()
	Columns.Add(( Name="POS",   Align=ALIGN_Left,   MinSize=2, bFieldsHTML=true ))
	Columns.Add(( Name="ID",    Align=ALIGN_Left,   MinSize=9, Color=0xFFFFFF ))
	Columns.Add(( Name="FROM",  Align=ALIGN_Left,   MinSize=3 ))
	Columns.Add(( Name="CLAN",  Align=ALIGN_Left,   MinSize=3 ))
	Columns.Add(( Name="LVL",   Align=ALIGN_Center, MinSize=3, bFieldsHTML=true ))
	Columns.Add(( Name="STATUS",Align=ALIGN_Center, MinSize=4, bFieldsHTML=true ))
	Columns.Add(( Name="SCORE", Align=ALIGN_Center, MinSize=5, bFieldsHTML=true ))
	Columns.Add(( Name="DEATH", Align=ALIGN_Center, MinSize=3, bFieldsHTML=true ))
	Columns.Add(( Name="MXP",   Align=ALIGN_Right,  MinSize=5, bFieldsHTML=true ))
	Columns.Add(( Name="TIME",  Align=ALIGN_Right,  MinSize=5, bFieldsHTML=true ))
	Columns.Add(( Name="PING",  Align=ALIGN_Right,  MinSize=3, bFieldsHTML=true ))
}
