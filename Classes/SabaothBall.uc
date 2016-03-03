class SabaothBall extends HellknightBall;

defaultproperties
{
	ProjectileLightClass=Class'ImpLight'
	ExplosionLightClass=Class'ImpLightBoom'
	
	ProjFlightTemplate=ParticleSystem'Doom3Monsters.Sabaoth.Particles.bfg_ball_particles'
	ProjExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_Impact'
	ProjExplosionTemplateOnPawn=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_PawnImpact'
	
	Speed=200.000000
	MaxSpeed=450.000000
	Damage=15.000000
	
	ProjScale=1.5

	MyDamageType=Class'IFDmgType_HellknightBall'
}