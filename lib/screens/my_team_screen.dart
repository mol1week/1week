import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/my_team_provider.dart';
import 'player_screen.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({Key? key}) : super(key: key);

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
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

  late final List<String> _allTeams = _rawToDisplay.values.toSet().toList()..sort();
  String? _selectedTeam;
  List<Map<String, dynamic>> _allGames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule().then((_) {
      setState(() => _loading = false);
    });
  }

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

  List<Map<String, dynamic>> _getGamesFor(String team, DateTimeRange range) {
    return _allGames.where((g) {
      final d = g['date'] as DateTime;
      return d.isAfter(range.start) &&
          d.isBefore(range.end) &&
          (g['home'] == team || g['away'] == team);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final myTeamProvider = context.watch<MyTeamProvider>();
    final selectedTeam = myTeamProvider.myTeam;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final todayGames = _getGamesFor(
      selectedTeam ?? '',
      DateTimeRange(start: now, end: now.add(const Duration(days: 1))),
    );
    final upcomingGames = _getGamesFor(
      selectedTeam ?? '',
      DateTimeRange(start: now.add(const Duration(days: 1)), end: now.add(const Duration(days: 7))),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: selectedTeam != null
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_${_displayToCode[selectedTeam]!}.png',
                  ),
                ),
              )
            : null,
        title: Text(
          selectedTeam ?? '마이 팀 설정',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (selectedTeam != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () => myTeamProvider.clearMyTeam(),
            ),
        ],
      ),
      body: selectedTeam == null
          ? _buildPicker(context)
          : _buildDashboard(context, selectedTeam, todayGames, upcomingGames),
    );
  }

  Widget _buildPicker(BuildContext context) {
    final myTeamProvider = context.read<MyTeamProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('마이 팀을 선택하세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _allTeams.map((team) {
                final code = _displayToCode[team]!;
                final isSelected = _selectedTeam == team;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTeam = team),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.network(
                            'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_${code}.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(team, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                      await myTeamProvider.setMyTeam(_selectedTeam!);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    String team,
    List<Map<String, dynamic>> todayGames,
    List<Map<String, dynamic>> upcomingGames,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('오늘의 경기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: todayGames.isEmpty
                ? const Center(child: Text('오늘 경기가 없습니다.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
                    itemCount: todayGames.length,
                    itemBuilder: (ctx, i) {
                      final g = todayGames[i];
                      final hc = _displayToCode[g['home']]!;
                      final ac = _displayToCode[g['away']]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                              'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_${hc}.png',
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(g['home'], style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                      const Text('VS', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                      Column(
                                        children: [
                                          ClipOval(
                                            child: Image.network(
                                              'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_${ac}.png',
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(g['away'], style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(g['time'], style: const TextStyle(color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(g['status'], style: const TextStyle(fontSize: 12, color: Colors.blue)),
                                    ],
                                  ),
                                ],
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
            child: Text('앞으로의 경기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          ...upcomingGames.map((g) {
            final hc = _displayToCode[g['home']]!;
            final ac = _displayToCode[g['away']]!;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_${hc}.png',
                ),
              ),
              title: Text('${g['home']} vs ${g['away']}'),
              subtitle: Text('${g['date'].month}.${g['date'].day} ${g['time']}'),
              trailing: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_${ac}.png',
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlayerScreen(filterTeam: team)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('우리 팀 선수 보기'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
