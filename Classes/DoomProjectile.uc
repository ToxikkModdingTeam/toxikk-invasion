class DoomProjectile extends CRZProjectile;

// Variables for the emitter
var 		float 		ProjScale;
var			rotator		ProjRotation;

// No team colors
simulated event CreateProjectileLight()
{
	local int TeamNum;

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
   ProjExplosionTemplateOnPawn=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_PawnImpact'
   ProjWaterExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_UnderWaterImpact'
   WaterSplashSound=SoundCue'Snd_ScionRifle.SoundCues.A_Weapon_ScionRifle_Impact_WaterCue'
   ExplosionSound=SoundCue'Snd_ScionRifle.SoundCues.A_Weapon_ScionRifle_ImpactCue'
   
   ProjFlightTemplate=ParticleSystem'Laser_Beams.Effects.P_Laser_Beam'
   ProjExplosionTemplate=ParticleSystem'ScionRifle.Effects.P_WP_ScionRifle_Impact'
   MaxEffectDistance=7000.000000

   bCheckProjectileLight=True
   CheckRadius=26.000000
   AccelRate=3000.000000
   Speed=3500.000000
   MaxSpeed=5000.000000
   Damage=35.000000
   
   MyDamageType=Class'Cruzade.CRZDmgType_Scion_Plasma'
   
   Begin Object Name=CollisionCylinder
      CollisionHeight=0.000000
      CollisionRadius=0.000000
      ReplacementPrimitive=None
      Name="CollisionCylinder"
      ObjectArchetype=CylinderComponent'Cruzade.Default__CRZProjectile:CollisionCylinder'
   End Object
   CylinderComponent=CollisionCylinder
   Components(0)=CollisionCylinder
   
   DrawScale=1.100000
   LifeSpan=3.000000
   CollisionComponent=CollisionCylinder
}