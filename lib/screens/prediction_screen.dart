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

  // 팀명 → 로고 URL
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
    // 경기 예정/진행 중인 경우 CSV에서 불러오기
    try {
      final raw = await rootBundle.loadString('assets/data/kbo_predictions.csv');
      final lines = raw.split('\n');
      for (int i = 1; i < lines.length; i++) {
        final parts = _parseCsv(lines[i]);
        if (parts.length < 13) continue;
        if (parts[1] == widget.game['homeTeam'] && parts[2] == widget.game['awayTeam']) {
          setState(() {
            _predData = {
              'winPctHome': double.tryParse(parts[3]) ?? 0.0,
              'winPctAway': double.tryParse(parts[4]) ?? 0.0,
              'homeKey': parts[5],
              'homeAvg': parts[6],
              'homeHits': parts[7],
              'homeHr': parts[8],
              'awayKey': parts[9],
              'awayAvg': parts[10],
              'awayHits': parts[11],
              'awayHr': parts[12],
            };
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // 무시
    }
    // 매칭 실패 시
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
    final homePct = ((d['winPctHome'] ?? 0.0) * 100).round().clamp(0, 100);
    final awayPct = ((d['winPctAway'] ?? 0.0) * 100).round().clamp(0, 100);
    final homeLogo = _teamLogoMap[widget.game['homeTeam']] ?? '';
    final awayLogo = _teamLogoMap[widget.game['awayTeam']] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${widget.game['homeTeam']} vs ${widget.game['awayTeam']}',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 경기장·시간
            if (widget.game['stadium'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${widget.game['stadium']} · ${widget.game['time']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 8),
            // 로고·팀명
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _teamColumn(awayLogo, widget.game['awayTeam']),
                const Text('VS', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                _teamColumn(homeLogo, widget.game['homeTeam']),
              ],
            ),
            const SizedBox(height: 16),
            // 승률 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: homePct,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                        ),
                        alignment: Alignment.center,
                        child: Text('$homePct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(
                      flex: awayPct,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
                        ),
                        alignment: Alignment.center,
                        child: Text('$awayPct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 키 플레이어
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _playerStat(d['homeKey'] ?? '', d['homeAvg'] ?? '', d['homeHits'] ?? '', d['homeHr'] ?? '', Colors.blue),
                  const SizedBox(width: 16),
                  _playerStat(d['awayKey'] ?? '', d['awayAvg'] ?? '', d['awayHits'] ?? '', d['awayHr'] ?? '', Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _teamColumn(String logoUrl, String name) => Column(
    children: [
      ClipOval(
        child: Image.network(logoUrl, width: 60, height: 60, fit: BoxFit.cover),
      ),
      const SizedBox(height: 8),
      Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _playerStat(String name, String avg, String hits, String hr, Color bg) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: bg,
                child: Text(name.isNotEmpty ? name[0] : '', style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 8),
              Text('AVG \$avg', style: const TextStyle(fontSize: 12)),
              Text('H \$hits', style: const TextStyle(fontSize: 12)),
              Text('HR \$hr', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
}
