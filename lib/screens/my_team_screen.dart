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
<<<<<<< HEAD
          padding: const EdgeInsets.all(3),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(0.5),
              child: Image.asset(
                'assets/image/${_displayToCode[selectedTeam]!}.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        )
=======
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_${_displayToCode[selectedTeam]!}.png',
                  ),
                ),
              )
>>>>>>> 8374a51ddd29569ce2cdc16085a385141fa76817
            : null,
        title: Text(
          "My TEAM",
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
                          child: Image.asset(
                            'assets/image/${code}.png',
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
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD

  Widget _buildDashboard(BuildContext context, String team, List<Map<String, dynamic>> todayGames, List<Map<String, dynamic>> upcomingGames) {
    final myTeam = context.watch<MyTeamProvider>().myTeam;
    final primaryColor = getPrimaryColor(myTeam);
    final secondaryColor = getSecondaryColor(myTeam);
=======
  Widget _buildDashboard(
    BuildContext context,
    String team,
    List<Map<String, dynamic>> todayGames,
    List<Map<String, dynamic>> upcomingGames,
  ) {
>>>>>>> 8374a51ddd29569ce2cdc16085a385141fa76817
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
<<<<<<< HEAD
=======
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
>>>>>>> 8374a51ddd29569ce2cdc16085a385141fa76817
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AspectRatio(
              aspectRatio: 2.5, // 너비:높이 비율 (이미지 비율 조정)
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 배경: 팀 로고 이미지
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/image/${_displayToCode[team]!}.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text("$team", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryColor)),
          const SizedBox(height: 20),
        Container(
          color: primaryColor, // 원하는 배경색
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('오늘의 경기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 180,
                child: Container(
                  color: primaryColor.withOpacity(0.1), // 💡 살짝 투명하게 (원하면 불투명하게도 가능)
                  child: todayGames.isEmpty
                      ? const Center(
                    child: Text('오늘 경기가 없습니다.', style: TextStyle(color: Colors.black)),
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: todayGames.length,
                    itemBuilder: (ctx, i) {
                      final g = todayGames[i];
                      final hc = _displayToCode[g['home']]!;
                      final ac = _displayToCode[g['away']]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width -
                              MediaQuery.of(context).padding.horizontal -
                              32,
                          child: Card(
                            color: Colors.white,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // 모서리 둥글기
                              side: BorderSide(
                                color: secondaryColor, // 테두리 색상
                                width: 4.0,         // 테두리 두께
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.white,
                                            child: Padding(
                                              padding: const EdgeInsets.all(0.5),
                                              child: Image.asset(
                                                'assets/image/$ac.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(g['away'], style: TextStyle(fontSize: 14, color: primaryColor, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Text('VS', style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w900)),
                                      Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.white,
                                            child: Padding(
                                              padding: const EdgeInsets.all(0.5),
                                              child: Image.asset(
                                                'assets/image/$hc.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(g['home'], style: TextStyle(fontSize: 14, color: primaryColor, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(g['time'], style: const TextStyle(color: Colors.black)),
                                      const SizedBox(height: 4),
                                      Text(g['status'], style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
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
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('앞으로의 경기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16), // 외부 여백 동일하게
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: secondaryColor, // 테두리 색상
                      width: 4.0,         // 테두리 두께
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12), // 내부 여백
                  child: Column(
                    children: [
                      for (int i = 0; i < upcomingGames.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(0.5),
                                child: Image.asset(
                                  'assets/image/${_displayToCode[upcomingGames[i]['away']]!}.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${upcomingGames[i]['away']} VS ${upcomingGames[i]['home']}',
                                  style: TextStyle(fontSize: 14, color: primaryColor, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${upcomingGames[i]['date'].month}.${upcomingGames[i]['date'].day} ${upcomingGames[i]['time']}',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            trailing: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(0.5),
                                child: Image.asset(
                                  'assets/image/${_displayToCode[upcomingGames[i]['home']]!}.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (i != upcomingGames.length - 1)
                           Divider(
                            color: secondaryColor,
                            thickness: 2,
                            height: 8,
                            indent: 12,
                            endIndent: 12,
                          ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayerScreen(filterTeam: team)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('우리 팀 선수 보기'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
      ),
    );
  }
}
