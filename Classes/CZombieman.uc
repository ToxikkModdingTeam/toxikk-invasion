//--DOOM ZOMBIEMAN
//------------------------------------------------------------------
Class CZombieman extends CDoomMonster;

DefaultProperties
{
	bHasMelee=false
	bHasRanged=true
	bHitscanMonster=true
	
	BulletCount=1
	
	// In angle units
	ShotSpread=500
	ShotRange=30000
	
	ShotHeight=32
	
	TracingClass=ParticleSystem'Pistol.Effects.P_WP_Pistol_BulletStreak'
	FireSound=SoundCue'CDoomMonsters.Zombieman.zombieman_fire_cue'
	IdleSound=SoundCue'CDoomMonsters.Zombieman.zombieman_idle_cue'
	ChatterSound=SoundCue'CDoomMonsters.Zombieman.zombieman_idle_cue'
	PainSound=SoundCue'CDoomMonsters.Zombieman.zombieman_pain_cue'
	SightSound=SoundCue'CDoomMonsters.Zombieman.zombieman_sight_cue'
	DeathSound=SoundCue'CDoomMonsters.Zombieman.zombieman_die_cue'
	
	ShotDamage=10
	
	AttackDistance=100
	RangedAttackDistance=2500
	
	// Idle frames
	MonsterFrames(0)=(Prefix="CDoomMonsters.Zombieman.POSSA",bHasSixEight=false,Type="idle",bBright=false,Duration=0.1)
	// Fire frames
	MonsterFrames(1)=(Prefix="CDoomMonsters.Zombieman.POSSE",bHasSixEight=false,Type="fire",bBright=false,Duration=0.333)
	MonsterFrames(2)=(Prefix="CDoomMonsters.Zombieman.POSSF",bHasSixEight=false,Type="fire",bBright=true,Duration=0.2666,ForceEvent="FIRE")
	MonsterFrames(3)=(Prefix="CDoomMonsters.Zombieman.POSSE",bHasSixEight=false,Type="fire",bBright=false,Duration=0.2666)
	// Pain frames
	MonsterFrames(4)=(Prefix="CDoomMonsters.Zombieman.POSSG",bHasSixEight=false,Type="pain",bBright=false,Duration=0.2)
	// Death frames
	MonsterFrames(5)=(Prefix="CDoomMonsters.Zombieman.POSSH",bHasSixEight=false,Type="death",bBright=false,Duration=0.1,bCardboard=true)
	MonsterFrames(6)=(Prefix="CDoomMonsters.Zombieman.POSSI",bHasSixEight=false,Type="death",bBright=false,Duration=0.1,bCardboard=true)
	MonsterFrames(7)=(Prefix="CDoomMonsters.Zombieman.POSSJ",bHasSixEight=false,Type="death",bBright=false,Duration=0.1,bCardboard=true)
	MonsterFrames(8)=(Prefix="CDoomMonsters.Zombieman.POSSK",bHasSixEight=false,Type="death",bBright=false,Duration=0.1,bCardboard=true)
	MonsterFrames(9)=(Prefix="CDoomMonsters.Zombieman.POSSL",bHasSixEight=false,Type="death",bBright=false,Duration=0.1,bCardboard=true)
	// Walk frames
	MonsterFrames(10)=(Prefix="CDoomMonsters.Zombieman.POSSA",bHasSixEight=false,Type="walk",bBright=false,Duration=0.2)
	MonsterFrames(11)=(Prefix="CDoomMonsters.Zombieman.POSSB",bHasSixEight=false,Type="walk",bBright=false,Duration=0.2)
	MonsterFrames(12)=(Prefix="CDoomMonsters.Zombieman.POSSC",bHasSixEight=false,Type="walk",bBright=false,Duration=0.2)
	MonsterFrames(13)=(Prefix="CDoomMonsters.Zombieman.POSSD",bHasSixEight=false,Type="walk",bBright=false,Duration=0.2)
}
