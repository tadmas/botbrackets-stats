CREATE DATABASE bbstats;
USE bbstats;

CREATE TABLE Games
(
	gameId int not null auto_increment primary key,
	ncaaGameNo int null,
	teamA varchar(100) null,
	teamAScore int null,
	teamB varchar(100) null,
	teamBScore int null,
	gameDate varchar(50) null,
	location varchar(100) null
)
ENGINE = InnoDB;

CREATE TABLE Stats
(
	gameId int not null references Games(gameId),
	team varchar(100) null,
	Minutes int null,
	FGM int null,
	FGA int null,
	`3FG` int null,
	`3FGA` int null,
	FT int null,
	FTA int null,
	PTS int null,
	OffReb int null,
	DefReb int null,
	TotReb int null,
	AST int null,
	`TO` int null,
	ST int null,
	BLKS int null,
	Fouls int null
)
ENGINE = InnoDB;

CREATE TABLE GameSummary
(
	team varchar(100) not null,
	gameId int not null references Games(gameId),
	Minutes int null,
	FGM int null,
	FGA int null,
	`3FG` int null,
	`3FGA` int null,
	FT int null,
	FTA int null,
	PTS int null,
	OffReb int null,
	DefReb int null,
	TotReb int null,
	AST int null,
	`TO` int null,
	ST int null,
	BLKS int null,
	Fouls int null,
	opponent varchar(100) null,
	OPP_Minutes int null,
	OPP_FGM int null,
	OPP_FGA int null,
	OPP_3FG int null,
	OPP_3FGA int null,
	OPP_FT int null,
	OPP_FTA int null,
	OPP_PTS int null,
	OPP_OffReb int null,
	OPP_DefReb int null,
	OPP_TotReb int null,
	OPP_AST int null,
	OPP_TO int null,
	OPP_ST int null,
	OPP_BLKS int null,
	OPP_Fouls int null,
	gameDate datetime null,
	primary key (team, gameId)
)
ENGINE = InnoDB;

CREATE TABLE TeamSummary
(
	name varchar(100) not null primary key,
	W int null,
	L int null,
	PtsFor int null,
	PtsOpp int null,
	FGM int null,
	FGA int null,
	`3FG` int null,
	`3FGA` int null,
	FT int null,
	FTA int null,
	OffReb int null,
	DefReb int null,
	TotReb int null,
	Assists int null,
	Turnovers int null,
	Steals int null,
	Blocks int null,
	Fouls int null,
	FGM_Opp int null,
	FGA_Opp int null,
	`3FG_Opp` int null,
	`3FGA_Opp` int null,
	FT_Opp int null,
	FTA_Opp int null,
	OffReb_Opp int null,
	DefReb_Opp int null,
	TotReb_Opp int null,
	Assists_Opp int null,
	Turnovers_Opp int null,
	Steals_Opp int null,
	Blocks_Opp int null,
	Fouls_Opp int null
)
ENGINE = InnoDB;

CREATE TABLE ManualStatsVerification
(
	ncaaGameNo int not null primary key,
	comments text not null
)
ENGINE = InnoDB;

CREATE TABLE KenPom
(
	Rnk smallint null,
	Team varchar(100) null,
	Conf varchar(10) null,
	W tinyint null,
	L tinyint null,
	Pyth numeric(4,4) null,
	ncaaTeam varchar(100) null
)
ENGINE = InnoDB;

CREATE TABLE KenPomMapping
(
	Team varchar(100) null,
	ncaaTeam varchar(100) null
)
ENGINE = InnoDB;

