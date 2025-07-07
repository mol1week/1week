import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    try {
      final raw = await rootBundle.loadString('assets/data/kbo_predictions.csv');
      final lines = raw.split('\n');
      for (int i = 1; i < lines.length; i++) {
        final parts = _parseCsv(lines[i]);
        print('CSV Line $i: $parts');
        if (parts.length < 4) continue;
        final gameDate = widget.game['date'] is DateTime
            ? (widget.game['date'] as DateTime).toIso8601String().split('T').first
            : widget.game['date']?.toString() ?? '';
        if (gameDate.contains(parts[0]) &&
            parts[1] == widget.game['homeTeam'] &&
            parts[2] == widget.game['awayTeam']) {
          setState(() {
            _predData = {
              'winPctHome': double.tryParse(parts[3]) ?? 0.0,
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final d = _predData ?? {};
    final double winPctHome = (d['winPctHome'] ?? 0.0) as double;
    final homePct = (winPctHome * 100).round().clamp(0, 100);
    final awayPct = ((1 - winPctHome) * 100).round().clamp(0, 100);
    final homeLogo = _teamLogoMap[widget.game['homeTeam']] ?? '';
    final awayLogo = _teamLogoMap[widget.game['awayTeam']] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 경기장 · 시간
            if (widget.game['stadium'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${widget.game['stadium']}   |  ${widget.game['time']}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            // 예측 카드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(height: 24),
                    // 예상 득점과 승률 바
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                '예상 득점: 4.5', // TODO: 데이터 연동
                                style: const TextStyle(color: Colors.black, fontSize: 14),
                              ),
                              Text(
                                '예상 득점: 5.6', // TODO: 데이터 연동
                                style: const TextStyle(color: Colors.black, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: homePct,
                                child: Container(
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('$homePct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              Expanded(
                                flex: awayPct,
                                child: Container(
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('$awayPct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
            const SizedBox(height: 16),
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
        child: Image.network(logoUrl, width: 60, height: 60, fit: BoxFit.cover),
      ),
      const SizedBox(height: 8),
      Text(
        teamName,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
