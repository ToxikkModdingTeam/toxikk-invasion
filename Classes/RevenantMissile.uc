class RevenantMissile extends MonsterProjectile;

simulated function PostBeginPlay()
{
	// Force ambient sound if not vehicle game mode
	bImportantAmbientSound = !WorldInfo.bDropDetail;
	Super.PostBeginPlay();
}

defaultproperties
{
	ProjWaterFlightTemplate=ParticleSystem'RocketLauncher.Effects.P_WP_RocketLauncher_RocketWaterTrail'
	WaterSplashSound=SoundCue'Snd_RocketLauncher.SoundCues.A_Weapon_RocketLauncher_Impact_WaterCue'
	bWaitForEffects=True
	bAttachExplosionToVehicles=False
	AmbientSound=SoundCue'Snd_RocketLauncher.SoundCues.A_Weapon_RocketLauncher_TravelCue'
	ExplosionSound=SoundCue'Snd_RocketLauncher.SoundCues.A_Weapon_RocketLauncher_ImpactCue'
	ProjExplosionTemplate=ParticleSystem'RocketLauncher.Effects.P_WP_RocketLauncher_RocketExplosion'
	ExplosionDecal=MaterialInstanceTimeVarying'RocketLauncher.Decals.MITV_WP_RocketLauncher_Impact_Decal'
	DecalWidth=128.000000
	DecalHeight=128.000000
	ProjectileLightClass=Class'CRZRocketLight'
	ExplosionLightClass=Class'CRZRocketLauncherMuzzleFlashLight'
	bCheckProjectileLight=True
	CheckRadius=42.000000

	MaxSpeed=1600
	AccelRate=2200

	Damage=70
	DamageRadius=200
	MomentumTransfer=2000
	MyDamageType=Class'IFDmgType_MonsterMissile'

	ProjFlightTemplate=ParticleSystem'Doom3Monsters.Revenant.rev_rocket_particles'

	// Missile variables
	ProjScale=2.5
	ProjRotation=(Yaw=32768)
}
