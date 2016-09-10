class SabaothBall extends HellknightBall;

defaultproperties
{
	ProjectileLightClass=Class'ImpLight'
	ExplosionLightClass=Class'ImpLightBoom'
	
	ProjFlightTemplate=ParticleSystem'Doom3Monsters.Sabaoth.Particles.bfg_ball_particles'
	ProjExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_Impact'
	ProjExplosionTemplateOnPawn=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_PawnImpact'

	Damage=40
	MyDamageType=Class'IFDmgType_HellknightBall'

	ProjScale=1.5
}
