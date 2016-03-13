//================================================================
// Infekkted.LootOrb_Ammo
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class LootOrb_Ammo extends LootOrb;

var float AmmoPct;

// Init values from config
function SetParameters(eOrbColor Col, String Value, String Extras)
{
	Super.SetParameters(Col, Value, Extras);

	AmmoPct = float(Value);
}

// Give orb to player
function GiveTo(Pawn P)
{
	local Inventory Inv;
	local CRZWeapon W;

	if ( P.InvManager != None )
	{
		for ( Inv=P.InvManager.InventoryChain; Inv!=None; Inv=Inv.Inventory )
		{
			W = CRZWeapon(Inv);
			if ( W != None && !W.AmmoMaxed(0) )
				W.AddAmmo(AmmoPct*W.MaxAmmoCount);
		}

		//TODO: message (client!!!)
	}

	Super.GiveTo(P);
}

defaultproperties
{
	PickupSound=SoundCue'Snd_Pickups.Ammo.SoundCues.A_Pickup_Ammo_Respawn_Cue'
}

