//--DOOM 3 TICK
//------------------------------------------------------------------
Class Tick extends Trite;

DefaultProperties
{
	// SKELETAL MESH
    Begin Object Name=MainMesh
        SkeletalMesh=SkeletalMesh'Doom3Monsters.Tick.tick_mesh'
        AnimSets(0)=AnimSet'Doom3Monsters.Trite.trite_anims'
        AnimTreeTemplate=AnimTree'Doom3Monsters.doom3_animtree'
        HiddenGame=FALSE
        HiddenEditor=FALSE
		CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=false
		BlockRigidBody=true
		RBChannel=RBCC_Untitled3
		RBCollideWithChannels=(Untitled3=true,Default=true)
		bAcceptsStaticDecals=FALSE
		bAcceptsDynamicDecals=TRUE
		LightingChannels=(BSP=true,Static=true)
		LightEnvironment=MyLightEnvironment
		bHasPhysicsAssetInstance=true
		PhysicsAsset=PhysicsAsset'Doom3Monsters.Trite.trite_mesh_Physics'
		PhysicsWeight=0.0
    End Object
    Mesh=MainMesh

	FootstepSound=SoundCue'Doom3Monsters.Tick.VP.tick_walk_cue'

	PainSound=SoundCue'Doom3Monsters.Tick.VP.tick_pain_cue'
	
	SightSound=SoundCue'Doom3Monsters.Tick.VP.tick_sight_cue'
	DeathSound=SoundCue'Doom3Monsters.Tick.VP.tick_death_cue'
	AttackSound=SoundCue'Doom3Monsters.Tick.VP.tick_sight_cue'
	ChatterSound=SoundCue'Doom3Monsters.Tick.VP.tick_chirp_cue'
	IdleSound=SoundCue'Doom3Monsters.Tick.VP.tick_chirp_cue'

	PunchDamage=10
	
	MonsterName = "Tick"
}
