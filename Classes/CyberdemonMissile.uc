class CyberdemonMissile extends DoomProjectile;

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
	ProjectileLightClass=Class'Cruzade.CRZRocketLight'
	ExplosionLightClass=Class'Cruzade.CRZRocketLauncherMuzzleFlashLight'
	bCheckProjectileLight=True
	CheckRadius=42.000000
	Speed=1800.000000
	MaxSpeed=2700.000000
	DamageRadius=220.000000
	MyDamageType=Class'Cruzade.CRZDmgType_RocketLauncher'
	Begin Object Name=CollisionCylinder Archetype=CylinderComponent'Cruzade.Default__CRZProjectile:CollisionCylinder'
		CollisionHeight=0.000000
		CollisionRadius=0.000000
		ReplacementPrimitive=None
		Name="CollisionCylinder"
	End Object
	CylinderComponent=CollisionCylinder
	Components(0)=CollisionCylinder
	LifeSpan=6.000000
	CollisionComponent=CollisionCylinder
   
	Damage=100.000000
	MomentumTransfer=2000.000000
	BaseTrackingStrength=1.000000
	HomingTrackingStrength=16.000000
	ProjFlightTemplate=ParticleSystem'Doom3Monsters.Revenant.rev_rocket_particles'
   
	// Missile variables
	ProjScale=3.25
	ProjRotation=(Yaw=32768)
}
