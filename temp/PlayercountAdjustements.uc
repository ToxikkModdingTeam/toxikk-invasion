
var sPlayerCountAdjuster PlayercountAdjuster;

var bool bNeedRecalcPlayercountAdjuster;

// increase difficulty on player spawn (not on join)
// decrease difficulty on player exit (not on death)

function PostBeginPlay()
{
	PerPlayerDifficultyAdjusters.Sort(CompareAdjusters);
}

function bool CompareAdjusters(out sPlayercountAdjuster a, out sPlayercountAdjuster b)
{
	return a.NumPlayers < b.NumPlayers;
}

function GroupedNewPlayerFunction(Controller NewPlayer)
{
	bNeedRecalcPlayercountAdjuster = true;
}

function SetPlayerDefaults(Pawn P)
{
	if ( CRZPawn(P) != None && bNeedRecalcPlayercountAdjuster )
		RecalcPlayercountAdjuster();
}

function NotifyLogout(Controller Exiting)
{
	if ( !Exiting.PlayerReplicationInfo.bOnlySpectator )
		RecalcPlayercountAdjuster();
}

function RecalcPlayercountAdjuster()
{
	local int i, Count, j, cur;

	for ( i=0; i<GRI.PRIArray.Length; i++ )
	{
		if ( InfekktedPRI(GRI.PRIArray[i]) != None && !GRI.PRIArray[i].bOnlySpectator )
			Count++;
	}

	PlayercountAdjuster.TotalMonsters = 1.0;
	PlayercountAdjuster.MaxDensity = 1.0;
	PlayercountAdjuster.SpawnRate = 1.0;
	PlayercountAdjuster.Health = 1.0;
	PlayercountAdjuster.MeleeDamage = 1.0;
	PlayercountAdjuster.RangeDamage = 1.0;

	for ( i=2; i<=Count; i++ )
	{
		// find the right adjuster for each progressive playercount
		cur = -1;
		for ( j=0; j<PerPlayerDifficultyAdjusters.length; j++ )
		{
			if ( PerPlayerDifficultyAdjusters[j].NumPlayers > i )
				break;
			cur = j;
		}
		if ( adjuster != -1 )
		{
			if ( bMultiplicativeAdjusters )
			{
				PlayercountAdjuster.TotalMonsters *= PerPlayerDifficultyAdjusters[cur].TotalMonsters;
				PlayercountAdjuster.MaxDensity *= PerPlayerDifficultyAdjusters[cur].MaxDensity;
				PlayercountAdjuster.SpawnRate *= PerPlayerDifficultyAdjusters[cur].SpawnRate;
				PlayercountAdjuster.Health *= PerPlayerDifficultyAdjusters[cur].Health;
				PlayercountAdjuster.MeleeDamage *= PerPlayerDifficultyAdjusters[cur].MeleeDamage;
				PlayercountAdjuster.RangeDamage *= PerPlayerDifficultyAdjusters[cur].RangeDamage;
			}
			else
			{
				PlayercountAdjuster.TotalMonsters += PerPlayerDifficultyAdjusters[cur].TotalMonsters - 1.0;
				PlayercountAdjuster.MaxDensity += PerPlayerDifficultyAdjusters[cur].MaxDensity - 1.0;
				PlayercountAdjuster.SpawnRate += PerPlayerDifficultyAdjusters[cur].SpawnRate - 1.0;
				PlayercountAdjuster.Health += PerPlayerDifficultyAdjusters[cur].Health - 1.0;
				PlayercountAdjuster.MeleeDamage += PerPlayerDifficultyAdjusters[cur].MeleeDamage - 1.0;
				PlayercountAdjuster.RangeDamage += PerPlayerDifficultyAdjusters[cur].RangeDamage - 1.0;
			}
		}
	}
	bNeedRecalcPlayercountAdjuster = false;
}
