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

var PlayerReplicationInfo InitialOwner;

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
		InitialOwner, RepData;
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

auto state Pickup
{
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

Begin:
	CheckTouching();
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
	// no sprite
	Components.Remove(Sprite);

	// yes particle fx
	Begin Object Class=ParticleSystemComponent Name=PS
		Template=ParticleSystem'InfekktedResources.FX.PS_Orb1'
		AlwaysLoadOnServer=false
	End Object
	Components.Add(PS)
	PSComp=PS

	MaxDesireability=0.0

	bDestroyedByInterpActor=false
	RotationRate=()
	bIgnoreEncroachers=true
}
