class InvulBall extends HellknightBall;

defaultproperties
{
	ProjectileLightClass=Class'HellknightLight'
	ExplosionLightClass=Class'HellknightLightBoom'

	ProjFlightTemplate=ParticleSystem'Doom3Monsters.InvulHunter.invul_ball'
	ProjExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_Impact'

	ExplosionSound=SoundCue'Doom3Monsters.HellKnight.VP.hk_fireexplode_cue'
	ProjExplosionTemplateOnPawn=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_PawnImpact'

	Damage=45
	MomentumTransfer=30000
	MyDamageType=Class'IFDmgType_HellknightBall'

	ProjScale=3.0
}
