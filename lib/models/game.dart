class Game {
  final String homeTeam;
  final String awayTeam;
  final String homeTeamLogo;
  final String awayTeamLogo;
  final String time;
  final String stadium;
  final String homePitcher;
  final String awayPitcher;
  final String status;
  final int? homeWinProbability;
  final int? awayWinProbability;

  Game({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
    required this.time,
    required this.stadium,
    required this.homePitcher,
    required this.awayPitcher,
    required this.status,
    this.homeWinProbability,
    this.awayWinProbability,
  });
}

