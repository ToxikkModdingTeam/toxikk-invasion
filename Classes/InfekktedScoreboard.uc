//================================================================
// Infekkted.InfekktedScoreboard
// ----------------
// - Replace kills with score (damage-based)
// - Remove BXP
// - Add status (alive / dead)
// ----------------
// by Chatouille
//================================================================
class InfekktedScoreboard extends ModularScoreboard;


/** Update row for player */
function UpdateRow(out array<sb_Row> Rows, byte RowIdx, CRZPlayerReplicationInfo PRI)
{
	if ( PRI == None )
		return;

	if ( PRI.IsLocalPlayerPRI() )
		Rows[RowIdx].Background.SetVisible(true);
	else
		Rows[RowIdx].Background.SetVisible(false);

	UpdateField(Rows,RowIdx, "POS", PRI.bOnlySpectator ? "SPC" : class'CRZHud'.static.FormatInteger(PRI.ScoreboardRank,2) );

	UpdateField(Rows,RowIdx, "ID", Left(PRI.PlayerName,9));

	UpdateField(Rows,RowIdx, "FROM", PRI.bBot ? "---" : Caps(Left(PRI.CountryCode,3)) );

	UpdateField(Rows,RowIdx, "CLAN", PRI.ClanTag == "" ? "---" : Caps(Left(PRI.ClanTag,3)) );

	UpdateField(Rows,RowIdx, "LVL", class'CRZHud'.static.FormatInteger(int(PRI.SkillClass), 2));

	UpdateField(Rows,RowIdx, "STATUS", PRI.bOnlySpectator ? "SPEC" : (PRI.bOutOfLives ? class'CRZHud'.static.FormatHTMLHexColor("DEAD",class'CRZHud'.default.UIRedHtmlHexColor) : class'CRZHud'.static.FormatHTMLHexColor("OK",class'CRZHud'.default.UIGreenHtmlHexColor)) );

	UpdateField(Rows,RowIdx, "SCORE", class'CRZHud'.static.FormatHTMLHexColor( PRI.bOnlySpectator ? "---" : class'CRZHud'.static.FormatInteger(int(PRI.Score)) , class'CRZHud'.default.UIWhiteHtmlHexColor));

	UpdateField(Rows,RowIdx, "DEATH", PRI.bOnlySpectator ? "---" : class'CRZHud'.static.FormatInteger(PRI.Deaths));

	UpdateField(Rows,RowIdx, "MXP", PRI.bOnlySpectator ? "---" : class'CRZHud'.static.FormatInteger(PRI.LXP+PRI.MXP));

	UpdateField(Rows,RowIdx, "TIME", class'CRZHud'.static.FormatTime(FMax(0,CRZGameReplicationInfo(PRI.WorldInfo.GRI).GetElapsedTime() - PRI.StartTime)) );

	UpdateField(Rows,RowIdx, "PING", class'CRZHud'.static.FormatPingHexColor(PRI.GetPing()*1000, true));
}


defaultproperties
{
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
