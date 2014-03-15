<?php

header("Content-Type: text/csv");
header('Content-Disposition: attachment; filename="teamlist.csv"');

$db = new mysqli();
$db->real_connect(); // http://stackoverflow.com/q/20445395/3750
if ($db->connect_errno) die("Connect failed: " . $db->connect_error);
$db->select_db("bbstats");

$rs = $db->query("
	select TeamSummary.name, KenPom.Rnk, KenPom.Conf, TeamSummary.W, TeamSummary.L
	from TeamSummary
	join KenPom on KenPom.ncaaTeam = TeamSummary.name
	order by TeamSummary.name");

echo "Team,NCAANumber,Conf,W,L,Pct\n";

while ($row = $rs->fetch_assoc()) {
	$pct = $row['W'] / ($row['W'] + $row['L']);
	printf("%s,%d,%s,%d,%d,%.4f\n", $row['name'], $row['Rnk'], $row['Conf'], $row['W'], $row['L'], $pct);
}

$rs->close();

$db->close();
?>
