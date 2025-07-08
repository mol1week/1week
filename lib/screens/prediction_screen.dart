import 'dart:convert';
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

  static const Map<String, String> _teamLogoMap = {
    '삼성': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_SS.png',
    '한화': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_HH.png',
    '롯데': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_LT.png',
    'KIA' : 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_HT.png',
    '키움': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_WO.png',
    'SSG' : 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_SK.png',
    'LG'  : 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_LG.png',
    'KT'  : 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_KT.png',
    'NC'  : 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_NC.png',
    '두산': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_OB.png',
  };
  List<Map<String, dynamic>> _pitchers = [];
  @override
  void initState() {
    super.initState();
    _loadPitchers().then((_) => _loadPrediction());
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

  Future<void> _loadPrediction() async {
    try {
      final raw = await rootBundle.loadString('assets/data/kbo_predictions.csv');
      final lines = raw.split('\n');
      for (int i = 1; i < lines.length; i++) {
        final parts = _parseCsv(lines[i]);
        print('CSV Line $i: $parts');
        if (parts.length < 6) continue;
        final gameDate = widget.game['date'] is DateTime
            ? (widget.game['date'] as DateTime).toIso8601String().split('T').first
            : widget.game['date']?.toString() ?? '';
        if (gameDate.contains(parts[0]) &&
            parts[1] == widget.game['homeTeam'] &&
            parts[2] == widget.game['awayTeam']) {
          setState(() {
            _predData = {
              'scoreHome': double.tryParse(parts[3]) ?? 0.0,
              'scoreAway':double.tryParse(parts[4]) ?? 0.0,
              'winPctHome': double.tryParse(parts[5]) ?? 0.0,
            };
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading CSV: $e');
    }
    setState(() => _isLoading = false);
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
          (p) => p['name'] == widget.game['awayPitcher'],
      orElse: () => {},
    );
    final homePitcherData = _pitchers.firstWhere(
          (p) => p['name'] == widget.game['homePitcher'],
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
                            '승리 확률',
                            style: const TextStyle(color: Colors.black, fontSize: 15),
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
        child: Image.network(logoUrl, width: 60, height: 60, fit: BoxFit.contain),
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



