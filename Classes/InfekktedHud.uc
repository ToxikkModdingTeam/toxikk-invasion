//================================================================
// package.InfekktedHud
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class InfekktedHud extends CRZHud
	Config(Infekkted);

enum TextAlignType
{
	ALIGN_Left,
	ALIGN_Center,
	ALIGN_Right,
	ALIGN_Top,
	ALIGN_Bottom,
};

// Distance to draw the shadow from the text
var int ShadowDistance;

//========================================================
//-- Radar -----------------------------------------------

var config			bool			bCustomRadarColors;
var config			Color			CustomRadarBG, CustomRadarFG, CustomRadarScan;		

// Refs
var config			String			RadarTexFG, RadarTexBG, RadarTexScan;
// Real textures
var Texture2D						RRadarTexFG, RRadarTexBG, RRadarTexScan;

var float RadarSize;

var Texture2D RadarBgTex;
var Color RadarBgColor;

var Texture2D RadarFgTex;
var Color RadarFgColor;

var Texture2D RadarScanTex;
var Color RadarScanColor;

var float RadarUpdateInterval;
var float RadarScanTime;
var float RadarItemDuration;

var Texture2D RadarFriendlyTex;
var Color RadarFriendlyColor;
var float RadarFriendlySize;

var Texture2D RadarMonsterTex;
var Color RadarMonsterColor;
var float RadarMonsterSize;

var Texture2D RadarBossTex;
var Color RadarBossColor;
var float RadarBossSize;

//internal
var float RadarMaxDistSqrt;

struct sRadarItem
{
	var Vector WorldLoc;
	var Texture2D Tex;
	var Color Col;
	var float Size;
	var bool bShowing;
	var float Alpha;

	structdefaultproperties
	{
		Alpha=1.0
	}
};
var array<sRadarItem> PrevRadarItems;
var array<sRadarItem> RadarItems;


//========================================================
//-- Monsters remaining ----------------------------------


//========================================================
//-- Boss ------------------------------------------------

var ToxikkMonster Boss;


simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	SetTimer(RadarUpdateInterval, true, 'UpdateRadar');
	LoadCustomResources();
}

// Load custom stuff from the config because why not
function LoadCustomResources()
{
	local Texture2D TB, TF, TS;
	
	// Foreground
	TF = Texture2D(DynamicLoadObject(RadarTexFG,class'Texture2D'));
	if (TF != None)
		RadarFgTex = TF;
		
	// Background
	TB = Texture2D(DynamicLoadObject(RadarTexBG,class'Texture2D'));
	if (TB != None)
		RadarBgTex = TB;
		
	// Scan
	TS = Texture2D(DynamicLoadObject(RadarTexScan,class'Texture2D'));
	if (TS != None)
		RadarScanTex = TS;
}

function UpdateHUD(float DeltaTime)
{
	super.UpdateHUD(DeltaTime);
	if (HudMovie != None)
	{
		HudMovie.PlayerStatsMC.SetVisible(false);
	}	
}

simulated function UpdateRadar()
{
	local Pawn P;
	local int i;

	PrevRadarItems = RadarItems;
	RadarItems.Length = 0;
	foreach WorldInfo.AllPawns(class'Pawn', P)
	{
		if ( P.IsInState('Dying') || P.Health <= 0 || P == PlayerOwner.Pawn )
			continue;

		i = RadarItems.Length;
		RadarItems.Add(1);

		RadarItems[i].WorldLoc = P.Location;

		if ( CRZPawn(P) != None )
		{
			RadarItems[i].Tex = RadarFriendlyTex;
			RadarItems[i].Col = RadarFriendlyColor;
			RadarItems[i].Size = RadarFriendlySize;
		}
		else if ( ToxikkMonster(P) != None && ToxikkMonster(P).bIsBossMonster )
		{
			RadarItems[i].Tex = RadarBossTex;
			RadarItems[i].Col = RadarBossColor;
			RadarItems[i].Size = RadarBossSize;
		}
		else
		{
			RadarItems[i].Tex = RadarMonsterTex;
			RadarItems[i].Col = RadarMonsterColor;
			RadarItems[i].Size = RadarMonsterSize;
		}
	}
	SetTimer(RadarScanTime, false, 'RadarScanTimer');
}

simulated function RadarScanTimer() {}

simulated event PostRender()
{
	Super.PostRender();

	if ( RadarMaxDistSqrt > 0 )
		DrawRadar();
	else if ( InfekktedGRI(WorldInfo.GRI) != None && InfekktedGRI(WorldInfo.GRI).AvgMapSize > 0 )
		RadarMaxDistSqrt = Sqrt( InfekktedGRI(WorldInfo.GRI).AvgMapSize );

	// the GRI will start replicating RemainingMonsters once once we reach the post-spawn phase
	if ( InfekktedGRI(WorldInfo.GRI) != None && InfekktedGRI(WorldInfo.GRI).RemainingMonsters >= 0 )
		DrawRemainingMonsters( InfekktedGRI(WorldInfo.GRI).RemainingMonsters );

	// When boss is created on client-side, it sets itself automatically in var Boss
	if ( Boss != None )
		DrawBoss();
}

simulated function DrawRadar()
{
	local float RadarPosX, RadarPosY;
	local float ScanPct, ScanSize;
	local Vector MyLoc, V;
	local Rotator MyRot;
	local int i;
	local float DistSqrt, DistOnRadar, Angle;
	Local Color CFG, CBG, CSC, CD;

	if ( CurrentHudMode != HM_Game && CurrentHudMode != HM_Spectating )
		return;
		
	if (bCustomRadarColors)
	{
		CFG = CustomRadarFG;
		CBG = CustomRadarBG;
		CSC = CustomRadarScan;
	}
	else
	{
		CFG = RadarFgColor;
		CBG = RadarBgColor;
		CSC = RadarScanColor;
	}

	RadarPosX = Canvas.ClipX - 1.1*RadarSize;
	RadarPosY = Canvas.ClipY * 0.2;

	Canvas.DrawColor = CBG;
	Canvas.SetPos(RadarPosX, RadarPosY);
	Canvas.DrawTile(RadarBgTex, RadarSize, RadarSize, 0, 0, RadarBgTex.SizeX, RadarBgTex.SizeY);
	Canvas.DrawColor = CFG;
	Canvas.SetPos(RadarPosX, RadarPosY);
	Canvas.DrawTile(RadarFgTex, RadarSize, RadarSize, 0, 0, RadarFgTex.SizeX, RadarFgTex.SizeY);

	ScanPct = 1.0 - (FMax(GetRemainingTimeForTimer('RadarScanTimer'),0.0) / RadarScanTime);
	if ( ScanPct < 1.0 )
	{
		ScanPct = Sin(ScanPct*Pi/2);
		ScanSize = ScanPct * (RadarSize+16);
		Canvas.SetPos(RadarPosX + (RadarSize-ScanSize)/2, RadarPosY + (RadarSize-ScanSize)/2);
		Canvas.SetDrawColor(CSC.R, CSC.G, CSC.B, byte((1.0-ScanPct)*CSC.A));
		Canvas.DrawTile(RadarScanTex, ScanSize, ScanSize, 0, 0, RadarScanTex.SizeX, RadarScanTex.SizeY);
	}

	PlayerOwner.GetPlayerViewPoint(MyLoc, MyRot);

	for ( i=0; i<PrevRadarItems.Length; i++ )
	{
		if ( PrevRadarItems[i].Alpha <= 0 )
			continue;

		V = PrevRadarItems[i].WorldLoc - MyLoc;
		DistSqrt = Sqrt( VSize2D(V) );
		if ( DistSqrt > RadarMaxDistSqrt )
			continue;

		DistOnRadar = (DistSqrt / RadarMaxDistSqrt) * RadarSize / 2;
		Angle = (Rotator(V).Yaw - MyRot.Yaw - 16384) * 2*Pi / 65536;

		Canvas.SetPos(RadarPosX + (RadarSize/2) + DistOnRadar*Cos(Angle) - (PrevRadarItems[i].Size/2), RadarPosY + (RadarSize/2) + DistOnRadar*Sin(Angle) - (PrevRadarItems[i].Size/2));
		Canvas.SetDrawColor(PrevRadarItems[i].Col.R, PrevRadarItems[i].Col.G, PrevRadarItems[i].Col.B, byte(PrevRadarItems[i].Alpha*PrevRadarItems[i].Col.A));
		Canvas.DrawTile(PrevRadarItems[i].Tex, PrevRadarItems[i].Size, PrevRadarItems[i].Size, 0, 0, PrevRadarItems[i].Tex.SizeX, PrevRadarItems[i].Tex.SizeY);

		PrevRadarItems[i].Alpha -= (RenderDelta / RadarItemDuration);
	}
	for ( i=0; i<RadarItems.Length; i++ )
	{
		if ( RadarItems[i].Alpha <= 0 )
			continue;

		V = RadarItems[i].WorldLoc - MyLoc;
		DistSqrt = Sqrt( VSize2D(V) );
		if ( DistSqrt > RadarMaxDistSqrt )
			continue;

		if ( RadarItems[i].bShowing )
		{
			DistOnRadar = (DistSqrt / RadarMaxDistSqrt) * RadarSize / 2;
			Angle = (Rotator(V).Yaw - MyRot.Yaw - 16384) * 2*Pi / 65536;

			Canvas.SetPos(RadarPosX + (RadarSize/2) + DistOnRadar*Cos(Angle) - (RadarItems[i].Size/2), RadarPosY + (RadarSize/2) + DistOnRadar*Sin(Angle) - (RadarItems[i].Size/2));
			Canvas.SetDrawColor(RadarItems[i].Col.R, RadarItems[i].Col.G, RadarItems[i].Col.B, byte(RadarItems[i].Alpha*RadarItems[i].Col.A));
			Canvas.DrawTile(RadarItems[i].Tex, RadarItems[i].Size, RadarItems[i].Size, 0, 0, RadarItems[i].Tex.SizeX, RadarItems[i].Tex.SizeY);

			RadarItems[i].Alpha -= (RenderDelta / RadarItemDuration);
		}
		else if ( DistSqrt <= ScanPct*RadarMaxDistSqrt )
			RadarItems[i].bShowing = true;
	}
}

simulated function DrawRemainingMonsters(int Count)
{
	DrawTextPlus(Canvas.ClipX - 16, Canvas.ClipY*0.2 - 16, ALIGN_Right, ALIGN_Bottom, "Remaining monsters: " $ Count, true, 255,255,255,class'CRZHud'.default.GlowFonts[0]);
}

simulated function DrawBoss()
{
	local int Health;
	local string BossString;
	local int R,G,B;

	R = 255;
	G = 255-byte(255.f*float(Max(Boss.Health,0))/float(Boss.HealthMax));
	B = 0;

	Health = Max(Boss.Health, 0);
	BossString = "Boss HP: " $ string(Health) $ "/" $ string(Boss.HealthMax);
	
	DrawTextPlus(Canvas.ClipX - 16, Canvas.ClipY/2, ALIGN_Right, ALIGN_Top, BossString, true, R, G, B, class'CRZHud'.default.GlowFonts[0]);
	
	DrawBossName();
}

simulated function DrawBossName()
{
	local float XL, YL;
	local string BossName;

	BossName = Boss.GetMonsterName();
	// BossName = "Sample Text";
	Canvas.TextSize("Boss HP:", XL, YL);
	
	DrawTextPlus(Canvas.ClipX - 16, (Canvas.ClipY/2) + YL + 4.0, ALIGN_Right, ALIGN_Top, BossName, true, 255, 255, 0, class'CRZHud'.default.GlowFonts[0]);
}

// -- DRAW TEXT AT A CERTAIN POSITION, THIS SAVES SOME TIME
function DrawTextPlus(float DrawX, float DrawY, TextAlignType HAlign, TextAlignType VAlign, string Text, bool bUseShadow, int R, int G, int B, Font FontToUse)
{
	local float XL, YL;
	local float FinalX, FinalY;
	
	Canvas.Font = FontToUse;
	Canvas.TextSize(Text,XL,YL);
	
	// Horizontal alignment
	switch (HAlign)
	{
		// Left, do nothing
		case ALIGN_Left:
			FinalX = DrawX;
		break;
		
		// Center
		case ALIGN_Center:
			FinalX = DrawX - (XL/2);
		break;
		
		// Right
		case ALIGN_Right:
			FinalX = DrawX - XL;
		break;
	}
	
	// Vertical alignment
	switch (VAlign)
	{
		// Left, do nothing
		case ALIGN_Top:
			FinalY = DrawY;
		break;
		
		// Center
		case ALIGN_Center:
			FinalY = DrawY - (YL/2);
		break;
		
		// Bottom
		case ALIGN_Bottom:
			FinalY = DrawY - YL;
		break;
		
		default:
			FinalY = DrawY;
		break;
	}
	
	if (bUseShadow)
	{
		Canvas.SetPos(FinalX+ShadowDistance,FinalY+ShadowDistance);
		Canvas.SetDrawColor(0,0,0);
		Canvas.DrawText(Text);
	}
	
	Canvas.SetDrawColor(R,G,B);
	Canvas.SetPos(FinalX,FinalY);
	Canvas.DrawText(Text);
}

defaultproperties
{
	RadarSize=300

	RadarBgTex=Texture2D'CRZGFx.HUD_I3E'
	RadarBgColor=(R=0,G=0,B=0,A=255)

	RadarFgTex=Texture2D'UDKHUD.ut3_minimap_compass'
	RadarFgColor=(R=255,G=255,B=255,A=255)

	RadarScanTex=Texture2D'CastleHUD.HUD_TouchToMove'   //Texture2D'fx_particles_01.flares.Textures.MF_T_FlareRing_01_D'
	RadarScanColor=(R=100,G=200,B=255,A=200)
	
	// CustomRadarBG=(R=0,G=0,B=0,A=255)
	// CustomRadarFG=(R=255,G=255,B=255,A=255)
	// CustomRadarScan=(R=100,G=200,B=255,A=200)

	RadarUpdateInterval=1.4
	RadarScanTime=1.2
	RadarItemDuration=1.0

	RadarFriendlyTex=Texture2D'CastleHUD.HUD_TouchToMove'
	RadarFriendlyColor=(R=0,G=255,B=0,A=255)
	RadarFriendlySize=32

	RadarMonsterTex=Texture2D'EngineVolumetrics.LightBeam.Materials.T_EV_LightBeam_Falloff_02'
	RadarMonsterColor=(R=255,G=255,B=0,A=255)
	RadarMonsterSize=24

	RadarBossTex=Texture2D'UDKHUD.skull'
	RadarBossColor=(R=255,G=0,B=0,A=255)
	RadarBossSize=40

	ScoreBoardClass=class'InfekktedScoreboard'
	
	ShadowDistance = 2
}
