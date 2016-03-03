// Vagary spikeballs
Class VagaryShard extends Pawn;

var			Vector							DestVector;
var			bool							bIsRising;
var			float							RiseHeight;

simulated function Rise()
{
	DestVector = Location;
	DestVector.Z += RiseHeight;
	bIsRising=true;
	SetPhysics(PHYS_None);
}

simulated function Tick(float Delta)
{
	super.Tick(Delta);
	
	if (Role == ROLE_Authority)
	{
		if (bIsRising)
			SetLocation(Location+((DestVector-Location)*0.02));
	}
}

simulated function Destroyed()
{
	`Log("SHARD DESTROYED");
	super.Destroyed();
}

// Never take damage
event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser);

// StaticMesh=StaticMesh'Doom3Monsters.vagary.vagary_spike'

defaultproperties
{
	RiseHeight=250
	Health=9999
	
	Begin Object Name=CollisionCylinder
        CollisionHeight=20.0
		CollisionRadius=20.0
    End Object
	
	Begin Object Name=StaticMeshComponent0 Class=StaticMeshComponent
        StaticMesh=StaticMesh'Doom3Monsters.vagary.vagary_spike'
		bCollideActors=true
		bBlockActors=true
        bNotifyRigidBodyCollision=true
		BlockRigidBody=true        
        BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
		CollideWorld=true
		ScriptRigidBodyCollisionThreshold=0.001 
		AlwaysCheckCollision=true
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE,Pawn=TRUE)
    End Object

    CollisionComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)

    bWakeOnLevelStart=true
	bBlockActors=true	
    bWakeOnLevelStart=true
    CollisionType=COLLIDE_BlockAll
	bCollideComplex=true
	
	Physics=PHYS_Falling
}