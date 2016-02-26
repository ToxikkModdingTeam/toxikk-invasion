class ImpBall extends HellknightBall;

defaultproperties
{
	ProjectileLightClass=Class'ImpLight'
	ExplosionLightClass=Class'ImpLightBoom'
	
	ProjFlightTemplate=ParticleSystem'Doom3Monsters.Imp.Particles.imp_fireball_particles'
	ProjExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_Impact'
	ProjExplosionTemplateOnPawn=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_PawnImpact'
	
	Speed=1000.000000
	MaxSpeed=1500.000000
	Damage=15.000000
	
	ProjScale=1.5

	MyDamageType=Class'DmgType_HellknightBall'
}