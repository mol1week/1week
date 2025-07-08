// lib/screens/my_team_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'schedule_screen.dart';
import 'player_screen.dart';

/// MyTeamScreen:
/// - 앱 처음 실행 시 로고 그리드로 마이팀을 선택·저장할 수 있습니다.
/// - 이후 선택된 팀의 로고, 오늘/앞으로 경기, 우리 팀 선수 보기 기능을 제공합니다.
class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({Key? key}) : super(key: key);

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  // CSV raw 값 → 화면용 팀명 매핑
  static const Map<String, String> _rawToDisplay = {
    'KIA': 'KIA 타이거즈', 'HT': 'KIA 타이거즈',
    '롯데': '롯데 자이언츠', 'LT': '롯데 자이언츠',
    '삼성': '삼성 라이온즈', 'SS': '삼성 라이온즈',
    '두산': '두산 베어스', 'OB': '두산 베어스',
    'LG': 'LG 트윈스',
    '한화': '한화 이글스', 'HH': '한화 이글스',
    'KT': 'KT 위즈',
    'NC': 'NC 다이노스',
    '키움': '키움 히어로즈', 'WO': '키움 히어로즈',
    'SSG': 'SSG 랜더스', 'SK': 'SSG 랜더스',
  };

  final Map<String, String> _displayToCsvTeam = {
    'KIA 타이거즈': 'KIA',
    '롯데 자이언츠': '롯데',
    '삼성 라이온즈': '삼성',
    '두산 베어스': '두산',
    'LG 트윈스': 'LG',
    '한화 이글스': '한화',
    'KT 위즈': 'KT',
    'NC 다이노스': 'NC',
    '키움 히어로즈': '키움',
    'SSG 랜더스': 'SSG',
  };

  // 화면용 팀명 → 로고 파일명 코드
  static const Map<String, String> _displayToCode = {
    'KIA 타이거즈': 'HT',
    '롯데 자이언츠': 'LT',
    '삼성 라이온즈': 'SS',
    '두산 베어스': 'OB',
    'LG 트윈스': 'LG',
    '한화 이글스': 'HH',
    'KT 위즈': 'KT',
    'NC 다이노스': 'NC',
    '키움 히어로즈': 'WO',
    'SSG 랜더스': 'SK',
  };

  // 화면에 보여줄 팀 목록 (중복 제거 후 정렬)
  late final List<String> _allTeams =
  _rawToDisplay.values.toSet().toList()..sort();

  String? _selectedTeam;
  List<Map<String, dynamic>> _allGames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  /// 1) 스케줄 CSV 로드
  /// 2) SharedPreferences에서 저장된 myTeam 불러오기
  /// 3) _loading=false
  Future<void> _initData() async {
    await Future.wait([
      _loadSchedule(),
      _loadRankings(),
    ]);
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('myTeam');
    if (mounted) {
      setState(() {
        _selectedTeam = saved;
        _loading = false;
      });
    }
  }

  /// 선택한 마이팀 저장
  Future<void> _saveTeam(String team) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myTeam', team);
    setState(() => _selectedTeam = team);
  }

  /// assets/data/kbo_games.csv 를 읽어서 _allGames에 채워넣기
  Future<void> _loadSchedule() async {
    final raw = await rootBundle.loadString('assets/data/kbo_games.csv');
    final lines = raw.split('\n');
    final games = <Map<String, dynamic>>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = _parseCsv(line);
      if (parts.length < 6) continue;
      final ds = parts[0];
      if (ds.length < 8) continue;
      final y = int.tryParse(ds.substring(0, 4));
      final m = int.tryParse(ds.substring(4, 6));
      final d = int.tryParse(ds.substring(6, 8));
      if (y == null || m == null || d == null) continue;
      final date = DateTime(y, m, d);
      final home = _rawToDisplay[parts[4]] ?? parts[4];
      final away = _rawToDisplay[parts[5]] ?? parts[5];
      games.add({
        'date': date,
        'stadium': parts[1],
        'status': parts[2],
        'time': parts[3],
        'home': home,
        'away': away,
      });
    }
    _allGames = games;
  }

  /// 단순 CSV 파싱 (따옴표 내부 콤마 무시)
  List<String> _parseCsv(String line) {
    final res = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;
    for (var c in line.characters) {
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        res.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(c);
      }
    }
    res.add(sb.toString().trim());
    return res;
  }

  List<Map<String, String>> _rankings = [];

  Future<void> _loadRankings() async {
    final raw = await rootBundle.loadString('assets/data/kbo_win_lose.csv');
    final lines = raw.split('\n');
    final headers = lines.first.split(',');

    final list = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final values = line.split(',');
      if (values.length != headers.length) continue;

      final teamData = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        teamData[headers[j]] = values[j];
      }
      list.add(teamData);
    }

    setState(() {
      _rankings = list;
    });
  }


  Map<String, String>? get _myTeamRanking {
    if (_selectedTeam == null) return null;
    final csvName = _displayToCsvTeam[_selectedTeam!];
    if (csvName == null) return null;

    return _rankings.firstWhere(
          (row) => row['팀명']?.trim() == csvName,
      orElse: () => {},
    );
  }


  /// 오늘의 경기 리스트
  List<Map<String, dynamic>> get _todayGames {
    if (_selectedTeam == null) return [];
    final now = DateTime.now();
    return _allGames.where((g) {
      final d = g['date'] as DateTime;
      return d.year == now.year &&
          d.month == now.month &&
          d.day == now.day &&
          (g['home'] == _selectedTeam || g['away'] == _selectedTeam);
    }).toList();
  }

  /// 향후 7일 경기 리스트
  List<Map<String, dynamic>> get _upcomingGames {
    if (_selectedTeam == null) return [];
    final now = DateTime.now();
    final end = now.add(const Duration(days: 7));
    return _allGames.where((g) {
      final d = g['date'] as DateTime;
      return d.isAfter(now) &&
          d.isBefore(end) &&
          (g['home'] == _selectedTeam || g['away'] == _selectedTeam);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _selectedTeam != null
            ? Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundImage: NetworkImage(
              'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/'
                  'emblem_${_displayToCode[_selectedTeam!]}.png',
            ),
          ),
        )
            : null,
        title: Text(
          _selectedTeam ?? '마이 팀 설정',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedTeam != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () => setState(() => _selectedTeam = null),
            ),
        ],
      ),
      body: _selectedTeam == null ? _buildPicker() : _buildDashboard(),
    );
  }

  /// 로고 그리드로 마이팀을 선택하는 화면
  Widget _buildPicker() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('마이 팀을 선택하세요',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _allTeams.map((team) {
                final code = _displayToCode[team]!;
                final isSelected = _selectedTeam == team;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedTeam = team);
                    // Scroll to bottom or show 저장 버튼 clearly, optionally
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 3 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.network(
                            'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/'
                                'emblem_${code}.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(team,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedTeam == null
                  ? null
                  : () async {
                      await _saveTeam(_selectedTeam!);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MyTeamScreen()),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }

  /// 대시보드: 오늘의 경기, 앞으로의 경기, 우리 팀 선수 보기
  Widget _buildDashboard() => SingleChildScrollView(

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_myTeamRanking != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '우리 팀 순위',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_myTeamRanking!['순위']}위 ${_myTeamRanking!['팀명']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '승률: ${_myTeamRanking!['승률']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '전적: ${_myTeamRanking!['승']}승-${_myTeamRanking!['무']}무-${_myTeamRanking!['패']}패',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '게임차: ${_myTeamRanking!['게임차']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '연속: ${_myTeamRanking!['연속']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '최근 10경기: ${_myTeamRanking!['최근10경기']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),


        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('오늘의 경기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: _todayGames.isEmpty
              ? const Center(
            child: Text(
              '오늘 경기가 없습니다.',
              style: TextStyle(color: Colors.grey),
            ),
          )
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            // give equal horizontal padding so first/last items sit in the center
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.1,
            ),
            itemCount: _todayGames.length,
            itemBuilder: (ctx, i) {
              final g = _todayGames[i];
              final hc = _displayToCode[g['home']]!;
              final ac = _displayToCode[g['away']]!;

              // each item is now centered within its "slot"
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    ClipOval(
                                      child: Image.network(
                                        'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/'
                                            'emblem_${hc}.png',
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      g['home'],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'VS',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                Column(
                                  children: [
                                    ClipOval(
                                      child: Image.network(
                                        'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/'
                                            'emblem_${ac}.png',
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      g['away'],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  g['time'],
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  g['status'],
                                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('앞으로의 경기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        // 앞으로의 경기 리스트
        ..._upcomingGames.map((g) {
          final hc = _displayToCode[g['home']]!;
          final ac = _displayToCode[g['away']]!;
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/'
                    'emblem_${hc}.png',
              ),
            ),
            title: Text('${g['home']} vs ${g['away']}'),
            subtitle:
            Text('${g['date'].month}.${g['date'].day} ${g['time']}'),
            trailing: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/'
                    'emblem_${ac}.png',
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(filterTeam: _selectedTeam!),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,    // 버튼 배경색
              foregroundColor: Colors.white,   // 버튼 텍스트(및 아이콘) 색
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('우리 팀 선수 보기'),
          ),
        ),

        const SizedBox(height: 16),
      ],
    ),
  );
}
