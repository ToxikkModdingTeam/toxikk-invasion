//================================================================
// Infekkted.InfekktedHud
// ----------------
// ...
// ----------------
// by Chatouille & ZedekThePD
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
	local Texture2D Tex;
	
	// Foreground
	Tex = Texture2D(DynamicLoadObject(RadarTexFG, class'Texture2D', true));
	if (Tex != None)
		RadarFgTex = Tex;
		
	// Background
	Tex = Texture2D(DynamicLoadObject(RadarTexBG, class'Texture2D', true));
	if (Tex != None)
		RadarBgTex = Tex;
		
	// Scan
	Tex = Texture2D(DynamicLoadObject(RadarTexScan, class'Texture2D', true));
	if (Tex != None)
		RadarScanTex = Tex;
}

function UpdateHUD(float dt)
{
	Super.UpdateHUD(dt);

	if ( HudMovie != None && HudMovie.PlayerStatsMC != None )
		HudMovie.PlayerStatsMC.SetVisible(false);
}

simulated function UpdateRadar()
{
	local Pawn P;
	local int i;

	for ( i=0; i<RadarItems.Length; i++ )
	{
		if ( !RadarItems[i].bShowing )
			RadarItems.Remove(i--,1);
	}

	foreach WorldInfo.AllPawns(class'Pawn', P)
	{
		if ( P.IsInState('Dying') || P.Health <= 0 || P == PlayerOwner.Pawn || Vehicle(P) != None )
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
	Local Color CFG, CBG, CSC;

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

	for ( i=0; i<RadarItems.Length; i++ )
	{
		if ( RadarItems[i].Alpha <= 0 )
		{
			RadarItems.Remove(i--,1);
			continue;
		}

		V = RadarItems[i].WorldLoc - MyLoc;
		DistSqrt = Sqrt(VSize2D(V));
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
	DrawTextPlus(Canvas, Canvas.ClipX - 16, Canvas.ClipY*0.2 - 16, ALIGN_Right, ALIGN_Bottom, "Remaining monsters: " $ Count, true, 255,255,255,class'CRZHud'.default.GlowFonts[0]);
}

simulated function DrawBoss()
{
	local float XL, YL;

	//TODO: full width top-centered health bar, below is temporary stuff

	// Draw boss HP
	DrawTextPlus(
		Canvas,
		Canvas.ClipX - 16,
		Canvas.ClipY/2,
		ALIGN_Right,
		ALIGN_Top,
		"Boss HP: " $ Max(Boss.Health,0) $ "/" $ string(Boss.HealthMax),
		true,
		255,
		255-byte(255.f*float(Max(Boss.Health,0))/float(Boss.HealthMax)),
		0,
		class'CRZHud'.default.GlowFonts[0]
	);

	// Draw boss name
	Canvas.TextSize("BosHP:01234/56789",XL,YL); //need line height
	DrawTextPlus(
		Canvas,
		Canvas.ClipX - 16,
		Canvas.ClipY/2 + YL + 4,
		ALIGN_Right,
		ALIGN_Top,
		Boss.GetMonsterName(),
		true,
		255,
		255,
		0,
		class'CRZHud'.default.GlowFonts[0]
	);
}


// -- DRAW TEXT AT A CERTAIN POSITION, THIS SAVES SOME LINES
static function DrawTextPlus(Canvas CNV, float DrawX, float DrawY, TextAlignType HAlign, TextAlignType VAlign, string Text, bool bUseShadow, int R, int G, int B, Font FontToUse)
{
	local float XL, YL;
	local float FinalX, FinalY;
	
	CNV.Font = FontToUse;
	CNV.TextSize(Text,XL,YL);

	switch (HAlign)
	{
		case ALIGN_Left:    FinalX = DrawX;             break;
		case ALIGN_Center:  FinalX = DrawX - (XL/2);    break;
		case ALIGN_Right:   FinalX = DrawX - XL;        break;
	}

	switch (VAlign)
	{
		case ALIGN_Top:     FinalY = DrawY;             break;
		case ALIGN_Center:  FinalY = DrawY - (YL/2);    break;
		case ALIGN_Bottom:  FinalY = DrawY - YL;        break;
	}

	if (bUseShadow)
	{
		CNV.SetPos(FinalX+default.ShadowDistance,FinalY+default.ShadowDistance);
		CNV.SetDrawColor(0,0,0);
		CNV.DrawText(Text);
	}

	CNV.SetDrawColor(R,G,B);
	CNV.SetPos(FinalX,FinalY);
	CNV.DrawText(Text);
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
