//================================================================
// Infekkted.InfekktedScoreboard
// ----------------
// - Replace kills with score (damage-based)
// - Remove BXP
// - Add status (alive / dead)
// ----------------
// by Chatouille
//================================================================
class InfekktedScoreboard extends GFxCRZUIScoreBoard;


function UpdateField(out array <sb_Row> Rows, byte RowIdx, byte ColIdx, optional string ColName, optional string OverrideText, optional object Content)
{	
	local InfekktedPRI PRI;

	PRI = InfekktedPRI(Content);
	if ( PRI != None )
	{
		Switch (ColName)
		{
			case "STATUS":
				UpdateFieldValue(Rows, RowIdx, ColIdx, PRI.bOnlySpectator ? "SPEC" : (PRI.bOutOfLives ? class'CRZHud'.static.FormatHTMLHexColor("DEAD",class'CRZHud'.default.UIRedHtmlHexColor) : class'CRZHud'.static.FormatHTMLHexColor("OK",class'CRZHud'.default.UIGreenHtmlHexColor)) );
				return;
			case "SCORE":
				UpdateFieldValue(Rows, RowIdx, ColIdx, class'CRZHud'.static.FormatHTMLHexColor( PRI.bOnlySpectator ? "---" : class'CRZHud'.static.FormatInteger(int(PRI.Score)) , class'CRZHud'.default.UIWhiteHtmlHexColor));
				return;
		}
	}
	Super.UpdateField(Rows, RowIdx, ColIdx, ColName, OverrideText, Content);
}


defaultproperties
{
	Columns=()
	Columns.Add(( Name="POS",   Align=ALIGN_Left,   MinSize=2, bFieldsHTML=true ))
	Columns.Add(( Name="PLAYERNAME",    Align=ALIGN_Left,   MinSize=9, Color=0xFFFFFF ))
	Columns.Add(( Name="FROM",  Align=ALIGN_Left,   MinSize=3 ))
	Columns.Add(( Name="CLAN",  Align=ALIGN_Left,   MinSize=3 ))
	Columns.Add(( Name="SKILLCLASS",   Align=ALIGN_Center, MinSize=3, bFieldsHTML=true ))
	Columns.Add(( Name="STATUS",Align=ALIGN_Center, MinSize=4, bFieldsHTML=true ))
	Columns.Add(( Name="SCORE", Align=ALIGN_Center, MinSize=5, bFieldsHTML=true ))
	Columns.Add(( Name="DEATH", Align=ALIGN_Center, MinSize=3, bFieldsHTML=true ))
	Columns.Add(( Name="MXP",   Align=ALIGN_Right,  MinSize=5, bFieldsHTML=true ))
	Columns.Add(( Name="TIME",  Align=ALIGN_Right,  MinSize=5, bFieldsHTML=true ))
	Columns.Add(( Name="PING",  Align=ALIGN_Right,  MinSize=3, bFieldsHTML=true ))
}
