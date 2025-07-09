// lib/player_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'player_detail_screen.dart';
import 'package:provider/provider.dart';
import '../providers/my_team_provider.dart';

/// PlayerScreen:
/// 선수 목록 화면입니다. filterTeam 파라미터로 특정 팀만 보여줄 수 있습니다.
class PlayerScreen extends StatefulWidget {
  /// 선택된 팀명 (null이면 전체)
  final String? filterTeam;

  const PlayerScreen({Key? key, this.filterTeam}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  /// 현재 드롭다운에 선택된 팀
  late String _selectedTeam;
  bool _userChangedFilter = false;
  /// 드롭다운용 팀 목록 (전체 + CSV에서 추출된 팀)
  List<String> _teams = ['전체'];

  /// CSV에서 로드한 모든 선수
  List<Map<String, dynamic>> _players = [];

  /// 로딩 상태
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();// 데이터 로딩만 담당
  }
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _selectedTeam = context.read<MyTeamProvider>().myTeam ?? '전체';;
      _loadAllPlayers();
      _initialized = true;
    }
  }
  /// hitter/pitcher CSV를 모두 읽어서 _players 에 저장
  Future<void> _loadAllPlayers() async {
    final hitters  = await _loadCsv('assets/data/kbo_hitter_players.csv', isPitcher: false);
    final pitchers = await _loadCsv('assets/data/kbo_pitcher_players.csv', isPitcher: true);
    final all = [...hitters, ...pitchers];

    // 드롭다운용 팀 목록 생성
    final teams = all.map((p) => p['team'] as String).toSet().toList()..sort();

    setState(() {
      _players   = all;
      _teams     = ['전체', ...teams];
      _isLoading = false;
      // 만약 filterTeam이 전달된 값 중 하나라면 드롭다운에도 적용
      if (widget.filterTeam != null && teams.contains(widget.filterTeam)) {
        _selectedTeam = widget.filterTeam!;
      }
    });
  }

  /// CSV 파싱 로직 (n개만 split)
  Future<List<Map<String, dynamic>>> _loadCsv(String path, {required bool isPitcher}) async {
    final raw   = await rootBundle.loadString(path);
    final lines = raw.split('\n');
    final out   = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = _parseCSVLine(line, maxSplits: isPitcher ? 6 : 5);
      if (parts.length <= (isPitcher ? 6 : 5)) continue;

      // --- 공통 필드 추출 ---
      final name           = parts[0];
      final imageUrl       = parts[1];
      final backNo         = isPitcher ? parts[3] : parts[2];
      final positionDetail = isPitcher ? parts[4] : parts[3];
      final heightWeight   = isPitcher ? parts[5] : parts[4];
      var   recordJson     = parts.last;

      // JSON 문자열 정리 (외부 따옴표, 작은따옴표 교체)
      if (recordJson.startsWith('"') && recordJson.endsWith('"')) {
        recordJson = recordJson.substring(1, recordJson.length - 1);
      }
      recordJson = recordJson.replaceAll("'", '"');

      // --- 3) 팀 코드 추출 ---
      String teamCode;
      if (isPitcher) {
        // 투수 CSV에 Team 컬럼이 3번째 요소(parts[2])에 들어있음
        teamCode = parts[2];
      } else {
        // 타자 CSV엔 Team 컬럼 없으므로, Record JSON 배열을 역순으로 돌며
        // Team 필드가 있는 첫 번째 레코드를 최신 팀으로 사용
        teamCode = 'N/A';
        try {
          final recs = json.decode(recordJson) as List<dynamic>;
          for (final rec in recs.reversed) {
            if (rec is Map<String, dynamic> && rec.containsKey('Team')) {
              teamCode = rec['Team'].toString();
              break;
            }
          }
        } catch (_) {
          // 파싱 오류 시 기본값 N/A 유지
        }
      }

      // --- 4) 스탯 파싱 ---
      final stats = <String, Map<String, String>>{};
      try {
        final recs = json.decode(recordJson) as List<dynamic>;
        for (var rec in recs) {
          if (rec is Map<String, dynamic>) {
            final year = rec.containsKey('Year') ? rec['Year'].toString() : '통산';
            if (isPitcher) {
              stats[year] = {
                'era' : rec['ERA']?.toString() ?? '-',
                'win' : rec['Win']?.toString() ?? '-',
                'lose': rec['Lose']?.toString() ?? '-',
              };
            } else {
              stats[year] = {
                'avg' : rec['Avg']?.toString() ?? '0.000',
                'hits': rec['Hit']?.toString() ?? '0',
                'hr'  : rec['HomeRun']?.toString() ?? '0',
              };
            }
          }
        }
      } catch (_) {
        // 스탯 파싱 오류 무시
      }

      // --- 5) 화면용 팀명 매핑 ---
      final teamName = _teamDisplayMap[teamCode] ?? teamCode;

      out.add({
        'name'           : name,
        'imageUrl'       : imageUrl,
        'team'           : teamName,
        'number'         : backNo,
        'positionDetail': positionDetail,
        'position'       : _simplifyPosition(positionDetail),
        'heightWeight'   : heightWeight,
        'stats'          : stats,
        'isPitcher'      : isPitcher,
      });
    }

    return out;
  }

  /// CSV 한 줄을 maxSplits 만큼만 콤마 분리
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

  /// 코드 → 화면용 팀명 매핑
  static const Map<String, String> _teamDisplayMap = {
    'KIA' : 'KIA 타이거즈',
    '롯데' : '롯데 자이언츠',
    '삼성' : '삼성 라이온즈',
    '두산' : '두산 베어스',
    'LG'  : 'LG 트윈스',
    '한화' : '한화 이글스',
    'KT'  : 'KT 위즈',
    'NC'  : 'NC 다이노스',
    '키움' : '키움 히어로즈',
    'SSG' : 'SSG 랜더스',
  };

  String _simplifyPosition(String pd) {
    if (pd.contains('투수'))   return '투수';
    if (pd.contains('내야수')) return '내야수';
    if (pd.contains('외야수')) return '외야수';
    if (pd.contains('포수'))   return '포수';
    return 'N/A';
  }

  /// 드롭다운 선택값에 따라 필터링
  List<Map<String, dynamic>> get _filteredPlayers {
    if (_selectedTeam == '전체') return _players;
    return _players.where((p) => p['team'] == _selectedTeam).toList();
  }


  @override
  Widget build(BuildContext context) {
    // 선택된 드롭다운 팀을 배경색으로 사용
    final myTeam = context.watch<MyTeamProvider>().myTeam;

    // 사용자가 드롭다운을 건드리지 않았고, 마이팀과 필터가 다르면 동기화
    if (!_userChangedFilter &&
        widget.filterTeam == null &&
        myTeam != null &&
        myTeam != _selectedTeam) {
      setState(() {
        _selectedTeam = myTeam;
      });
    }

    final primaryColor = getPrimaryColor(_selectedTeam);
    final secondaryColor = getSecondaryColor(_selectedTeam);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.sports_baseball, color: primaryColor),
            SizedBox(width: 8),
            Text(
              '선수 보기',
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ── 팀 필터 ──
          Container(
            color: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('팀 필터', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    dropdownColor: primaryColor,
                    value: _selectedTeam,
                    items: _teams
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                      onChanged: (t) => setState(() {
                        _selectedTeam = t!;
                        _userChangedFilter = true;
                      }),
                  ),
                ),
              ],
            ),
          ),

          // ── 선수 그리드 ──
          Expanded(
            child: _filteredPlayers.isEmpty
                ? const Center(
                child: Text('선수 데이터가 없습니다.', style: TextStyle(color: Colors.grey)))
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: _filteredPlayers.length,
              itemBuilder: (ctx, i) {
                final p = _filteredPlayers[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlayerDetailScreen(player: p)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryColor, // 테두리 색상
                        width: 3.0,         // 테두리 두께
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 3)
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: (p['imageUrl'] != null &&
                              p['imageUrl'].toString().isNotEmpty)
                              ? NetworkImage(p['imageUrl'])
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(p['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
                        Text(p['position'], style: TextStyle(fontSize: 12, color: secondaryColor)),
                        Text('#${p['number']}',
                            style: const TextStyle(color: Colors.black, fontSize: 12)),
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
