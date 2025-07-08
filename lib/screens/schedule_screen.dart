// lib/screens/schedule_screen.dart


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'prediction_screen.dart';
import 'package:provider/provider.dart';
import '../providers/my_team_provider.dart';


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
        _selectedDate = DateTime.now();
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
    final myTeam = context.watch<MyTeamProvider>().myTeam;
    final primaryColor = getPrimaryColor(myTeam);
    final secondaryColor = getSecondaryColor(myTeam);
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.sports_baseball, color: primaryColor),
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
          Container(
            color: primaryColor,
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽: 이전 날짜 버튼
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () => setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  }),
                ),

                // 가운데: 날짜 + 요일 + 달력 버튼
                GestureDetector(
                  onTap: () async {
                    DateTime? pickedDate;
                    await showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Date Picker',
                      barrierColor: Colors.transparent,
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return Center(
                          child: Material(
                            color: Colors.transparent,
                            child: Localizations.override(
                              context: context,
                              locale: const Locale('ko'),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: primaryColor,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                  datePickerTheme: const DatePickerThemeData(
                                    backgroundColor: Colors.white,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                  textTheme: Theme.of(context).textTheme.copyWith(
                                    titleLarge: const TextStyle(
                                      fontSize: 10, // 👈 상단 날짜 텍스트 크기 줄이기
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                    bodyMedium: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                child: DatePickerDialog(
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2026),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          _selectedDate = value as DateTime;
                        });
                      }
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Builder(builder: (context) {
                        final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                        final weekdayStr = weekdays[_selectedDate.weekday - 1];
                        return Text(
                          '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')} ($weekdayStr)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today, size: 20, color: Colors.white),
                    ],
                  ),
                ),

                // 오른쪽: 다음 날짜 버튼
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
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
              child: Text('해당일 경기 정보가 없습니다.', style: TextStyle(color: Colors.white)),
            )
                : ListView.builder(
              itemCount: _filteredGames.length,
              itemBuilder: (ctx, i) {
                final g = _filteredGames[i];
                final homeLogo = _teamLogoMap[g['homeTeam']]!;
                final awayLogo = _teamLogoMap[g['awayTeam']]!;
                final finished = g['status'] == '경기종료';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: secondaryColor,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 0),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 상단: 경기장명 | 시간
                        Text('${g['stadium']}    |    ${g['time']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 15),

                        // 경기 상태 표시
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            g['status'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // 로고 + VS + 로고
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(_teamLogoMap[g['awayTeam']]!, width: 70, height: 70),
                            const SizedBox(width: 35),
                            const Text('VS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 35),
                            Image.asset(_teamLogoMap[g['homeTeam']]!, width: 70, height: 70),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // 경기종료: 점수 & 승/세/패 투수 정보
                        if (g['status'] == '경기종료') ...[
                          Builder(builder: (context) {
                            final homeScore = int.tryParse(g['homeScore'] ?? '0') ?? 0;
                            final awayScore = int.tryParse(g['awayScore'] ?? '0') ?? 0;
                            final isDraw = homeScore == awayScore; // 무승부 여부
                            final homeWin = homeScore > awayScore;
                            final savePitcher = g['savePitcher']?.toString() ?? '';

                            return Column(
                              children: [
                                // 점수는 한 Row로 평행하게 고정
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$awayScore',
                                      style: TextStyle(
                                        color: isDraw ? Colors.black : (!homeWin ? Colors.red : Colors.black),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 150),
                                    Text(
                                      '$homeScore',
                                      style: TextStyle(
                                        color: isDraw ? Colors.black : (homeWin ? Colors.red : Colors.black),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // 무승부가 아니면 승/세/패 투수 정보 표시
                                if (!isDraw)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 어웨이팀 투수 정보
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (!homeWin) ...[
                                            Row(
                                              children: [
                                                Text('승 ', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text('${g['winPitcher']}', style: const TextStyle(color: Colors.black, fontSize: 13)),
                                              ],
                                            ),
                                            if (savePitcher.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text('세 ', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                                  Text(savePitcher, style: const TextStyle(color: Colors.black, fontSize: 13)),
                                                ],
                                              ),
                                            ],
                                          ] else
                                            Row(
                                              children: [
                                                Text('패 ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text('${g['losePitcher']}', style: const TextStyle(color: Colors.black, fontSize: 13)),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 120),
                                      // 홈팀 투수 정보
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (homeWin) ...[
                                            Row(
                                              children: [
                                                Text('승 ', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text('${g['winPitcher']}', style: const TextStyle(color: Colors.black, fontSize: 13)),
                                              ],
                                            ),
                                            if (savePitcher.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text('세 ', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                                  Text(savePitcher, style: const TextStyle(color: Colors.black, fontSize: 13)),
                                                ],
                                              ),
                                            ],
                                          ] else
                                            Row(
                                              children: [
                                                Text('패 ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text('${g['losePitcher']}', style: const TextStyle(color: Colors.black, fontSize: 13)),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            );
                          }),
                        ],

                        // 경기예정: 선발투수 & 예측보기 버튼
                        if (g['status'] == '경기예정') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(g['awayPitcher'], style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 35),
                              const Text('선발투수', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(width: 35),
                              Text(g['homePitcher'], style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if ((g['homePitcher']?.toString().isNotEmpty ?? false) && (g['awayPitcher']?.toString().isNotEmpty ?? false))
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PredictionScreen(game: g)),
                              ),
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return primaryColor;
                                  } else if (states.contains(MaterialState.hovered)) {
                                    return Colors.grey.shade800;
                                  }
                                  return secondaryColor;
                                }),
                                minimumSize: MaterialStateProperty.all(const Size.fromHeight(36)),
                                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              child: const Text('예측 보기', style: TextStyle(color: Colors.white, fontSize: 14)),
                            ),
                        ],
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
