class InvulBall extends HellknightBall;

defaultproperties
{
	ProjectileLightClass=Class'HellknightLight'
	ExplosionLightClass=Class'HellknightLightBoom'
	
	ProjFlightTemplate=ParticleSystem'Doom3Monsters.InvulHunter.invul_ball'
	ProjExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_Impact'
	
	ExplosionSound=SoundCue'Doom3Monsters.HellKnight.VP.hk_fireexplode_cue'
	ProjExplosionTemplateOnPawn=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_PawnImpact'
	
	Speed=2000.000000
	MaxSpeed=3000.000000
	Damage=35.000000
		
	Physics=PHYS_Falling
	MomentumTransfer=30000.000000
	bRotationFollowsVelocity=True
	AccelRate=3000.000000
	
	MyDamageType=Class'IFDmgType_HellknightBall'
	
	ProjScale=3.0
}