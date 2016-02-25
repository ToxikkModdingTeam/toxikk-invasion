
CONST MAPSIZE_REFERENCE = 4096;

var sMapAdjuster MapAdjuster;

function CalcMapAdjusters()
{
	local int i;

	i = MapAdjusters.Find('Map', WorldInfo.GetMapName(true));
	if ( i != INDEX_None )
		MapAdjuster = MapAdjusters[i];
	else
	{
		Size = CalcAvgMapSize();
		`Log("[DEBUG] Calculated avg map size: " $ Size);
		SizeDiff = Size / MAPSIZE_REFERENCE;
		`Log("[DEBUG] SizeDiff = " $ SizeDiff);
		MapAdjuster.TotalMonsters = SizeDiff * AutoMapAdjuster.TotalMonsters;
		MapAdjuster.SpawnRate = SizeDiff * AutoMapAdjuster.SpawnRate;
		MapAdjuster.MaxDensity = SizeDiff * AutoMapAdjuster.MaxDensity;
	}
}

function float CalcAvgMapSize()
{
	local NavigationPoint P;
	local float Weight, Total;
	local Vector Center;
	local float AvgDist;

	foreach WorldInfo.AllNavigationPoints(class'NavigationPoint', P)
	{
		Weight = WeightForNavPoint(P);
		Center = (Total / (Total+Weight))*Center + (Weight / (Total+Weight))*P.Location;
		Total += Weight;
	}

	AvgSize = 0.0;
	foreach WorldInfo.AllNavigationPoints(class'NavigationPoint', P)
	{
		AvgDist += (WeightForNavPoint(P) / Total) * VSize( (P.Location - Center)*Vect(1.0,1.0,0.5) );
	}
	
	return AvgDist;
}

function float WeightForNavPoint(NavigationPoint P)
{
	if ( P.IsA('PlayerStart') ) return 3;
	if ( P.IsA('PathNode') ) return 1;
	return 0;
}
