// lib/player_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'player_detail_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  String _selectedTeam = '전체';
  List<String> _teams = ['전체'];
  List<Map<String, dynamic>> _players = [];
  bool _isLoading = true;

  /// 팀 코드 → 화면용 이름 매핑
  static const Map<String, String> _teamDisplayMap = {
    'KIA'  : 'KIA 타이거즈',
    '롯데'  : '롯데 자이언츠',
    '삼성'  : '삼성 라이온즈',
    '두산'  : '두산 베어스',
    'LG'   : 'LG 트윈스',
    '한화'  : '한화 이글스',
    'KT'   : 'KT 위즈',
    'NC'   : 'NC 다이노스',
    '키움'  : '키움 히어로즈',
    'SSG'  : 'SSG 랜더스',
  };

  @override
  void initState() {
    super.initState();
    _loadAllPlayers();
  }

  Future<void> _loadAllPlayers() async {
    final hitters  = await _loadCsv('assets/data/kbo_hitter_players.csv', isPitcher: false);
    final pitchers = await _loadCsv('assets/data/kbo_pitcher_players.csv', isPitcher: true);

    final all = [...hitters, ...pitchers];
    // 드롭다운용 팀 리스트 생성
    final teams = all.map((p) => p['team'] as String).toSet().toList()..sort();

    setState(() {
      _players    = all;
      _teams      = ['전체', ...teams];
      _isLoading  = false;
      _selectedTeam = '전체';
    });
  }

  Future<List<Map<String, dynamic>>> _loadCsv(String path, {required bool isPitcher}) async {
    final raw   = await rootBundle.loadString(path);
    final lines = raw.split('\n');
    final out   = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // 1) 타자: 첫 5개 콤마, 투수: 첫 6개 콤마만 split
      final parts = _parseCSVLine(line, maxSplits: isPitcher ? 6 : 5);
      if (parts.length <= (isPitcher ? 6 : 5)) continue;

      // 공통 필드
      final name           = parts[0];
      final imageUrl       = parts[1];
      final backNo         = parts[isPitcher ? 3 : 2];
      final positionDetail = parts[isPitcher ? 4 : 3];
      final heightWeight   = parts[isPitcher ? 5 : 4];
      var   recordJson     = parts.last;    // 타자: parts[5], 투수: parts[6]

      // 2) Record JSON cleanup
      if (recordJson.startsWith('"') && recordJson.endsWith('"')) {
        recordJson = recordJson.substring(1, recordJson.length - 1);
      }
      recordJson = recordJson.replaceAll("'", '"');

      // 3) 팀 코드 추출
      String teamCode;
      if (isPitcher) {
        // 투수 CSV에 Team 컬럼이 3번째 요소(parts[2])로 들어있음
        teamCode = parts[2];
      } else {
        // 타자 CSV엔 Team 컬럼이 없으니 Record JSON 첫 레코드에서 추출
        teamCode = 'N/A';
      }

      // 4) JSON 파싱: stats와, 타자일 때 팀 코드도 여기서 뽑기
      final stats = <String, Map<String, String>>{};
      try {
        final recs = json.decode(recordJson) as List<dynamic>;
        for (var rec in recs) {
          if (rec is Map<String, dynamic>) {
            final year = rec.containsKey('Year') ? rec['Year'].toString() : '통산';
            if (isPitcher) {
              stats[year] = {
                'era' : rec['ERA']?.toString()    ?? '-',
                'win' : rec['Win']?.toString()    ?? '-',
                'lose': rec['Lose']?.toString()   ?? '-',
              };
            } else {
              stats[year] = {
                'avg' : rec['Avg']?.toString()     ?? '0.000',
                'hits': rec['Hit']?.toString()     ?? '0',
                'hr'  : rec['HomeRun']?.toString() ?? '0',
              };
              // 타자의 Team은 Record JSON의 첫 레코드에서 가져오기
              if (teamCode == 'N/A' && rec.containsKey('Team')) {
                teamCode = rec['Team'].toString();
              }
            }
          }
        }
      } catch (_) {
        // 파싱 오류 무시
      }

      // 5) 매핑된 화면용 팀 이름
      final teamName = _teamDisplayMap[teamCode] ?? teamCode;

      // 6) 포지션 단순화
      final position = _simplifyPosition(positionDetail);

      out.add({
        'name'           : name,
        'imageUrl'       : imageUrl,
        'team'           : teamName,
        'number'         : backNo,
        'positionDetail': positionDetail,
        'position'       : position,
        'heightWeight'   : heightWeight,
        'stats'          : stats,
        'isPitcher'      : isPitcher,
      });
    }

    return out;
  }

  String _simplifyPosition(String pd) {
    if (pd.contains('투수'))   return '투수';
    if (pd.contains('내야수')) return '내야수';
    if (pd.contains('외야수')) return '외야수';
    if (pd.contains('포수'))   return '포수';
    return 'N/A';
  }

  /// 처음 maxSplits 개만큼 콤마 분리, 나머지는 그대로 묶어서 남김
  List<String> _parseCSVLine(String line, {required int maxSplits}) {
    final res = <String>[];
    final sb  = StringBuffer();
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

  List<Map<String, dynamic>> get _filteredPlayers {
    if (_selectedTeam == '전체') return _players;
    return _players.where((p) => p['team'] == _selectedTeam).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('선수 보기', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ── 팀 필터 ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('팀 필터', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTeam,
                    items: _teams.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (t) => setState(() => _selectedTeam = t!),
                  ),
                ),
              ],
            ),
          ),

          // ── 선수 그리드 ──
          Expanded(
            child: _filteredPlayers.isEmpty
                ? const Center(child: Text('선수 데이터가 없습니다.', style: TextStyle(color: Colors.grey)))
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 0.8, crossAxisSpacing: 16, mainAxisSpacing: 16,
              ),
              itemCount: _filteredPlayers.length,
              itemBuilder: (ctx, i) {
                final p = _filteredPlayers[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: p)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 3)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30, backgroundColor: Colors.grey[300],
                          backgroundImage: (p['imageUrl'] != null && p['imageUrl'].toString().isNotEmpty)
                              ? NetworkImage(p['imageUrl'])
                              : null,
                          child: (p['imageUrl'] == null || p['imageUrl'].toString().isEmpty)
                              ? Text(p['name'][0], style: const TextStyle(color: Colors.white, fontSize: 20))
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(p['position'], style: const TextStyle(color: Colors.grey)),
                        Text('#${p['number']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
