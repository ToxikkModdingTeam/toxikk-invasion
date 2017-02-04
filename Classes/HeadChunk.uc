class HeadChunk extends CRZGib;
	
simulated function DoCustomGibEffects();

defaultproperties
{
   Begin Object Name=GibLightEnvironmentComp
      bCastShadows=False
      AmbientShadowColor=(R=0.300000,G=0.300000,B=0.300000,A=1.000000)
      AmbientGlow=(R=0.500000,G=0.500000,B=0.500000,A=1.000000)
   End Object
   GibLightEnvironment=GibLightEnvironmentComp
   HitSound=None
   Components(0)=GibLightEnvironmentComp
   
   GibMeshesData(0)=(TheStaticMesh=StaticMesh'InfekktedResources.FX.hs_gib_1',DrawScale=0.5)
   GibMeshesData(1)=(TheStaticMesh=StaticMesh'InfekktedResources.FX.hs_gib_2',DrawScale=0.5)
}
