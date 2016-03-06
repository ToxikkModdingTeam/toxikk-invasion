//--CLASSIC DOOM MONSTER BASE
//------------------------------------------------------------------
Class CDoomMonster extends ToxikkMonster;

var()				CDoomFakeSprite							Faker;

Struct SStruct
{
	// Rotations that this frame has
	var				array<Texture2D>				Frames;
	var				array<bool>						FrameFlip;
	// Four-letter prefix
	var				string							Prefix;
	// Whether or not we have to flip frames
	var				bool							bHasSixEight;
	// Whether or not this frame is bright
	var				bool							bBright;
	// What to force on this frame
	// FIRE, CLAW
	var				string							ForceEvent;
	// What type this frame is
	// IDLE, FIRE, PAIN, DEATH, GIB, MELEE, WALK
	var				string							Type;
	// How long this frame lasts
	var				float							Duration;
	// Use angle 0
	var				bool							bCardboard;
};

// All of the frames that this monster will use
var()				array<SStruct>						MonsterFrames;
// Caps for animation
var()				int									IdleLength, FireLength, PainLength, DeathLength, GibLength, MeleeLength, WalkLength;
// Positions in the list for certain states
var()				int									IdleID, FireID, PainID, DeathID, GibID, MeleeID, WalkID;

var()				int									ShotDamage;
var()				float								ShotSpread;
var()				float								ShotRange;
var()				int									CurrentFrame;
var()				string								SpriteState;
var()				int									BulletCount;
var()				bool								bHitscanMonster;
var()				ParticleSystem						TracingClass;
var()				float								ShotHeight;
var()				float								ExtentRad;

//------------------------------------------------------------------

// Frame is also controlled serverside since we have to do "notifies" and stuff
replication
{
	if (bNetDirty || bNetInitial)
		SpriteState, CurrentFrame;
}

simulated function PlayRangedSound()
{
	PlaySound(FireSound,TRUE);
}

// Called serverside and serverside only
simulated function RangedFire()
{
	local int l;
	
	PlayRangedSound();
	
	if (bHitscanMonster)
	{
		for (l=0; l<BulletCount; l++)
		{
			DoBullet();
		}
	}
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	
	if (Role == ROLE_Authority)
		CDoomController(Controller).GotoState('Paining');
}

// Serverside
// Copied from my Doom weps - Zedek
simulated function DoBullet()
{
	local Pawn PunchVictim;
	local vector HL, HN, TraceEnd;
	// Where the vector starts
	local vector IL, PVV;
	local rotator PVR, SpreadRot;
	local Vector TE;
	
	PVV = Location;
	PVV.Z += ShotHeight;
	
	PVR = Rotation;
	
	SpreadRot.Pitch += ShotSpread;
	SpreadRot.Yaw += ShotSpread;
	
	// Flip?
	if (FRand() >= 0.5)
		SpreadRot.Pitch *= -1;
	if (FRand() >= 0.5)
		SpreadRot.Yaw *= -1;

	TraceEnd = PVV + (Vector(PVR+SpreadRot) * ShotRange);
	TE.X = ExtentRad;
	TE.Y = ExtentRad;
	TE.Z = ExtentRad;
	
	SpawnTracer(PVV,TraceEnd);
	
	ForEach TraceActors(Class'Pawn',PunchVictim,HL,HN,TraceEnd,PVV,TE)
	{
		// TODO: Spawn puffs
		// Spawn(PunchPuff,,,HL);
		
		PunchVictim.TakeDamage(ShotDamage, Controller, HL, Vect(0,0,0), None);
	}
}

unreliable client function SpawnTracer(vector Start, vector Endy)
{
	local ParticleSystemComponent E;
	local actor HitActor;
	local vector HitNormal, HitLocation;
	
	if ( Endy == Vect(0,0,0) )
	{
		Endy = Start;
		HitActor = Instigator.Trace(HitLocation, HitNormal, Endy, Start, TRUE, vect(0,0,0),, TRACEFLAG_Bullet);
		if ( HitActor != None )
		{
			Endy = HitLocation;
		}
	}
	
	E = WorldInfo.MyEmitterPool.SpawnEmitter(TracingClass, Start);
	E.SetVectorParameter('BeamEnd', Endy);
	E.SetDepthPriorityGroup(SDPG_World);
}

// Used for calculating the total length of sprites with a certain type
function float CalcStateTime(string Type)
{
	local int l;
	local float TT;
	
	for (l=0; l<MonsterFrames.Length; l++)
	{
		if (MonsterFrames[l].Type ~= Type)
			TT += MonsterFrames[l].Duration;
	}
	
	return TT;
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	
	// Load on both client and server
	SetupSprites();
	
	// On the clientside, spawn our fake sprite
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (Faker == None)
		{
			Faker = Spawn(Class'CDoomFakeSprite',Self);
			Faker.SetBase(Self);
			Faker.OwningPawn = Self;
		}
	}
	
	if (Role == ROLE_Authority)
		IncrementFrame();
		
	Mesh.SetScale(0.0);
}

simulated function PlayFootstep();

// Move forward a frame
simulated function IncrementFrame()
{
	local int Cap, ID;
	
	if (SpriteState ~= "dead")
		return;
	
	// How many frames our animation has, plus the start of that anim
	GetCap(Cap, ID);
	
	// Reached the end of our animation
	if (CurrentFrame+1 > ID+(Cap-1))
	{
		// if (SpriteState ~= "fire" || SpriteState ~= "melee" || SpriteState ~= "pain")
		if (SpriteState ~= "walk")
			SetSpriteState("walk");
		else if (SpriteState ~= "death")
			SetSpriteState("dead");
		else
			SetSpriteState("idle");
	}
	
	// Else, just proceed
	else
	{
		CurrentFrame ++;
		SetTimer(MonsterFrames[CurrentFrame].Duration,false,'IncrementFrame');
	}
	
	if (Role == ROLE_Authority)
	{
		if (MonsterFrames[CurrentFrame].ForceEvent ~= "FIRE")
			RangedFire();
	}
}

simulated function Destroyed()
{
	if (Faker != None)
		Faker.Destroy();
		
	super.Destroyed();
}

function GetCap(out int Cappy, out int IDD)
{
	if (SpriteState ~= "idle")
	{
		Cappy = IdleLength;
		IDD = IdleID;
	}
	else if (SpriteState ~= "fire")
	{
		Cappy = FireLength;
		IDD = FireID;
	}
	else if (SpriteState ~= "pain")
	{
		Cappy = PainLength;
		IDD = PainID;
	}
	else if (SpriteState ~= "death")
	{
		Cappy = DeathLength;
		IDD = DeathID;
	}
	else if (SpriteState ~= "dead")
	{
		Cappy = 0;
		IDD = DeathID+DeathLength;
	}
	else if (SpriteState ~= "gib")
	{
		Cappy = GibLength;
		IDD = GibID;
	}
	else if (SpriteState ~= "melee")
	{
		Cappy = MeleeLength;
		IDD = MeleeID;
	}
	else if (SpriteState ~= "walk")
	{
		Cappy = WalkLength;
		IDD = WalkID;
	}
}

// Set a new sprite state
simulated function SetSpriteState(string NS)
{
	SpriteState = NS;
	
	// Set ID according to state
	if (NS ~= "idle")
		CurrentFrame = IdleID-1;
	else if (NS ~= "fire")
		CurrentFrame = FireID-1;
	else if (NS ~= "pain")
		CurrentFrame = PainID-1;
	else if (NS ~= "death")
		CurrentFrame = DeathID-1;
	else if (NS ~= "dead")
		CurrentFrame = DeathID+(DeathLength-1);
	else if (NS ~= "gib")
		CurrentFrame = GibID-1;
	else if (NS ~= "melee")
		CurrentFrame = MeleeID-1;
	else if (NS ~= "walk")
		CurrentFrame = WalkID-1;

	IncrementFrame();
}

// Setup all of the angles and shit for sprites
simulated function SetupSprites()
{
	local int l,m;
	local int AngleString;
	
	for (l=0; l<MonsterFrames.Length; l++)
	{
		// For each angle within the sprite...
		for (m=0; m<8; m++)
		{
			MonsterFrames[l].Frames.Add(1);
			
			// We have pre-specified 6-8 animations
			if (MonsterFrames[l].bHasSixEight)
			{
				AngleString=m;
				
				if (MonsterFrames[l].bCardboard)
					AngleString=-1;
				
				MonsterFrames[l].Frames[MonsterFrames[l].Frames.Length-1] = Texture2D(DynamicLoadObject(MonsterFrames[l].Prefix$string(AngleString+1),Class'Texture2D'));
				MonsterFrames[l].FrameFlip.AddItem(false);
			}
			// Otherwise, do some flipping
			else
			{
				// 0 is 1, 2 is 3, etc.
				AngleString = m+1;
				// Flipflip
				if (AngleString == 6)
					AngleString = 4;
				if (AngleString == 7)
					AngleString = 3;
				if (AngleString == 8)
					AngleString = 2;
					
				if (MonsterFrames[l].bCardboard)
					AngleString=0;
					
				MonsterFrames[l].Frames[MonsterFrames[l].Frames.Length-1] = Texture2D(DynamicLoadObject(MonsterFrames[l].Prefix$string(AngleString),Class'Texture2D'));
				// `Log("["$string(m)$"] Trying to load"@MonsterFrames[l].Prefix$string(AngleString)$"...");
				
				if (m > 4 && !MonsterFrames[l].bCardboard)
					MonsterFrames[l].FrameFlip.AddItem(true);
				else
					MonsterFrames[l].FrameFlip.AddItem(false);
			}
		}
		
		// Caps
		if (MonsterFrames[l].Type ~= "IDLE")
		{
			IdleLength ++;
			if (IdleID < 0)
				IdleID = l;
		}
		else if (MonsterFrames[l].Type ~= "FIRE")
		{
			FireLength ++;
			if (FireID < 0)
				FireID = l;
		}
		else if (MonsterFrames[l].Type ~= "PAIN")
		{
			PainLength ++;
			if (PainID < 0)
				PainID = l;
		}
		else if (MonsterFrames[l].Type ~= "DEATH")
		{
			DeathLength ++;
			if (DeathID < 0)
				DeathID = l;
		}
		else if (MonsterFrames[l].Type ~= "GIB")
		{
			GibLength ++;
			if (GibID < 0)
				GibID = l;
		}
		else if (MonsterFrames[l].Type ~= "MELEE")
		{
			MeleeLength ++;
			if (MeleeID < 0)
				MeleeID = l;
		}
		else if (MonsterFrames[l].Type ~= "WALK")
		{
			WalkLength ++;
			if (WalkID < 0)
				WalkID = l;
		}
	}
}

reliable server function SeenSomething()
{
	PlaySound(SightSound, TRUE);
	SetSpriteState("walk");
}

simulated function Tick(float Delta)
{
	super.Tick(Delta);
}

// TURN THE MONSTER INTO A RAGDOLL
simulated function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
  if (Super(Pawn).Died(Killer, DamageType, HitLocation))
  {
	PlaySound(DeathSound, TRUE);
    CylinderComponent.SetActorCollision(false, false);
    Mesh.SetActorCollision(true, false);
    Mesh.SetTraceBlocking(true, true);
	if (Role == ROLE_Authority)
	{
		SetSpriteState("death");
		Acceleration = vect(0,0,1);
	}
    return true;
  }
}

defaultproperties
{
	ShotRange=10000
	ShotDamage=100
	
	// List IDs
	IdleID = -1
	FireID = -1
	PainID = -1
	DeathID = -1
	GibID = -1
	MeleeID = -1
	WalkID = -1
	
	SpriteState="idle"
	
	ControllerClass=Class'CDoomController'
	
	ExtentRad=10
}