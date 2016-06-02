class HellknightBall extends MonsterProjectile;

defaultproperties
{
	ProjectileLightClass=Class'HellknightLight'
	ExplosionLightClass=Class'HellknightLightBoom'
	
	ProjFlightTemplate=ParticleSystem'Doom3Monsters.HellKnight.hk_projectile_effect'

	ProjExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_Impact'
	ProjExplosionTemplateOnPawn=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_PawnImpact'
	ProjWaterExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_UnderWaterImpact'
	
	ExplosionSound=SoundCue'Doom3Monsters.HellKnight.VP.hk_fireexplode_cue'
	WaterSplashSound=SoundCue'Snd_ScionRifle.SoundCues.A_Weapon_ScionRifle_Impact_WaterCue'

	Damage=35
	MomentumTransfer=30000
	MyDamageType=Class'IFDmgType_HellknightBall'
	
	//TODO: use dropping projectiles only when we can handle the aiming correctly!
	//Physics=PHYS_Falling
	bRotationFollowsVelocity=True
}
