CREATE USER 'bbstatswebsite'@'localhost' IDENTIFIED BY PASSWORD '*A32F33CAC70F84F1F409C2F8B7213C7A875A2CCA';
GRANT SELECT ON bbstats.Games TO 'bbstatswebsite'@'localhost';
GRANT SELECT ON bbstats.Stats TO 'bbstatswebsite'@'localhost';
GRANT SELECT ON bbstats.GameSummary TO 'bbstatswebsite'@'localhost';
GRANT SELECT ON bbstats.TeamSummary TO 'bbstatswebsite'@'localhost';
GRANT SELECT ON bbstats.ManualStatsVerification TO 'bbstatswebsite'@'localhost';
GRANT SELECT ON bbstats.KenPom TO 'bbstatswebsite'@'localhost';
GRANT SELECT ON bbstats.KenPomMapping TO 'bbstatswebsite'@'localhost';

CREATE USER 'bbstatsdownload'@'localhost' IDENTIFIED BY PASSWORD '*73C632F129D022201B2605D396119495B89067F5';
GRANT SELECT,DELETE,INSERT,UPDATE ON bbstats.Games TO 'bbstatsdownload'@'localhost';
GRANT SELECT,DELETE,INSERT,UPDATE ON bbstats.Stats TO 'bbstatsdownload'@'localhost';
GRANT SELECT,DELETE,INSERT,UPDATE ON bbstats.GameSummary TO 'bbstatsdownload'@'localhost';
GRANT SELECT,DELETE,INSERT,UPDATE ON bbstats.TeamSummary TO 'bbstatsdownload'@'localhost';
GRANT SELECT ON bbstats.ManualStatsVerification TO 'bbstatsdownload'@'localhost';
GRANT SELECT,DELETE,INSERT,UPDATE ON bbstats.KenPom TO 'bbstatsdownload'@'localhost';
GRANT SELECT ON bbstats.KenPomMapping TO 'bbstatsdownload'@'localhost';

FLUSH PRIVILEGES;

