//------------------------------------------------------------------
Class VagaryController extends ToxikkMonsterController;

// Only do ranged if we have spikes
function bool ExtraRangedException()
{
	return Vagary(Pawn).CanUseShards();
}