class CDoomFakeSprite extends Actor;

var()			StaticMeshComponent					FakeMesh;
var()			Pawn								CameraPawn;
var()			Float								MeshScale;

var()			int									CurrentFrame;
var() 			PlayerController 					PC;

var()			MaterialInstanceConstant			TDMIC;
var()			Material							TDMat;
var()			bool								bFullbright;

var()			int									FrameAddition;
var()			int									FrameID;
var()			CDoomMonster						OwningPawn;
var()			float								YawAddition;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
		PC = GetALocalPlayerController();
		
	// Create the MIC
	if (TDMIC == None)
		TDMIC = FakeMesh.CreateAndSetMaterialInstanceConstant(0);
}

Static final function byte GetRotation( int MonYaw, int ViewYaw )
{
	local int YawErr;
	
	YawErr = ((MonYaw & 65535) - (ViewYaw & 65535)) & 65535; // Get the yaw error.
	if( YawErr<3456 )
		Return 0;
	if( YawErr<11672 )
		Return 1;
	if( YawErr<19822 )
		Return 2;
	if( YawErr<27700 )
		Return 3;
	if( YawErr<36930 )
		Return 4;
	if( YawErr<44740 )
		Return 5;
	if( YawErr<53350 )
		Return 6;
	if( YawErr<60550 )
		Return 7;
	Return 0;
}

simulated function Tick(float Delta)
{
	local Vector V;
	local Rotator R, FaceRot;
	local int NewFrame;
	local vector DS;
	
	NewFrame=0;
	
	super.Tick(Delta);
	
	if (PC != None)
	{
		PC.GetPlayerViewPoint(V,R);

		FaceRot = Rotator(V - Location);
		FaceRot.Pitch=0;
		FaceRot.Roll=0;
		SetRotation(FaceRot);
	}
	

	NewFrame = GetRotation(OwningPawn.Rotation.Yaw + YawAddition, R.Yaw);

	FakeMesh.SetScale(MeshScale);
	
	CurrentFrame = NewFrame;
	
	if (TDMIC != None && bFullBright)
		TDMIC.SetScalarParameterValue('FullBright',1.0);
		
	TDMIC.SetTextureParameterValue('Sprite',OwningPawn.MonsterFrames[OwningPawn.CurrentFrame].Frames[CurrentFrame]);
		
	
	DS.Y=1.0;
	DS.Z=1.0;
		
	if (OwningPawn.MonsterFrames[OwningPawn.CurrentFrame].FrameFlip[CurrentFrame])
		DS.X = -1.0;
	else
		DS.X = 1.0;
		
	FakeMesh.SetScale3D(DS);
}

defaultproperties
{
   Physics=PHYS_None
   MeshScale=2.6
   bHardAttach=true
   
   CurrentFrame=-1
   
   YawAddition=32768
   
   // 2DMat=Material'ClassicDoomWeps.2dsprite_mat'
   
   Begin Object Name=StaticMeshComponent0 Class=StaticMeshComponent
        StaticMesh=StaticMesh'CDoomMonsters.cdoom_faker'
        bNotifyRigidBodyCollision=False
		BlockRigidBody=False        
        BlockNonZeroExtent=False
		BlockZeroExtent=False
		BlockActors=False
		CollideActors=False
		AlwaysCheckCollision=False
		Scale=1.0
		Rotation=(Yaw=-16384)
		Translation=(Z=17.0)
		RBCollideWithChannels=(Default=False,BlockingVolume=False,GameplayPhysics=False,EffectPhysics=False,Pawn=False)
    End Object
	FakeMesh=StaticMeshComponent0
	Components.Add(StaticMeshcomponent0)
}
