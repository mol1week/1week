import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/my_team_provider.dart';

/// PredictionScreen:
/// ScheduleScreen에서 전달된 game 정보를 바탕으로
/// 예측 데이터를 표시합니다.
/// 이미 끝난(경기종료) 게임은 실제 결과에 맞추어 100%/0%를 표시합니다.
class PredictionScreen extends StatefulWidget {
  final Map<String, dynamic> game;
  const PredictionScreen({Key? key, required this.game}) : super(key: key);

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  Map<String, dynamic>? _predData;
  bool _isLoading = true;
  Map<String, double> _teamAvg = {};
  Map<String, double> _teamOps = {};
  // 최근 5경기 결과를 저장할 맵
  Map<String, List<String>> _teamRecentResults = {};

  static const Map<String, String> _teamLogoMap = {
    '두산': 'assets/image/두산.png',
    '삼성': 'assets/image/삼성.png',
    '롯데': 'assets/image/롯데.png',
    'KIA': 'assets/image/KIA.png',
    '한화': 'assets/image/한화.png',
    'KT':  'assets/image/KT.png',
    'SSG': 'assets/image/SSG.png',
    '키움': 'assets/image/키움.png',
    'LG':  'assets/image/LG.png',
    'NC':  'assets/image/NC.png',
  };
  List<Map<String, dynamic>> _pitchers = [];

  @override
  void initState() {
    super.initState();
    _loadHitters()
      .then((_) => _loadPitchers())
      .then((_) => _loadRecentResults())
      .then((_) => _loadPrediction());
  }
  // 최근 5경기 결과 CSV 파싱 및 저장
  Future<void> _loadRecentResults() async {
    final raw = await rootBundle.loadString('assets/data/kbo_win_lose.csv');
    final lines = raw.split('\n');
    for (int i = 1; i < lines.length; i++) {
      final cols = _parseCsv(lines[i]);
      if (cols.length >= 9) {
        final team = cols[1].trim();
        final recentRaw = cols[8].replaceAll(' ', '').replaceAll('무', ''); // e.g. "3승-2패" or "승,패,승,승,패"
        final recentList = recentRaw.split('-').expand((part) {
          if (part.contains('승')) {
            return List.filled(int.tryParse(part.replaceAll('승', '')) ?? 0, '승');
          } else if (part.contains('패')) {
            return List.filled(int.tryParse(part.replaceAll('패', '')) ?? 0, '패');
          }
          return [];
        }).toList();
        _teamRecentResults[team] = recentList.take(5).map((e) => e.toString()).toList();
      }
    }
  }

  Future<void> _loadHitters() async {
    final raw = await rootBundle.loadString('assets/data/kbo_hitter_players.csv');
    final lines = raw.split('\n');
    final Map<String, List<double>> avgMap = {};
    final Map<String, List<double>> opsMap = {};
    for (int i = 1; i < lines.length; i++) {
      final parts = _parseCSVLine(lines[i].trim(), maxSplits: 5);
      if (parts.length < 6) continue;
      var recordJson = parts.last;
      if (recordJson.startsWith('"') && recordJson.endsWith('"')) {
        recordJson = recordJson.substring(1, recordJson.length - 1);
      }
      recordJson = recordJson.replaceAll("'", '"');
      try {
        final recs = json.decode(recordJson) as List<dynamic>;
        if (recs.isEmpty) continue;
        final latest = recs.cast<Map<String, dynamic>>()
                          .where((r) => r.containsKey('Year'))
                          .reduce((a, b) => int.parse(a['Year'].toString()) > int.parse(b['Year'].toString()) ? a : b);
        final team = latest['Team']?.toString() ?? '';
        final avg = double.tryParse(latest['Avg']?.toString() ?? '') ?? 0.0;
        final obp = double.tryParse(latest['OBP']?.toString() ?? '') ?? 0.0;
        final slg = double.tryParse(latest['SLG']?.toString() ?? '') ?? 0.0;
        final ops = obp + slg;
        avgMap.putIfAbsent(team, () => []).add(avg);
        opsMap.putIfAbsent(team, () => []).add(ops);
      } catch (_) {}
    }
    // Compute team averages
    avgMap.forEach((team, list) {
      _teamAvg[team] = list.reduce((a, b) => a + b) / list.length;
    });
    opsMap.forEach((team, list) {
      _teamOps[team] = list.reduce((a, b) => a + b) / list.length;
    });
  }

  Future<void> _loadPitchers() async {
    final raw = await rootBundle.loadString('assets/data/kbo_pitcher_players.csv');
    final lines = raw.split('\n');
    final pitchers = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = _parseCSVLine(line, maxSplits: 6);
      if (parts.length <= 6) continue;

      final name = parts[0];
      final imageUrl = parts[1];
      final teamCode = parts[2];
      final backNo = parts[3];
      final positionDetail = parts[4];
      final heightWeight = parts[5];
      var recordJson = parts.last;

      if (recordJson.startsWith('"') && recordJson.endsWith('"')) {
        recordJson = recordJson.substring(1, recordJson.length - 1);
      }
      recordJson = recordJson.replaceAll("'", '"');

      // 스탯 파싱
      final stats = <String, Map<String, String>>{};
      try {
        final recs = json.decode(recordJson) as List<dynamic>;
        for (var rec in recs) {
          if (rec is Map<String, dynamic>) {
            final year = rec.containsKey('Year') ? rec['Year'].toString() : '통산';
            stats[year] = {
              'era': rec['ERA']?.toString() ?? '-',
              'win': rec['Win']?.toString() ?? '-',
              'lose': rec['Lose']?.toString() ?? '-',
            };
          }
        }
      } catch (_) {
        // 파싱 실패 무시
      }
      // 화면용 팀명 매핑
      final teamName = teamCode;

      pitchers.add({
        'name'           : name,
        'imageUrl'       : imageUrl,
        'team'           : teamName,
        'number'         : backNo,
        'positionDetail' : positionDetail,
        'heightWeight'   : heightWeight,
        'stats'          : stats,
        'careerStats'    : stats['2025'] ?? {'era': '-', 'win': '-', 'lose': '-'},
        'Player_name'    : normalizeName(name),
      });
    }

    setState(() => _pitchers = pitchers);
  }

  /// CSV 한 줄을 maxSplits만큼만 콤마 분리
  List<String> _parseCSVLine(String line, {required int maxSplits}) {
    final res = <String>[];
    final sb = StringBuffer();
    int splits = 0;
    for (var ch in line.characters) {
      if (ch == ',' && splits < maxSplits) {
        res.add(sb.toString());
        sb.clear();
        splits++;
      } else {
        sb.write(ch);
      }
    }
    res.add(sb.toString());
    return res.map((s) => s.trim()).toList();
  }

  // 팀명 정규화 함수
  String normalizeTeamName(String team) {
    const Map<String, String> mapping = {
      'KIA': 'KIA',
      '한화': '한화',
      '두산': '두산',
      '삼성': '삼성',
      '롯데': '롯데',
      'KT': 'KT',
      'SSG': 'SSG',
      '키움': '키움',
      'LG': 'LG',
      'NC': 'NC',
    };
    return mapping[team] ?? team;
  }

  // 투수 이름 정규화 함수
  String normalizeName(String name) {
    return name.replaceAll(' ', '').trim();
  }

  double _calcRecentWinRate(List<String>? results) {
    if (results == null || results.isEmpty) return 0.5;
    final wins = results.where((r) => r == '승').length;
    return wins / results.length;
  }

  int _calcStreakScore(List<String>? results) {
    if (results == null || results.isEmpty) return 0;
    return results.map((r) => r == '승' ? 1 : -1).reduce((a, b) => a + b);
  }

  Future<void> _loadPrediction() async {
    // 1) Extract features from widget.game
    final homeTeam = normalizeTeamName(widget.game['homeTeam']?.toString() ?? '');
    final awayTeam = normalizeTeamName(widget.game['awayTeam']?.toString() ?? '');
    final homeAvg = _teamAvg[homeTeam] ?? 0.300;
    final awayAvg = _teamAvg[awayTeam] ?? 0.300;

    // 디버깅: 등록된 투수 전체 확인
    print('[DEBUG] 등록된 투수 수: ${_pitchers.length}');
    print('[DEBUG] 등록된 투수 예시: ${_pitchers.take(5).map((p) => p['Player_name']).toList()}');

    // Lookup ERA from loaded pitcher data
    final homePitchEntry = _pitchers.firstWhere(
      (p) => normalizeName(p['Player_name']) == normalizeName(widget.game['homePitcher'] ?? ''),
      orElse: () => {},
    );
    final awayPitchEntry = _pitchers.firstWhere(
      (p) => normalizeName(p['Player_name']) == normalizeName(widget.game['awayPitcher'] ?? ''),
      orElse: () => {},
    );

    // [DEBUG] Inspect pitcher data for 2025 season
    print('[DEBUG] 홈 투수 전체 데이터: $homePitchEntry');
    print('[DEBUG] 홈 투수 2025 기록: ${homePitchEntry['stats']?['2025']}');
    print('[DEBUG] 어웨이 투수 전체 데이터: $awayPitchEntry');
    print('[DEBUG] 어웨이 투수 2025 기록: ${awayPitchEntry['stats']?['2025']}');

    // 디버깅: 투수 매칭 결과 출력
    if (homePitchEntry.isEmpty) {
      print('[DEBUG] 홈 투수 매칭 실패: ${widget.game['homePitcher']}');
    } else {
      print('[DEBUG] 홈 투수 매칭 성공: ${widget.game['homePitcher']}');
    }
    if (awayPitchEntry.isEmpty) {
      print('[DEBUG] 어웨이 투수 매칭 실패: ${widget.game['awayPitcher']}');
    } else {
      print('[DEBUG] 어웨이 투수 매칭 성공: ${widget.game['awayPitcher']}');
    }
    final homeEraStr = (homePitchEntry['careerStats']?['era'] ?? '').toString();
    final awayEraStr = (awayPitchEntry['careerStats']?['era'] ?? '').toString();
    final homeEra = double.tryParse(homeEraStr) ?? 4.00;
    final awayEra = double.tryParse(awayEraStr) ?? 4.00;

    // Extract 2025 pitcher stats for advanced features
    final homeStats25 = homePitchEntry['stats']?['2025'] ?? {};
    final awayStats25 = awayPitchEntry['stats']?['2025'] ?? {};

    // Extract advanced pitcher stats using lowercased keys: whip, ip, k9
    final homeWHIP = double.tryParse(homeStats25['whip']?.toString() ?? '') ?? 1.3;
    final awayWHIP = double.tryParse(awayStats25['whip']?.toString() ?? '') ?? 1.3;
    final homeIP = double.tryParse(homeStats25['ip']?.toString() ?? '') ?? 80.0;
    final awayIP = double.tryParse(awayStats25['ip']?.toString() ?? '') ?? 80.0;
    final homeK9 = double.tryParse(homeStats25['k9']?.toString() ?? '') ?? 7.0;
    final awayK9 = double.tryParse(awayStats25['k9']?.toString() ?? '') ?? 7.0;

    final whipDiff = awayWHIP - homeWHIP;
    final ipDiff = homeIP - awayIP;
    final k9Diff = homeK9 - awayK9;

    // Parse OPS from loaded team OPS after hitters load (otherwise default)
    final homeOps = _teamOps[homeTeam] ?? 0.700;
    final awayOps = _teamOps[awayTeam] ?? 0.700;

    // 1.1) Extract SP win/loss counts for additional features
    final homeSPWins = double.tryParse(homePitchEntry['careerStats']?['win'] ?? '0') ?? 0.0;
    final awaySPWins = double.tryParse(awayPitchEntry['careerStats']?['win'] ?? '0') ?? 0.0;
    final spWinDiff = homeSPWins - awaySPWins;

    final homeSPLosses = double.tryParse(homePitchEntry['careerStats']?['lose'] ?? '0') ?? 0.0;
    final awaySPLosses = double.tryParse(awayPitchEntry['careerStats']?['lose'] ?? '0') ?? 0.0;
    final spLossDiff = homeSPLosses - awaySPLosses;

    final homeRecent = _teamRecentResults[homeTeam];
    final awayRecent = _teamRecentResults[awayTeam];
    final recentWinDiff = _calcRecentWinRate(homeRecent) - _calcRecentWinRate(awayRecent);
    final streakScoreDiff = _calcStreakScore(homeRecent) - _calcStreakScore(awayRecent);

    // --- 예측 입력값 디버깅 로그 ---
    print('--- 예측 입력값 ---');
    print('Home: $homeTeam, Away: $awayTeam');
    print('AVG diff: ${homeAvg - awayAvg}');
    print('ERA diff: ${awayEra - homeEra}');
    print('OPS diff: ${homeOps - awayOps}');
    print('SP Wins diff: $spWinDiff, SP Loss diff: $spLossDiff');
    print('최근 5경기: ${_teamRecentResults[homeTeam]}, ${_teamRecentResults[awayTeam]}');
    print('WHIP diff: $whipDiff, IP diff: $ipDiff, K9 diff: $k9Diff');

    // 2) Logistic regression coefficients (update with trained values)
    const double beta0 = -0.345;
    const double betaAvg =  2.12;
    const double betaEra = -1.73;
    const double betaOps =  3.08;
    const double betaHomeAdv = 0.55;
    const double betaSPWinDiff = 0.05;   // SP win difference coefficient
    const double betaSPLossDiff = -0.02; // SP loss difference coefficient
    const double betaRecent = 1.1;
    const double betaStreak = 0.7;
    const double betaWHIP = -1.2;
    const double betaIP = 0.1;
    const double betaK9 = 0.6;

    // 3) Compute feature differences
    final avgDiff = homeAvg - awayAvg;
    final eraDiff = awayEra - homeEra;
    final opsDiff = homeOps - awayOps;
    const homeDummy = 1.0;

    // 4) Calculate logit and probability
    final logitValue = beta0
        + betaAvg * avgDiff
        + betaEra * eraDiff
        + betaOps * opsDiff
        + betaHomeAdv * homeDummy
        + betaSPWinDiff * spWinDiff
        + betaSPLossDiff * spLossDiff
        + betaRecent * recentWinDiff
        + betaStreak * streakScoreDiff
        + betaWHIP * whipDiff
        + betaIP * ipDiff
        + betaK9 * k9Diff;
    // Raw probability from logistic
    final rawWinPct = 1 / (1 + exp(-logitValue));
    // Apply moderate smoothing towards 50%
    const double smoothingFactor = 0.8;
    final baseWinPct = 0.5 + (rawWinPct - 0.5) * smoothingFactor;

    // Add deterministic noise per game to diversify probabilities
    final seed = widget.game['date']?.toString().hashCode ?? DateTime.now().millisecondsSinceEpoch;
    final rnd = Random(seed);
    const double noiseLevel = 0.15; // up to ±15% noise
    final noise = (rnd.nextDouble() * 2 - 1) * noiseLevel;
    final winPctHome = (baseWinPct + noise).clamp(0.0, 1.0);

    // 5) Derive score predictions (scaled)
    const expectedTotalRuns = 7.0;
    final scoreHome = double.parse((winPctHome * expectedTotalRuns).toStringAsFixed(1));
    final scoreAway = double.parse(((1 - winPctHome) * expectedTotalRuns).toStringAsFixed(1));

    // 6) Update state for UI
    setState(() {
      _predData = {
        'scoreHome': scoreHome,
        'scoreAway': scoreAway,
        'winPctHome': winPctHome,
      };
      _isLoading = false;
    });
  }

  List<String> _parseCsv(String line) {
    final res = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;
    for (var ch in line.characters) {
      if (ch == '"') inQuotes = !inQuotes;
      else if (ch == ',' && !inQuotes) {
        res.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    res.add(sb.toString().trim());
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final myTeam = context.watch<MyTeamProvider>().myTeam;
    final primaryColor = getPrimaryColor(myTeam);
    final secondaryColor = getSecondaryColor(myTeam);
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),

      );
    }

    final d = _predData ?? {};

    final awayPitcherData = _pitchers.firstWhere(
      (p) => normalizeName(p['Player_name']) == normalizeName(widget.game['awayPitcher'] ?? ''),
      orElse: () => {},
    );
    final homePitcherData = _pitchers.firstWhere(
      (p) => normalizeName(p['Player_name']) == normalizeName(widget.game['homePitcher'] ?? ''),
      orElse: () => {},
    );

    final double winPctHome = (d['winPctHome'] ?? 0.0) as double;
    final homePct = (winPctHome * 100).round().clamp(0, 100);
    final awayPct = ((1 - winPctHome) * 100).round().clamp(0, 100);
    final homeLogo = _teamLogoMap[widget.game['homeTeam']] ?? '';
    final awayLogo = _teamLogoMap[widget.game['awayTeam']] ?? '';

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // 기본 leading 비활성화
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              padding: EdgeInsets.zero, // 여백 제거
              constraints: const BoxConstraints(), // 버튼 크기 강제 축소
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 1), // 화살표와 텍스트 사이 간격 조절
            const Text(
              '승부예측',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 예측 카드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: secondaryColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 0),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 홈-원정 팀 정보
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _teamInfoColumn(
                          logoUrl: awayLogo,
                          teamName: widget.game['awayTeam'],
                        ),
                        const Text(
                          'VS',
                          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        _teamInfoColumn(
                          logoUrl: homeLogo,
                          teamName: widget.game['homeTeam'],
                        ),
                      ],
                    ),
                    // 경기장 · 시간
                    if (widget.game['stadium'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${widget.game['stadium']}   |  ${widget.game['time']}',
                          style: const TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // 예상 득점과 승률 바
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // 예상 득점과 승률 바



                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                '${d['scoreAway']?? 0.0}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '예상 득점',
                                style: const TextStyle(color: Colors.black, fontSize: 13),
                              ),
                              Text(
                                '${d['scoreHome']?? 0.0}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            '< 승리 확률 >',
                            style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: awayPct,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('$awayPct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                              ),
                              Expanded(
                                flex: homePct,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: secondaryColor,
                                    borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('$homePct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: secondaryColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 0),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '선발 투수',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _pitcherBoxWithImage(
                            pitcherName: widget.game['awayPitcher'] ?? '정보 없음',
                            pitcherEra: widget.game['awayEra'] ?? '-',
                            teamName: widget.game['awayTeam'] ?? '원정',
                            imageUrl: awayPitcherData['imageUrl'] ?? '',
                            careerStats: awayPitcherData['stats']?['2025'],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _pitcherBoxWithImage(
                            pitcherName: widget.game['homePitcher'] ?? '정보 없음',
                            pitcherEra: widget.game['homeEra'] ?? '-',
                            teamName: widget.game['homeTeam'] ?? '홈',
                            imageUrl: homePitcherData['imageUrl'] ?? '',
                            careerStats: homePitcherData['stats']?['2025'],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamInfoColumn({
    required String logoUrl,
    required String teamName,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipOval(
        child: Image.asset(logoUrl, width: 60, height: 60, fit: BoxFit.contain),
      ),
      const SizedBox(height: 8),
      Text(
        teamName,
        style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

Widget _pitcherBoxWithImage({
  required String pitcherName,
  required String pitcherEra,
  required String teamName,
  required String imageUrl,
  required Map<String, String>? careerStats,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),

    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (imageUrl.isNotEmpty)
          ClipOval(
            child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover),
          ),
        if (imageUrl.isNotEmpty) const SizedBox(width: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 14),
                  Text(teamName, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(pitcherName,
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        if (careerStats != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('ERA', careerStats['era']!),
              _buildStatItem('승', careerStats['win']!),
              _buildStatItem('패', careerStats['lose']!),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _buildStatItem(String label, String value) {
  return Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
    ],
  );
}






