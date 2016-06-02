class RevenantMissile extends MonsterProjectile;

simulated function PostBeginPlay()
{
	// Force ambient sound if not vehicle game mode
	bImportantAmbientSound = !WorldInfo.bDropDetail;
	Super.PostBeginPlay();
}

defaultproperties
{
	ProjectileLightClass=Class'CRZRocketLight'
	ExplosionLightClass=Class'CRZRocketLauncherMuzzleFlashLight'

	ProjFlightTemplate=ParticleSystem'Doom3Monsters.Revenant.rev_rocket_particles'
	ProjWaterFlightTemplate=ParticleSystem'RocketLauncher.Effects.P_WP_RocketLauncher_RocketWaterTrail'

	ProjExplosionTemplate=ParticleSystem'RocketLauncher.Effects.P_WP_RocketLauncher_RocketExplosion'
	ExplosionDecal=MaterialInstanceTimeVarying'RocketLauncher.Decals.MITV_WP_RocketLauncher_Impact_Decal'

	AmbientSound=SoundCue'Snd_RocketLauncher.SoundCues.A_Weapon_RocketLauncher_TravelCue'
	ExplosionSound=SoundCue'Snd_RocketLauncher.SoundCues.A_Weapon_RocketLauncher_ImpactCue'
	WaterSplashSound=SoundCue'Snd_RocketLauncher.SoundCues.A_Weapon_RocketLauncher_Impact_WaterCue'

	bWaitForEffects=True
	bAttachExplosionToVehicles=False

	DecalWidth=128.000000
	DecalHeight=128.000000

	bCheckProjectileLight=True
	CheckRadius=42.000000

	MaxSpeed=1600
	AccelRate=2200

	Damage=70
	DamageRadius=200
	MomentumTransfer=2000
	MyDamageType=Class'IFDmgType_MonsterMissile'

	// Missile variables
	ProjScale=2.5
	ProjRotation=(Yaw=32768)
}
