//================================================================
// Infekkted.LootOrb
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class LootOrb extends UTDroppedItemPickup
	abstract;

var ParticleSystemComponent PSComp;
var editconst Vector PSBaseTranslation;
var editconst Vector PSBobMax;
var Vector PSBobCounter;
var float PSEndBobCounter;

var Pawn InitialOwner;

var editconst float TravelDistCheck;

var bool bLandedOnce;
var float WaitForOwnerTime;

var Pawn TravelTarget;
var editconst float TravelSpeed;
var editconst float TravelAccel;
var editconst float TravelFriction;
var float ActualTravelSpeed;
var Vector OldVelocity;

struct sOrbRepData
{
	var eOrbColor Color;
	var String Value;
	var String Extras;
};
var sOrbRepData RepData;

Replication
{
	if ( bNetInitial )
		RepData;
	if ( bNetInitial || bNetDirty )
		TravelTarget;
}

// PickupMesh comes from InventoryClass definition - maybe we'll use it for weapon orbs
simulated event SetPickupMesh(PrimitiveComponent NewPickupMesh)
{}
// PickupParticles comes from InventoryClass definition
simulated event SetPickupParticles(ParticleSystemComponent NewPickupParticles)
{}

// Init values from config
function SetParameters(eOrbColor Col, String Value, String Extras)
{
	RepData.Color = Col;
	RepData.Value = Value;
	RepData.Extras = Extras;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( PSComp != None )
		PSComp.SetTranslation(PSBaseTranslation);

	if ( WorldInfo.NetMode != NM_DedicatedServer )
		SetTimer(0.01, false, 'ReceivedParameters');
}

// Client
simulated function ReceivedParameters()
{
	SetColor(RepData.Color);
}

simulated function SetColor(eOrbColor Col)
{
	Switch (Col)
	{
		case ORB_Red:
			PSComp.SetColorParameter('Color1', MakeColor(255,64,64,255));
			PSComp.SetColorParameter('Color2', MakeColor(255,0,0,255));
			break;

		case ORB_Yellow:
			PSComp.SetColorParameter('Color1', MakeColor(255,255,96,160));
			PSComp.SetColorParameter('Color2', MakeColor(255,255,0,160));
			break;

		case ORB_Green:
			PSComp.SetColorParameter('Color1', MakeColor(64,255,64,255));
			PSComp.SetColorParameter('Color2', MakeColor(0,255,0,255));
			break;

		case ORB_Orange:
			PSComp.SetColorParameter('Color1', MakeColor(255,96,32,255));
			PSComp.SetColorParameter('Color2', MakeColor(255,64,0,255));
			break;

		case ORB_Purple:
			PSComp.SetColorParameter('Color1', MakeColor(160,64,255,255));
			PSComp.SetColorParameter('Color2', MakeColor(160,0,255,255));
			break;
	}
}

auto simulated state Pickup
{
	event BeginState(Name PrevStateName)
	{
		SetPhysics(PHYS_Falling);
		Acceleration = Vect(0,0,5);
		bCollideWorld = true;
		PSBobCounter = Vect(0,0,0);
		PSEndBobCounter = 0;
		ActualTravelSpeed = TravelSpeed;
	}

	function bool ValidTouch(Pawn Other)
	{
		// make sure its a live player
		if ( Other == None || !Other.bCanPickupInventory || (Other.DrivenVehicle == None && Other.Controller == None) || Other.Health <= 0 )
			return false;

		// we skip the "own weapon" check
		// we skip the "through wall" check because our orbs are going to travel through walls

		// ask confirmation from the gamemode
		return WorldInfo.Game.PickupQuery(Other, Inventory.class, self);
	}

	simulated event Landed(vector HitNormal, Actor FloorActor)
	{
		bLandedOnce = true;
	}

	simulated event Tick(float dt)
	{
		local Vector V, Dir;

		if ( dt < 0 )
			return;

		// Traveling
		if ( TravelTarget != None )
		{
			// end the bobbing smoothly
			PSEndBobCounter = Min(PSEndBobCounter + dt/2.0, 1.0);

			if ( bCollideWorld )
				bCollideWorld = false;

			if ( Physics != PHYS_Falling )
				SetPhysics(PHYS_Falling);

			if ( Role == ROLE_Authority )
			{
				if ( OldVelocity == Vect(0,0,0) )
					OldVelocity = Velocity;

				ActualTravelSpeed += TravelAccel*dt;
				Dir = Normal(TravelTarget.Location - Location);
				Velocity = OldVelocity + (ActualTravelSpeed*dt)*Dir - (TravelFriction*dt)*VSize(OldVelocity)*OldVelocity;

				OldVelocity = Velocity;
			}
		}

		// Bobbing
		if ( bLandedOnce )
		{
			PSBobCounter.Z += dt;
			V = PSBaseTranslation;
			V.Z += Sin(PSBobCounter.Z * Pi) * PSBobMax.Z * Cos(PSEndBobCounter * Pi / 2);
			PSComp.SetTranslation(V);
		}
	}

Begin:
	if ( Role == ROLE_Authority )
	{
		CheckTouching();

		Sleep(0.1);

		if ( InitialOwner != None )
		{
			if ( ShouldTravelTo(InitialOwner) )
				TravelTarget = InitialOwner;
			else
			{
				while ( !bLandedOnce )
				{
					if ( ShouldTravelTo(InitialOwner) )
					{
						TravelTarget = InitialOwner;
						break;
					}
					Sleep(0.1);
				}
				if ( TravelTarget == None )
				{
					SetTimer(WaitForOwnerTime, false, 'WaitForOwner');
					while ( IsTimerActive('WaitForOwner') )
					{
						if ( ShouldTravelTo(InitialOwner) )
						{
							TravelTarget = InitialOwner;
							break;
						}
						Sleep(0.1);
					}
				}
			}
		}

		while ( TravelTarget == None )
		{
			TravelTarget = FindTravelTarget();
			if ( TravelTarget != None )
				break;
			Sleep(0.1);
		}

		while ( TravelTarget != None && TravelTarget.Health > 0 )
			Sleep(0.1);

		TravelTarget = None;
		GotoState('Pickup');
	}
}

function WaitForOwner() {}

function bool ShouldTravelTo(Pawn P)
{
	return VSize(P.Location - Location) <= TravelDistCheck;
}

function Pawn FindTravelTarget()
{
	local CRZPawn P, Best;
	local float Dist, BestDist;

	foreach WorldInfo.AllPawns(class'CRZPawn', P)
	{
		if ( P.Health > 0 )
		{
			Dist = VSize(P.Location - Location);
			if ( Best == None || Dist < BestDist )
			{
				BestDist = Dist;
				Best = P;
			}
		}
	}
	return (BestDist <= TravelDistCheck) ? Best : None;
}

// Give orb to player
function GiveTo(Pawn P)
{
	PlaySound(PickupSound);
	Destroy();
}

// Ignore encroach
event EncroachedBy(Actor Other)
{}

defaultproperties
{
	TravelDistCheck=800
	TravelSpeed=1000
	TravelAccel=10000
	TravelFriction=0.02
	WaitForOwnerTime=3.0

	Begin Object Name=CollisionCylinder
		CollisionHeight=32.000000
	End Object

	// no sprite
	Components.Remove(Sprite);

	// yes particle fx
	Begin Object Class=ParticleSystemComponent Name=PS
		Template=ParticleSystem'InfekktedResources.FX.PS_Orb1'
		AlwaysLoadOnServer=false
	End Object
	Components.Add(PS)
	PSComp=PS
	PSBaseTranslation=(X=0,Y=0,Z=+16)
	PSBobMax=(X=0,Y=0,Z=6)

	MaxDesireability=0.0

	bDestroyedByInterpActor=false
	RotationRate=()
	bIgnoreEncroachers=true
}
