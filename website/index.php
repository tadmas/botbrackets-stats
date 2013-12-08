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
?>
</body>
</html>
