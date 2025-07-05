class Player {
  final String name;
  final String position;
  final String number;
  final String birthDate;
  final String positionDetail;
  final String team;
  final Map<String, PlayerStats> stats;

  Player({
    required this.name,
    required this.position,
    required this.number,
    required this.birthDate,
    required this.positionDetail,
    required this.team,
    required this.stats,
  });
}

class PlayerStats {
  final String avg;
  final String hits;
  final String hr;

  PlayerStats({
    required this.avg,
    required this.hits,
    required this.hr,
  });
}

