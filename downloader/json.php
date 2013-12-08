<?php

$db = new mysqli();
$db->real_connect(); // http://stackoverflow.com/q/20445395/3750
if ($db->connect_errno) die("Connect failed: " . $db->connect_error);

$db->select_db("bbstats");

echo "var stats = {\n";

$team_summary_stmt = $db->prepare("
	select W,L,PtsFor,PtsOpp,
		FGM,FGA,`3FG`,`3FGA`,FT,FTA,
		OffReb,DefReb,TotReb,
		Assists,Turnovers,Steals,Blocks,Fouls,
		FGM_Opp,FGA_Opp,`3FG_Opp`,`3FGA_Opp`,FT_Opp,FTA_Opp,
		OffReb_Opp,DefReb_Opp,TotReb_Opp,
		Assists_Opp,Turnovers_Opp,Steals_Opp,Blocks_Opp,Fouls_Opp,
		(select Conf from KenPom where KenPom.ncaaTeam = TeamSummary.name limit 1) as Conf
	from TeamSummary
	where name = ?");

$game_list_stmt = $db->prepare("
	select opponent,PTS,OPP_PTS,
		case when PTS > OPP_PTS then 1 else 0 end as W,
		case when PTS < OPP_PTS then 1 else 0 end as L
	from GameSummary
	where team = ?
	order by gameDate, gameId");

if ($teams = $db->query("select name from TeamSummary order by name;")) {
	$team_concat = "";
	while ($team = $teams->fetch_assoc())
	{
		printf("%s\"%s\":{\n", $team_concat, $team['name']);
		$team_concat = ",";

		if ($team_summary_stmt) {
			$team_summary_stmt->bind_param("s", $team_name);
			$team_name = $team['name'];
			$team_summary_stmt->execute();
			$team_summary_stmt->bind_result($W,$L,$PtsFor,$PtsOpp,
				$FGM,$FGA,$_3FG,$_3FGA,$FT,$FTA,
				$OffReb,$DefReb,$TotReb,
				$Assists,$Turnovers,$Steals,$Blocks,$Fouls,
				$FGM_Opp,$FGA_Opp,$_3FG_Opp,$_3FGA_Opp,$FT_Opp,$FTA_Opp,
				$OffReb_Opp,$DefReb_Opp,$TotReb_Opp,
				$Assists_Opp,$Turnovers_Opp,$Steals_Opp,$Blocks_Opp,$Fouls_Opp,
				$Conf);
			$team_summary_stmt->fetch();
			printf("W:%d,L:%d,PTF:%d,PTA:%d,".
					"FGM:%d,FGA:%d,\"3FG\":%d,\"3FGA\":%d,FT:%d,FTA:%d,".
					"ORB:%d,DRB:%d,TRB:%d,".
					"AST:%d,\"TO\":%d,ST:%d,BLK:%d,PF:%d,".
					"OppFGM:%d,OppFGA:%d,Opp3FG:%d,Opp3FGA:%d,OppFT:%d,OppFTA:%d,".
					"OppORB:%d,OppDRB:%d,OppTRB:%d,".
					"OppAST:%d,OppTO:%d,OppST:%d,OppBLK:%d,OppPF:%d,".
					"Conf:\"%s\",Games:[\n",
				$W,$L,$PtsFor,$PtsOpp,
				$FGM,$FGA,$_3FG,$_3FGA,$FT,$FTA,
				$OffReb,$DefReb,$TotReb,
				$Assists,$Turnovers,$Steals,$Blocks,$Fouls,
				$FGM_Opp,$FGA_Opp,$_3FG_Opp,$_3FGA_Opp,$FT_Opp,$FTA_Opp,
				$OffReb_Opp,$DefReb_Opp,$TotReb_Opp,
				$Assists_Opp,$Turnovers_Opp,$Steals_Opp,$Blocks_Opp,$Fouls_Opp,
				$Conf);
			$team_summary_stmt->reset();
		}

		if ($game_list_stmt) {
			$game_list_stmt->bind_param("s", $team_name);
			$team_name = $team['name'];
			$game_list_stmt->execute();
			$game_list_stmt->bind_result($opponent,$PtsFor,$PtsOpp,$W,$L);
			$game_concat = "";
			while ($game_list_stmt->fetch())
			{
				printf("%s{W:%d,L:%d,PTF:%d,PTA:%d,Opponent:\"%s\"}\n",
					$game_concat,$W,$L,$PtsFor,$PtsOpp,$opponent);
				$game_concat = ",";
			}
			$game_list_stmt->reset();
		}

		echo "]}\n";
	}
	echo "};\n";
	$teams->close();
}

$db->close();

?>
