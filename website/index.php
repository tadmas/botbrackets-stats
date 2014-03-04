<html>
<head>
<title>Bot Brackets Stats</title>
<style>
body { background: #ffffee; color: #663300; }
table { border-collapse: collapse; }
td, th { border: 1px solid #331800; padding: 0.2em 0.5em; }
th { background: #cc6600; color: #ffeedd; }
</style>
<script>
function toggleNextRow(row) {
	var nextRow = row.nextSibling;
	while ((nextRow.nodeName || '').toUpperCase() != 'TR') {
		nextRow = nextRow.nextSibling;
	}
	if (nextRow.style.display)
		nextRow.style.display = '';
	else
		nextRow.style.display = 'none';
}
</script>
</head>
<body>
<h1>Bot Brackets Stats</h1>
<?php

$db = new mysqli();
$db->real_connect(); // http://stackoverflow.com/q/20445395/3750
if ($db->connect_errno) die("Connect failed: " . $db->connect_error . "</body></html>");
$db->select_db("bbstats");

$rs = $db->query("
	select SeasonWL.team, SeasonWL.W, SeasonWL.L,
		KenPom.Team as KenPomTeam, KenPom.W as KenPomW, KenPom.L as KenPomL,
		(select max(GameSummary.gameDate) from GameSummary where GameSummary.team = KenPom.ncaaTeam) as LastGameDate
	from (
		select GameWL.team,
			sum(case GameWL.outcome when 'W' then 1 else 0 end) as W,
			sum(case GameWL.outcome when 'L' then 1 else 0 end) as L
		from (
			select teamA as team, case when teamAScore > teamBScore then 'W' else 'L' end as outcome from Games
			union all
			select teamB as team, case when TeamBScore > teamAScore then 'W' else 'L' end as outcome from Games
		) as GameWL
		group by GameWL.team
	) as SeasonWL
	join KenPom on KenPom.ncaaTeam = SeasonWL.team
	where KenPom.W <> SeasonWL.W or KenPom.L <> SeasonWL.L
	order by SeasonWL.team");

if ($rs->num_rows > 0) {
	echo "<h2>Record check failures</h2>\n";
	echo "<table>\n";
	echo "<tr><th>NCAA team</th><th>W</th><th>L</th><th>Last Game</th><th>KenPom team</th><th>W</th><th>L</th><th>Notes</th></tr>\n";

	$stmt = $db->prepare("
		select Games.ncaaGameNo,Games.gameDate,GameSummary.opponent,GameSummary.PTS,GameSummary.OPP_PTS,
			case when GameSummary.PTS > GameSummary.OPP_PTS then 'W' else 'L' end as outcome
		from GameSummary
		join Games on Games.gameId = GameSummary.gameId
		where GameSummary.team = ?
		order by GameSummary.gameDate, Games.ncaaGameNo");

	while ($row = $rs->fetch_assoc()) {
		$notes = "Record mismatch";
		if ($row['W'] >= $row['KenPomW'] && $row['L'] >= $row['KenPomL']) $notes = "Duplicate games?";
		if ($row['W'] <= $row['KenPomW'] && $row['L'] <= $row['KenPomL']) $notes = "Missing games";

		printf("<tr onclick='toggleNextRow(this);' style='cursor:hand;'>".
			"<td>%s</td><td>%d</td><td>%d</td><td>%s</td>".
			"<td>%s</td><td>%d</td><td>%d</td><td>%s</td></tr>\n",
			$row['team'], $row['W'], $row['L'], $row['LastGameDate'],
			$row['KenPomTeam'], $row['KenPomW'], $row['KenPomL'], $notes);

		$stmt->bind_param("s", $team_name);
		$team_name = $row['team'];
		$stmt->execute();
		$stmt->bind_result($gameNo,$gameDate,$opponent,$PtsFor,$PtsOpp,$outcome);
		echo "<tr style='display:none'><td colspan=8><table style='margin-left: 1em;'>\n";
		echo "  <tr><th>#</th><th>Game Date</th><th>Opponent</th><th>PTS</th><th>PTA</th><th>W/L</th></tr>\n";
		while ($stmt->fetch())
		{
			printf("  <tr><td>%s</td><td>%s</td><td>%s</td><td>%d</td><td>%d</td><td>%s</td></tr>\n",
				$gameNo,$gameDate,$opponent,$PtsFor,$PtsOpp,$outcome);
		}
		echo "</table></td></tr>\n";
		$stmt->reset();
	}
	echo "</table>\n";
}
$rs->close();

$rs = $db->query("
	select Games.ncaaGameNo, Games.gameDate, Games.teamA, Games.teamB, COUNT(Stats.gameId) as NumStats
	from Games
	left outer join Stats on Stats.gameId = Games.gameId
	group by Games.ncaaGameNo, Games.gameDate, Games.teamA, Games.teamB
	having COUNT(Stats.gameId) <> 2
	order by ncaaGameNo");
if ($rs->num_rows > 0) {
	echo "<h2>Internal stats errors</h2>\n";
	echo "<table>\n";
	echo "<tr><th>#</th><th>Game Date Text</th><th>Team 1</th><th>Team 2</th><th># stats records</th></tr>\n";
	while ($row = $rs->fetch_assoc()) {
		printf("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%d</td></tr>\n",
			$row['ncaaGameNo'],$row['gameDate'],$row['teamA'],$row['teamB'],$row['NumStats']);
	}
	echo "</table>\n";
}
$rs->close();

$rs = $db->query("
	select Games.ncaaGameNo, GameSummary.team, GameSummary.opponent, GameSummary.gameDate,
		GameSummary.PTS, GameSummary.FGM, GameSummary.`3FG`, GameSummary.FT,
		(GameSummary.FGM * 2 + GameSummary.`3FG` + GameSummary.FT) AS CalcPTS, null as Score
	from GameSummary
	join Games on Games.gameId = GameSummary.gameId
	where GameSummary.PTS <> (GameSummary.FGM * 2 + GameSummary.`3FG` + GameSummary.FT)
	and not exists (select * from ManualStatsVerification where ManualStatsVerification.ncaaGameNo = Games.ncaaGameNo)

	union all

	select Games.ncaaGameNo, GameSummary.team, GameSummary.opponent, GameSummary.gameDate,
		GameSummary.PTS, GameSummary.FGM, GameSummary.`3FG`, GameSummary.FT,
		null AS CalcPTS, Games.teamAScore AS Score
	from GameSummary
	join Games on Games.gameId = GameSummary.gameId and Games.teamA = GameSummary.team
	where GameSummary.PTS <> Games.teamAScore
	and not exists (select * from ManualStatsVerification where ManualStatsVerification.ncaaGameNo = Games.ncaaGameNo)

	union all

	select Games.ncaaGameNo, GameSummary.team, GameSummary.opponent, GameSummary.gameDate,
		GameSummary.PTS, GameSummary.FGM, GameSummary.`3FG`, GameSummary.FT,
		null AS CalcPTS, Games.teamBScore AS Score
	from GameSummary
	join Games on Games.gameId = GameSummary.gameId and Games.teamB = GameSummary.team
	where GameSummary.PTS <> Games.teamBScore
	and not exists (select * from ManualStatsVerification where ManualStatsVerification.ncaaGameNo = Games.ncaaGameNo)

	order by ncaaGameNo");
if ($rs->num_rows > 0) {
	echo "<h2>Points mismatch</h2>\n";
	echo "<table>\n";
	echo "<tr><th>#</th><th>Game Date</th><th>Team</th><th>Opponent</th><th>PTS</th><th>Calculated PTS</th></tr>\n";
	while ($row = $rs->fetch_assoc()) {
		if (is_null($row['CalcPTS']))
			printf("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%d</td><td>%d = Game Score</td></tr>\n",
				$row['ncaaGameNo'],$row['gameDate'],$row['team'],$row['opponent'],$row['PTS'],$row['Score']);
		else
			printf("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%d</td><td>%d = %d FG + %d 3FG + %d FT</td></tr>\n",
				$row['ncaaGameNo'],$row['gameDate'],$row['team'],$row['opponent'],$row['PTS'],
				$row['CalcPTS'],$row['FGM'],$row['3FG'],$row['FT']);
	}
	echo "</table>\n";
}
$rs->close();

$rs = $db->query("
	select Games.ncaaGameNo, GameSummary.team, GameSummary.opponent, GameSummary.gameDate,
		GameSummary.TotReb, GameSummary.OffReb, GameSummary.DefReb, (GameSummary.OffReb + GameSummary.DefReb) AS CalcTotReb
	from GameSummary
	join Games on Games.gameId = GameSummary.gameId
	where GameSummary.TotReb <> (GameSummary.OffReb + GameSummary.DefReb)
	and not exists (select * from ManualStatsVerification where ManualStatsVerification.ncaaGameNo = Games.ncaaGameNo)
	order by Games.ncaaGameNo");
if ($rs->num_rows > 0) {
	echo "<h2>Rebound mismatch</h2>\n";
	echo "<table>\n";
	echo "<tr><th>#</th><th>Game Date</th><th>Team</th><th>Opponent</th><th>TotReb</th><th>Calculated TotReb</th></tr>\n";
	while ($row = $rs->fetch_assoc()) {
		printf("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%d</td><td>%d = %d ORB + %d DRB</td></tr>\n",
			$row['ncaaGameNo'],$row['gameDate'],$row['team'],$row['opponent'],
			$row['TotReb'],$row['CalcTotReb'],$row['OffReb'],$row['DefReb']);
	}
	echo "</table>\n";
}
$rs->close();

$rs = $db->query("
	select Games.ncaaGameNo, Games.gameDate, Games.teamA, Games.teamB
	from Games
	join GameSummary on GameSummary.gameId = Games.gameId
	where GameSummary.gameDate is null
	order by Games.ncaaGameNo");

if ($rs->num_rows > 0) {
	echo "<h2>Invalid game dates</h2>\n";
	echo "<table>\n";
	echo "<tr><th>#</th><th>Game Date Text</th><th>Team 1</th><th>Team 2</th></tr>\n";
	while ($row = $rs->fetch_assoc()) {
		printf("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n",
			$row['ncaaGameNo'],$row['gameDate'],$row['teamA'],$row['teamB']);
	}
	echo "</table>\n";
}
$rs->close();

$rs = $db->query("
	select Games.ncaaGameNo, GameSummary.team, GameSummary.opponent, GameSummary.gameDate, 'same day, no am/pm' as notes
	from GameSummary
	join Games on Games.gameId = GameSummary.gameId
	where Games.gameDate not like '% AM' and Games.gameDate not like '% PM'
	and exists (
		select * from GameSummary as Other
		where Other.team = GameSummary.team
		and Other.gameId <> GameSummary.gameId
		and cast(Other.gameDate as date) = cast(GameSummary.gameDate as date)
	)

	union all

	select Games.ncaaGameNo, GameSummary.team, GameSummary.opponent, GameSummary.gameDate, 'start times within 3 hours' as notes
	from GameSummary
	join Games on Games.gameId = GameSummary.gameId
	where exists (
		select * from GameSummary as Other
		where Other.team = GameSummary.team
		and Other.gameId <> GameSummary.gameId
		and abs(timestampdiff(HOUR, GameSummary.gameDate, Other.gameDate)) < 3
	)

	order by ncaaGameNo");
if ($rs->num_rows > 0) {
	echo "<h2>Date clash</h2>\n";
	echo "<table>\n";
	echo "<tr><th>#</th><th>Game Date</th><th>Team</th><th>Opponent</th><th>Notes</th></tr>\n";
	while ($row = $rs->fetch_assoc()) {
		printf("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n",
			$row['ncaaGameNo'],$row['gameDate'],$row['team'],$row['opponent'],$row['notes']);
	}
	echo "</table>\n";
}
$rs->close();

$rs = $db->query("
	select Games.ncaaGameNo, Games.gameDate, Games.teamA, Games.teamB, Stats.team
	from Stats
	join Games on Games.gameId = Stats.gameId
	where Stats.team <> Games.teamA and Stats.team <> Games.teamB
	order by ncaaGameNo");
if ($rs->num_rows > 0) {
	echo "<h2>Team name mismatch</h2>\n";
	echo "<table>\n";
	echo "<tr><th>#</th><th>Game Date Text</th><th>Team 1</th><th>Team 2</th><th>Stats Team</th></tr>\n";
	while ($row = $rs->fetch_assoc()) {
		printf("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n",
			$row['ncaaGameNo'],$row['gameDate'],$row['teamA'],$row['teamB'],$row['team']);
	}
	echo "</table>\n";
}
$rs->close();

$rs = $db->query("
	select KenPomMapping.Team, KenPomMapping.ncaaTeam, 'Team missing from NCAA data.' as Notes
	from KenPomMapping
	left join TeamSummary on TeamSummary.name = KenPomMapping.ncaaTeam
	where TeamSummary.name is null

	union all

	select null as Team, TeamSummary.name as ncaaTeam, 'No KenPom mapping entry.' as Notes
	from TeamSummary
	left join KenPomMapping on KenPomMapping.ncaaTeam = TeamSummary.name
	where KenPomMapping.ncaaTeam is null

	union all

	select KenPom.Team, null as ncaaTeam, 'No KenPom mapping entry.' as Notes
	from KenPom
	left join KenPomMapping on KenPomMapping.Team = KenPom.Team
	where KenPomMapping.Team is null

	union all

	select KenPomMapping.Team, KenPomMapping.ncaaTeam, 'No KenPom entry this season.' as Notes
	from KenPomMapping
	left join KenPom on KenPom.Team = KenPomMapping.Team
	where KenPom.Team is null

	order by coalesce(Team, ncaaTeam)");

if ($rs->num_rows > 0) {
	echo "<h2>KenPom mapping errors</h2>\n";
	echo "<table>\n";
	echo "<tr><th>KenPom team name</th><th>NCAA team name</th><th>Notes</th></tr>\n";
	while ($row = $rs->fetch_assoc()) {
		printf("<tr><td>%s</td><td>%s</td><td>%s</td></tr>\n",
			$row['Team'], $row['ncaaTeam'], $row['Notes']);
	}
	echo "</table>\n";
}
$rs->close();

$db->close();
echo "<h1>Done</h1>";
?>
</body>
</html>
