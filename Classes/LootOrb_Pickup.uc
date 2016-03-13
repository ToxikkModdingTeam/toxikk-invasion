//================================================================
// Infekkted.LootOrb_Pickup
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class LootOrb_Pickup extends LootOrb;

// Init values from config
function SetParameters(eOrbColor Col, String Value, String Extras)
{
	Super.SetParameters(Col, Value, Extras);

	InventoryClass = class<Inventory>(DynamicLoadObject(Value, class'Class', true));
	if ( InventoryClass == None )
	{
		`Log("[Infekkted] Failed to load class '" $ Value $ "' for LootOrb_Pickup - destroying");
		Destroy();
	}
}

// Give orb to player
function GiveTo(Pawn P)
{
	local Inventory Inv;

	Inv = P.FindInventoryType(InventoryClass, false);
	if ( Inv == None )
	{
		Inv = Spawn(InventoryClass, P);
		if ( UTTimedPowerup(Inv) != None )
		{
			UTTimedPowerup(Inv).TimeRemaining = class'GameInfo'.static.GetIntOption(RepData.Extras, "duration", UTTimedPowerup(Inv).TimeRemaining);
		}
		Inv.GiveTo(P);
	}
	else if ( UTTimedPowerup(Inv) != None )
	{
		UTTimedPowerup(Inv).TimeRemaining += class'GameInfo'.static.GetIntOption(RepData.Extras, "duration", UTTimedPowerup(Inv).TimeRemaining);
	}
	else if ( UTWeapon(Inv) != None )
	{
		Weapon(Inv).AddAmmo(UTWeapon(Inv).default.AmmoCount);
	}

	Inv.AnnouncePickup(P);

	PickupSound = Inv.PickupSound;
	Super.GiveTo(P);
}

defaultproperties
{
}
