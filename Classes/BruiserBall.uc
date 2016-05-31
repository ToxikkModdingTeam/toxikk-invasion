//================================================================
// Infekkted.BruiserBall
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class BruiserBall extends MonsterProjectile;

defaultproperties
{
	ProjFlightTemplate=ParticleSystem'Laser_Beams.Effects.P_Laser_Beam'

	ProjectileLightClass=class'Cruzade.CRZScionLaserProjectileLight'
	ExplosionLightClass=class'Cruzade.CRZScionRifleMuzzleFlashLight'

	ProjExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_Impact'
	ProjExplosionTemplateOnPawn=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_PawnImpact'
	ProjWaterExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_UnderWaterImpact'

	ExplosionSound=SoundCue'Snd_ScionRifle.SoundCues.A_Weapon_ScionRifle_ImpactCue'
	WaterSplashSound = SoundCue'Snd_ScionRifle.SoundCues.A_Weapon_ScionRifle_Impact_WaterCue'

	Speed=1000
	MaxSpeed=2500
	AccelRate=3000

	Damage=30
	MomentumTransfer=0
	MyDamageType=Class'IFDmgType_Monster'

	ProjScale=1.0
}
