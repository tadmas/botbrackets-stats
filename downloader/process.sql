-- ============================================================================
-- Standard fixup: game dates
-- ============================================================================

-- Normalize case to uppercase
update Games set gameDate = TRIM(UPPER(gameDate));

-- Do "p.m." -> "PM" in two stages since some cases have one dot but not the other.
update Games set gameDate = REPLACE(gameDate, 'P.M', 'PM') where gameDate like '%P.M%';
update Games set gameDate = REPLACE(gameDate, 'A.M', 'AM') where gameDate like '%A.M%';

update Games set gameDate = REPLACE(gameDate, 'AM.', 'AM') where gameDate like '%AM.%';
update Games set gameDate = REPLACE(gameDate, 'PM.', 'PM') where gameDate like '%PM.%';

-- Remove timezones
update Games set gameDate = REPLACE(gameDate, 'EST', '') where gameDate like '%EST%';
update Games set gameDate = REPLACE(gameDate, 'CST', '') where gameDate like '%CST%';
update Games set gameDate = REPLACE(gameDate, 'MST', '') where gameDate like '%MST%';
update Games set gameDate = REPLACE(gameDate, 'PST', '') where gameDate like '%PST%';
update Games set gameDate = REPLACE(gameDate, 'AST', '') where gameDate like '%AST%';
update Games set gameDate = REPLACE(gameDate, 'HST', '') where gameDate like '%HST%';

update Games set gameDate = REPLACE(gameDate, 'EDT', '') where gameDate like '%EDT%';
update Games set gameDate = REPLACE(gameDate, 'CDT', '') where gameDate like '%CDT%';
update Games set gameDate = REPLACE(gameDate, 'MDT', '') where gameDate like '%MDT%';
update Games set gameDate = REPLACE(gameDate, 'PDT', '') where gameDate like '%PDT%';
update Games set gameDate = REPLACE(gameDate, 'ADT', '') where gameDate like '%ADT%';
update Games set gameDate = REPLACE(gameDate, 'HDT', '') where gameDate like '%HDT%';

update Games set gameDate = REPLACE(gameDate, 'ET', '') where gameDate like '%ET%';
update Games set gameDate = REPLACE(gameDate, 'CT', '') where gameDate like '%CT%';
update Games set gameDate = REPLACE(gameDate, 'MT', '') where gameDate like '%MT%';
update Games set gameDate = REPLACE(gameDate, 'PT', '') where gameDate like '%PT%';
update Games set gameDate = REPLACE(gameDate, 'AT', '') where gameDate like '%AT%';
update Games set gameDate = REPLACE(gameDate, 'HT', '') where gameDate like '%HT%';

update Games set gameDate = REPLACE(gameDate, ' ()', '') where gameDate like '% ()';

-- Removing timezones can cause the date to now have a trailing space.  Need to fix.
update Games set gameDate = TRIM(gameDate) where gameDate like '% ';

-- Fix times listed as "noon"
update Games set gameDate = REPLACE(gameDate, '12 NOON', '12:00 PM') where gameDate like '% 12 NOON%';
update Games set gameDate = REPLACE(gameDate, '12:00 NOON', '12:00 PM') where gameDate like '% 12:00 NOON%';
update Games set gameDate = REPLACE(gameDate, 'NOON', '12:00 PM') where gameDate like '% NOON%';

-- Fix am/pm that doesn't have the trailing "m"
update Games set gameDate = REPLACE(gameDate, 'P', 'PM') where gameDate like '%P';
update Games set gameDate = REPLACE(gameDate, 'A', 'AM') where gameDate like '%A';

-- Fix am/pm with no space ahead of it.
update Games set gameDate = REPLACE(gameDate, 'PM', ' PM') where gameDate like '%PM%' and gameDate not like '% PM%';
update Games set gameDate = REPLACE(gameDate, 'AM', ' AM') where gameDate like '%AM%' and gameDate not like '% AM%';

-- Fix hours with no minutes
update Games set gameDate = REPLACE(gameDate, ' PM', ':00 PM') where gameDate like '% _ PM' or gameDate like '% 1_ PM';
update Games set gameDate = REPLACE(gameDate, ' AM', ':00 AM') where gameDate like '% _ AM' or gameDate like '% 1_ AM';

-- Common typo
update Games set gameDate = REPLACE(gameDate, ';', ':') where gameDate like '%;%';

-- ============================================================================
-- Standard fixup: team names
-- ============================================================================

update Stats set team = REPLACE(team, ' - Exhibition contest for this institution', '') where team like '%Exhibition%';

-- ============================================================================
-- Populate TeamSummary
-- ============================================================================
delete from TeamSummary;

insert into TeamSummary (name,W,L,PtsFor,PtsOpp,
	FGM,FGA,`3FG`,`3FGA`,FT,FTA,
	OffReb,DefReb,TotReb,
	Assists,Turnovers,Steals,Blocks,Fouls,
	FGM_Opp,FGA_Opp,`3FG_Opp`,`3FGA_Opp`,FT_Opp,FTA_Opp,
	OffReb_Opp,DefReb_Opp,TotReb_Opp,
	Assists_Opp,Turnovers_Opp,Steals_Opp,Blocks_Opp,Fouls_Opp)
select
	WLData.team,WLData.W,WLData.L,WLData.PtsFor,WLData.PtsOpp,
	Totals.FGM,Totals.FGA,Totals.`3FG`,Totals.`3FGA`,Totals.FT,Totals.FTA,
	Totals.OffReb,Totals.DefReb,Totals.TotReb,
	Totals.AST,Totals.`TO`,Totals.ST,Totals.BLKS,Totals.Fouls,
	OppTotals.FGM,OppTotals.FGA,OppTotals.`3FG`,OppTotals.`3FGA`,OppTotals.FT,OppTotals.FTA,
	OppTotals.OffReb,OppTotals.DefReb,OppTotals.TotReb,
	OppTotals.AST,OppTotals.`TO`,OppTotals.ST,OppTotals.BLKS,OppTotals.Fouls
from (
	select
		data.team,
		sum(case data.outcome when 'W' then 1 else 0 end) as W,
		sum(case data.outcome when 'L' then 1 else 0 end) as L,
		sum(data.ptsfor) as PtsFor,
		sum(data.ptsopp) as PtsOpp
	from (
		select
			Games.teamA as team,
			case when Games.teamAScore > Games.teamBScore then 'W' else 'L' end as outcome,
			Games.teamAScore as ptsfor,
			Games.teamBScore as ptsopp
		from Games
		union all
		select
			Games.teamB as team,
			case when Games.teamBScore > Games.teamAScore then 'W' else 'L' end as outcome,
			Games.teamBScore as ptsfor,
			Games.teamAScore as ptsopp
		from Games
	) as data
	group by data.team
) WLData
inner join (
	select
		Stats.team,
		sum(Stats.FGM) as FGM, sum(Stats.FGA) as FGA,
		sum(Stats.`3FG`) as `3FG`, sum(Stats.`3FGA`) as `3FGA`,
		sum(Stats.FT) as FT, sum(Stats.FTA) as FTA,
		sum(Stats.OffReb) as OffReb, sum(Stats.DefReb) as DefReb, sum(Stats.TotReb) as TotReb,
		sum(Stats.AST) as AST, sum(Stats.`TO`) as `TO`, sum(Stats.ST) as ST,
		sum(Stats.BLKS) as BLKS, sum(Stats.Fouls) as Fouls
	from Stats
	group by Stats.team
) as Totals on Totals.team = WLData.team
inner join (
	select
		TeamStats.team,
		sum(Stats.FGM) as FGM, sum(Stats.FGA) as FGA,
		sum(Stats.`3FG`) as `3FG`, sum(Stats.`3FGA`) as `3FGA`,
		sum(Stats.FT) as FT, sum(Stats.FTA) as FTA,
		sum(Stats.OffReb) as OffReb, sum(Stats.DefReb) as DefReb, sum(Stats.TotReb) as TotReb,
		sum(Stats.AST) as AST, sum(Stats.`TO`) as `TO`, sum(Stats.ST) as ST,
		sum(Stats.BLKS) as BLKS, sum(Stats.Fouls) as Fouls
	from Stats as TeamStats
	inner join Games on Games.gameId = TeamStats.gameId
	inner join Stats as Stats on Stats.gameId = Games.gameId and Stats.team <> TeamStats.team
	group by TeamStats.team
) as OppTotals on OppTotals.team = WLData.team;

-- Remove teams outside Division I
delete from TeamSummary where (W + L) < 10;

-- ============================================================================
-- Populate GameSummary
-- ============================================================================
delete from GameSummary;

insert into GameSummary (gameId,gameDate,
	team,Minutes,PTS,
	FGM,FGA,`3FG`,`3FGA`,FT,FTA,
	OffReb,DefReb,TotReb,
	AST,`TO`,ST,BLKS,Fouls,
	opponent,OPP_Minutes,OPP_PTS,
	OPP_FGM,OPP_FGA,OPP_3FG,OPP_3FGA,OPP_FT,OPP_FTA,
	OPP_OffReb,OPP_DefReb,OPP_TotReb,
	OPP_AST,OPP_TO,OPP_ST,OPP_BLKS,OPP_Fouls)
select Games.gameId,STR_TO_DATE(Games.gameDate,'%m/%d/%Y %h:%i %p'),
	A.team,A.Minutes,A.PTS,
	A.FGM,A.FGA,A.`3FG`,A.`3FGA`,A.FT,A.FTA,
	A.OffReb,A.DefReb,A.TotReb,
	A.AST,A.`TO`,A.ST,A.BLKS,A.Fouls,
	B.team,B.Minutes,B.PTS,
	B.FGM,B.FGA,B.`3FG`,B.`3FGA`,B.FT,B.FTA,
	B.OffReb,B.DefReb,B.TotReb,
	B.AST,B.`TO`,B.ST,B.BLKS,B.Fouls
from Games
inner join Stats A on A.gameId = Games.gameId and A.team = Games.teamA
inner join Stats B on B.gameId = Games.gameId and B.team = Games.teamB
inner join TeamSummary on TeamSummary.name = Games.teamA /* ignore non-DivI */
union all
select Games.gameId,STR_TO_DATE(Games.gameDate,'%m/%d/%Y %h:%i %p'),
	B.team,B.Minutes,B.PTS,
	B.FGM,B.FGA,B.`3FG`,B.`3FGA`,B.FT,B.FTA,
	B.OffReb,B.DefReb,B.TotReb,
	B.AST,B.`TO`,B.ST,B.BLKS,B.Fouls,
	A.team,A.Minutes,A.PTS,
	A.FGM,A.FGA,A.`3FG`,A.`3FGA`,A.FT,A.FTA,
	A.OffReb,A.DefReb,A.TotReb,
	A.AST,A.`TO`,A.ST,A.BLKS,A.Fouls
from Games
inner join Stats A on A.gameId = Games.gameId and A.team = Games.teamA
inner join Stats B on B.gameId = Games.gameId and B.team = Games.teamB
inner join TeamSummary on TeamSummary.name = Games.teamB; /* ignore non-DivI */

-- ============================================================================
-- Fixup summary tables
-- ============================================================================

-- Fix obviously incorrect game times
update GameSummary set gameDate = DATE_ADD(gameDate, INTERVAL 12 HOUR) where HOUR(gameDate) between 1 and 8;
