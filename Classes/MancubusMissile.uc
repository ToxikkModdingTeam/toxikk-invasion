//================================================================
// Infekkted.MancubusMissile
// ----------------
// ...
// ----------------
// by Chatouille
//================================================================
class MancubusMissile extends HellknightBall;

defaultproperties
{
	ProjectileLightClass=Class'ImpLight'
	ExplosionLightClass=Class'ImpLightBoom'
	
	ProjFlightTemplate=ParticleSystem'Doom3Monsters.Mancubus.Particles.manc_fireball_particles'
	ProjExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_Impact'
	ProjExplosionTemplateOnPawn=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_PawnImpact'

	Damage=45.000000

	ProjScale=1.5

	MyDamageType=Class'IFDmgType_MancubusBall'
}
