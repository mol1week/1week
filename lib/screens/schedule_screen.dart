// lib/screens/schedule_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'prediction_screen.dart';

/// ScheduleScreen:
/// - assets/data/kbo_games.csv 파일에서 KBO 리그 경기일정을 로드합니다.
/// - “경기종료”된 게임은 스코어와 승·세·패 투수를 표시하고,
///   그 외(예정/취소)는 ‘선발투수’ 레이블과 투수 이름만 보여줍니다.
/// - 각 게임에 “예측 보기” 버튼을 누르면 PredictionScreen으로 이동합니다.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _games = [];
  bool _isLoading = true;

  /// 팀명 → 로고 이미지 URL 맵
  static const Map<String, String> _teamLogoMap = {
    '두산': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_OB.png',
    '삼성': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_SS.png',
    '롯데': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_LT.png',
    'KIA':  'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_HT.png',
    '한화': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_HH.png',
    'KT':   'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_KT.png',
    'SSG':  'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_SK.png',
    '키움': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_WO.png',
    'LG':   'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_LG.png',
    'NC':   'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_NC.png',
  };

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  /// CSV를 읽어와 각 경기 정보를 파싱 후 _games에 저장
  Future<void> _loadSchedule() async {
    final raw = await rootBundle.loadString('assets/data/kbo_games.csv');
    final lines = raw.split('\n');
    final List<Map<String, dynamic>> loaded = [];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = _parseCsv(line);
      // 최소 13개 컬럼 필요 (GameDate,…,HomeScore,AwayScore,…Win,Save,Lose)
      if (parts.length < 13) continue;

      // 날짜 파싱 (YYYYMMDD)
      late DateTime date;
      try {
        final gd = parts[0];
        date = DateTime(
          int.parse(gd.substring(0, 4)),
          int.parse(gd.substring(4, 6)),
          int.parse(gd.substring(6, 8)),
        );
      } catch (_) {
        continue;
      }

      loaded.add({
        'date'        : date,
        'stadium'     : parts[1],  // 경기장
        'status'      : parts[2],  // 경기종료, 경기예정 등
        'time'        : parts[3],  // 시작 시간
        'homeTeam'    : parts[4],
        'awayTeam'    : parts[5],
        'homeScore'   : parts[6],  // 홈 득점
        'awayScore'   : parts[7],  // 원정 득점
        'homePitcher' : parts[8],  // 홈 선발 투수
        'awayPitcher' : parts[9],  // 원정 선발 투수
        'winPitcher'  : parts[10], // 승리 투수
        'savePitcher' : parts[11], // 세이브 투수 (빈 문자열 가능)
        'losePitcher' : parts[12], // 패전 투수
      });
    }

    setState(() {
      _games = loaded;
      if (_games.isNotEmpty) {
        _selectedDate = _games.first['date'] as DateTime;
      }
      _isLoading = false;
    });
  }

  /// 큰따옴표 안의 콤마를 무시하고 split
  List<String> _parseCsv(String line) {
    final res = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;
    for (var ch in line.characters) {
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        res.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    res.add(sb.toString().trim());
    return res;
  }

  /// 선택된 날짜의 경기만 반환
  List<Map<String, dynamic>> get _filteredGames {
    return _games.where((g) {
      final d = g['date'] as DateTime;
      return d.year == _selectedDate.year
          && d.month == _selectedDate.month
          && d.day == _selectedDate.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.sports_baseball, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              '경기일정/결과',
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 날짜 네비게이션 바
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  }),
                ),
                Row(
                  children: [
                    Text(
                      '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  }),
                ),
              ],
            ),
          ),

          // 경기 리스트
          Expanded(
            child: _filteredGames.isEmpty
                ? const Center(
              child: Text('해당일 경기 정보가 없습니다.', style: TextStyle(color: Colors.grey)),
            )
                : ListView.builder(
              itemCount: _filteredGames.length,
              itemBuilder: (ctx, i) {
                final g = _filteredGames[i];
                final homeLogo = _teamLogoMap[g['homeTeam']]!;
                final awayLogo = _teamLogoMap[g['awayTeam']]!;
                final finished = g['status'] == '경기종료';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 3)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 경기 상태
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                          child: Text(
                            g['status'],
                            style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 로고 · 팀명 · 시간 · 경기장
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Image.network(awayLogo, width: 40, height: 40),
                                const SizedBox(height: 4),
                                Text(g['awayTeam'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text(g['time'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text(g['stadium'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            Column(
                              children: [
                                Image.network(homeLogo, width: 40, height: 40),
                                const SizedBox(height: 4),
                                Text(g['homeTeam'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 경기종료: 스코어 + 승·세·패 투수 / 예정: 선발투수
                        if (finished) ...[
                          // 스코어
                          Text(
                            '${g['homeScore']} : ${g['awayScore']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          // 승·세·패 투수
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text('승: ${g['winPitcher']}'),
                              if ((g['savePitcher'] as String).isNotEmpty)
                                Text('세: ${g['savePitcher']}'),
                              Text('패: ${g['losePitcher']}'),
                            ],
                          ),
                        ] else ...[
                          // 선발투수
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(g['awayPitcher'], style: const TextStyle(fontSize: 12)),
                              const Text('선발투수', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(g['homePitcher'], style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),
                        // 예측 보기 버튼
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PredictionScreen(game: g)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('예측 보기', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
