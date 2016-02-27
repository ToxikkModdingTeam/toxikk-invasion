class PathIndicator extends Actor;

defaultproperties
{
	Begin Object Class=ParticleSystemComponent Name=MouthFire
		Template=ParticleSystem'Doom3Monsters.Imp.Particles.imp_fireball_particles'
		bAutoActivate=true
		Rotation=(Yaw=16384)
		Scale=2.0
		End Object
	Components.Add(MouthFire);
}