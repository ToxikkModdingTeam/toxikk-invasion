class SabaothBall extends HellknightBall;

var			float			BFGMult, FlightScale, ExplodeScale, ExplodeDistance;
var			int				BoomIntensity;

// An array of targets that we should be beaming toward
var repnotify		array<Pawn>								BeamTargets;
var					float									BeamTime;
var					ParticleSystem							BeamFX;
var					array<ParticleSystemComponent>			Beams;
var					float									BeamRadius;
var					int										BeamDamage;


simulated function PostBeginPlay()
{
	// force ambient sound if not vehicle game mode
	bImportantAmbientSound = !WorldInfo.bDropDetail;
	Super.PostBeginPlay();
	
	if (Role == ROLE_Authority)
	SetTimer(BeamTime,true,'UpdateTargets');
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'BeamTargets')
		UpdateTargets();
		
	super.ReplicatedEvent(VarName);
}


simulated function Tick(float DT)
{
	local int l;
	
	super.Tick(DT);
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (Beams.Length > 0)
		{
			for (l=0; l<Beams.Length; l++)
			{
				Beams[l].SetVectorParameter('BeamStart', Location);
			}
		}
	}
}


// -- SERVER-SIDE --
simulated function UpdateTargets()
{
	local Pawn PP;
	
	BeamTargets.Length = 0;
	
	ForEach VisibleCollidingActors(Class'Pawn',PP,BeamRadius)
	{
		if (PP != Instigator && ToxikkMonster(PP) == None)
		{
			BeamTargets.AddItem(PP);
			PP.TakeDamage(BeamDamage*BFGMult,Instigator.Controller,Location,Vect(0,0,0),Class'Cruzade.CRZDmgType_Hellraiser');
		}
	}
	
	// `Log("Updated targets.");
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
		ClientUpdateBeams();
}

simulated function ClientUpdateBeams()
{
	local int l;
	local Vector V;
	
	// Clear our old beams
	if (Beams.Length > 0)
	{
		for (l=0; l<Beams.Length; l++)
		{
			Beams[l].DeactivateSystem();
			Beams[l].KillParticlesForced();
			Beams[l] = None;
		}
		
		Beams.Length = 0;
	}
	
	// Now make new beams
	for (l=0; l<BeamTargets.Length; l++)
	{
		Beams[l] = WorldInfo.MyEmitterPool.SpawnEmitter(BeamFX, Location);
		
		V = BeamTargets[l].Location;
		V.Z += CylinderComponent(BeamTargets[l].CollisionComponent).CollisionHeight / 2;
		
		Beams[l].SetVectorParameter('BeamEnd', V);
		Beams[l].SetVectorParameter('BeamStart', Location);
		Beams[l].SetDepthPriorityGroup(SDPG_World);
	}
}

function CRZInit(vector Direction, vector AimDir, int NewShotID)
{
	Init(Direction);
	InstigatorAimDir = AimDir;
	ShotID = NewShotID;
	
	Damage *= BFGMult;
	
	if (role == ROLE_Authority)
		`Log("Damage is"@string(Damage));
}

simulated function SpawnFlightEffects()
{
	super.SpawnFlightEffects();
	if (ProjEffects != None)
		ProjEffects.SetScale(FlightScale);
}

simulated function SpawnExplosionEffects(vector HitLocation, vector HitNormal)
{
	local UTPlayerController PC;
	local int l;
	
	super.SpawnExplosionEffects(HitLocation,HitNormal);

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		foreach WorldInfo.LocalPlayerControllers(class'UTPlayerController', PC)
		{
			if ( PC.Pawn != None )
				PC.DamageShake(BoomIntensity * BFGMult * (1.0 -(VSize(PC.Pawn.Location - HitLocation)/ExplodeDistance)),None);
			else if ( PC.ViewTarget != None )
				PC.DamageShake(BoomIntensity * BFGMult * (1.0 -(VSize(PC.ViewTarget.Location - HitLocation)/ExplodeDistance)),None);
		}
	}
	
	if (Beams.Length > 0)
	{
		for (l=0; l<Beams.Length; l++)
		{
			Beams[l].DeactivateSystem();
			Beams[l].KillParticlesForced();
			Beams[l] = None;
		}
		
		Beams.Length = 0;
	}
}

defaultproperties
{
	ProjectileLightClass=Class'ImpLight'
	ExplosionLightClass=Class'ImpLightBoom'
	
	ProjFlightTemplate=ParticleSystem'Doom3Monsters.Sabaoth.Particles.bfgball_pfx'
	ProjExplosionTemplate=ParticleSystem'Doom3Monsters.Sabaoth.Particles.bfg_explode_fx'
	ProjExplosionTemplateOnPawn=ParticleSystem'Doom3Monsters.Sabaoth.Particles.bfg_explode_fx'
	ExplosionSound=SoundCue'Doom3Monsters.Sabaoth.VP.bfg_explode_cue'
	AmbientSound=SoundCue'Doom3Monsters.Sabaoth.VP.bfg_fly_cue'

	Damage=40
	MyDamageType=Class'IFDmgType_HellknightBall'

	ProjScale=1.5
	FlightScale = 5.0
	ExplodeScale = 6.0
	
	BFGMult = 1.0
	
	BeamTime = 0.2
	BeamFX = ParticleSystem'Doom3Monsters.Sabaoth.Particles.bfg_arc_fx'
	BeamRadius = 256
	BeamDamage = 10
	
	BoomIntensity = 400
	ExplodeDistance = 2500
}
