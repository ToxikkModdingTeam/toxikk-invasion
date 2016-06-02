//================================================================
// Infekkted.MonsterProjectile
// ----------------
// ...
// ----------------
// by ZedekThePD & Chatouille
//================================================================
class MonsterProjectile extends CRZProjectile;

// Variables for the emitter
var 		float 		ProjScale;
var			rotator		ProjRotation;

/**
 * Supports accelerating projectiles
 * - Speed = initial speed
 * - AccelRate = speed gained per second
 * - MaxSpeed = maximum speed (0 means no limit)
 * 
 * TODO: better "Dropping" projectiles support
 * - DropFactor = scale factor for gravity calculation, to drop more/less
 *
 * TODO: homing support (with a Actor target, or with a Vector target)
 * - ActorTarget = homing target actor
 * - PointTarget = homing target point in space if no actor
 * - TravelFriction = the higher, the more it can turn towards target (see LootOrb)
 */
simulated function vector GetProjectileMoveFor(float dt)
{
	local Vector OldVel;

	OldVel = Velocity;

	Speed += AccelRate*dt;
	if ( MaxSpeed > 0 && Speed > MaxSpeed )
		Speed = MaxSpeed;

	Velocity = Speed*Normal(Velocity);

	if ( Physics == PHYS_Falling )
		Velocity.Z += dt * GetGravityZ()*2;

	//why are they taking the middle ??
	return (OldVel+Velocity) * dt / 2.f;
}

// No team colors
simulated event CreateProjectileLight()
{
	if ( WorldInfo.bDropDetail )
		return;

	ProjectileLight = new(self) ProjectileLightClass;
	AttachComponent(ProjectileLight);
}

simulated function SpawnFlightEffects()
{
	//local int TeamNum;
	local ParticleSystem FlightParticles;
	//local ParticleSystemComponent FlightEffect;

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		//TeamNum = GetTeamNum();

		FlightParticles = ProjFlightTemplate;

		//overwrite with Team effects
		//if(TeamNum!=255 && bUseTeamProjFlightTemplates)
		//{
		//	FlightParticles = TeamProjExplosionTemplates[TeamNum]; 
		//}

		if(FlightParticles != None)
		{
			//deactivate water effect
			if (WaterProjEffects!=None)
				WaterProjEffects.DeactivateSystem();

			if(ProjEffects != none)
			{
				ProjEffects.ActivateSystem();//just reactivate
			}
			else
			{
				ProjEffects = WorldInfo.MyEmitterPool.SpawnEmitterCustomLifetime(FlightParticles);
				ProjEffects.SetAbsolute(false, false, false);
				ProjEffects.SetLODLevel(WorldInfo.bDropDetail ? 1 : 0);
				ProjEffects.OnSystemFinished = MyOnParticleSystemFinished;
				ProjEffects.bUpdateComponentInTick = true;
				ProjEffects.CustomTimeDilation = 1/CustomTimeDilation;//dont slow it down
				ProjEffects.SetScale(ProjScale);
				ProjEffects.SetRotation(ProjRotation);
				AttachComponent(ProjEffects);
			}
		}
	}
}

simulated State WaterFlight
{

	simulated function SpawnFlightEffects()
	{
		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			if(ProjWaterFlightTemplate != None)
			{
				//deactivate old effect
				if (ProjEffects!=None)
					ProjEffects.DeactivateSystem();

				if(WaterProjEffects != none)
				{
					WaterProjEffects.ActivateSystem();//just reactivate
				}
				else
				{
					WaterProjEffects = WorldInfo.MyEmitterPool.SpawnEmitterCustomLifetime(ProjWaterFlightTemplate);
					WaterProjEffects.SetAbsolute(false, false, false);
					WaterProjEffects.SetLODLevel(WorldInfo.bDropDetail ? 1 : 0);
					WaterProjEffects.OnSystemFinished = MyOnParticleSystemFinished;
					WaterProjEffects.bUpdateComponentInTick = true;
					WaterProjEffects.CustomTimeDilation = 1/CustomTimeDilation;//dont slow it down
					AttachComponent(WaterProjEffects);
				}
			}
			else if(ProjEffects==None) //if no waterprojectile could be spawned and we have no projectileeffect jet, spawn default projectile effects
				global.SpawnFlightEffects();
		}

	}
}

defaultproperties
{
	ProjScale=5.0

	bUseExplosionRadialBlur=False
	TeamIndex=1

	MaxEffectDistance=7000.000000

	bCheckProjectileLight=True
	CheckRadius=26.000000

	//NOTE: don't neglect acceleration, with a slow start and quick acceleration to max it's very good especially for netcode
	// try to keep Speed at 500, and calc AccelRate=(MaxSpeed-Speed)*2
	Speed=500
	MaxSpeed=1700
	AccelRate=2400

	Damage=35
	MyDamageType=Class'IFDmgType_Monster'   //fallback

	DrawScale=1.100000
	LifeSpan=6.000000
}
