import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'prediction_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedTabIndex = 0; // KBO 리그 기본 탭
  DateTime _selectedDate = DateTime.now();

  final List<String> _tabs = ['KBO 리그'];
  List<Map<String, dynamic>> _games = [];
  bool _isLoading = true;

  // 팀 코드 → 로고 URL 매핑
  // 팀 코드 → 로고 URL 매핑
  static const Map<String, String> _teamLogoMap = {
    '삼성': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_SS.png',
    '한화': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_HH.png',
    '롯데': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_LT.png',
    'KIA': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_HT.png',
    '키움': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_WO.png',
    'SSG': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_SK.png',
    'LG': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_LG.png',
    'KT': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_KT.png',
    'NC': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_NC.png',
    '두산': 'https://6ptotvmi5753.edge.naverncp.com/KBO_IMAGE/emblem/regular/2025/emblem_OB.png',
  };

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final raw = await rootBundle.loadString('assets/data/kbo_games.csv');
      final lines = raw.split('\n');
      final List<Map<String, dynamic>> games = [];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _parseCsv(line);
        if (parts.length < 10) continue;

        DateTime date;
        try {
          final gd = parts[0];
          final y = int.parse(gd.substring(0, 4));
          final m = int.parse(gd.substring(4, 6));
          final d = int.parse(gd.substring(6, 8));
          date = DateTime(y, m, d);
        } catch (_) {
          continue;
        }

        games.add({
          'date': date,
          'stadium': parts[1],
          'status': parts[2],
          'time': parts[3],
          'homeTeam': parts[4],
          'awayTeam': parts[5],
          'homeScore': parts[6],
          'awayScore': parts[7],
          'homePitcher': parts[8],
          'awayPitcher': parts[9],
        });
      }

      setState(() {
        _games = games;
        if (games.isNotEmpty) {
          _selectedDate = games.first['date'] as DateTime;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _parseCsv(String line) {
    final res = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;
    for (var ch in line.characters) {
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        res.add(sb.toString().trim()); sb.clear();
      } else {
        sb.write(ch);
      }
    }
    res.add(sb.toString().trim());
    return res;
  }

  List<Map<String, dynamic>> get _filteredGames {
    return _games.where((g) {
      final d = g['date'] as DateTime;
      return d.year == _selectedDate.year &&
          d.month == _selectedDate.month &&
          d.day == _selectedDate.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              child: const Icon(Icons.sports_baseball, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('경기일정/결과', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.add, color: Colors.black), onPressed: () {})],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 탭바
          Container(
            color: Colors.white,
            child: Row(
              children: _tabs.asMap().entries.map((e) {
                final idx = e.key;
                final label = e.value;
                final selected = idx == _selectedTabIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: selected ? Colors.blue : Colors.transparent, width: 2)),
                      ),
                      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.blue : Colors.grey, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // 날짜 네비
          Container(
            color: Colors.white, padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days:1)))),
                Row(children: [
                  Text('${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2,'0')}.${_selectedDate.day.toString().padLeft(2,'0')}', style: const TextStyle(fontSize:16, fontWeight:FontWeight.bold)),
                  const SizedBox(width:8), const Icon(Icons.calendar_today, size:20),
                ]),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days:1)))),
              ],
            ),
          ),
          // 경기 리스트
          Expanded(
            child: _filteredGames.isEmpty
                ? const Center(child: Text('해당일 경기 정보가 없습니다.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                itemCount: _filteredGames.length,
                itemBuilder: (ctx, i) {
                  final game = _filteredGames[i];
                  final homeLogoUrl = _teamLogoMap[game['homeTeam']]!;
                  final awayLogoUrl = _teamLogoMap[game['awayTeam']]!;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal:16, vertical:8),
                    decoration: BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(8), boxShadow:[BoxShadow(color:Colors.grey.withOpacity(0.2), spreadRadius:1, blurRadius:3)]),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(padding:const EdgeInsets.symmetric(horizontal:12, vertical:4), decoration:BoxDecoration(color:Colors.blue, borderRadius:BorderRadius.circular(12)), child: Text(game['status'], style: const TextStyle(color:Colors.white, fontSize:12, fontWeight:FontWeight.bold))),
                          const SizedBox(height:16),
                          Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly, children:[
                            Column(children:[Image.network(homeLogoUrl, width:32, height:32), const SizedBox(height:4), Text(game['homeTeam'], style: const TextStyle(fontSize:14, fontWeight:FontWeight.bold))]),
                            Column(children:[Text(game['time'], style: const TextStyle(fontSize:16, fontWeight:FontWeight.bold)), Text(game['stadium'], style: const TextStyle(fontSize:12, color:Colors.grey))]),
                            Column(children:[Image.network(awayLogoUrl, width:32, height:32), const SizedBox(height:4), Text(game['awayTeam'], style: const TextStyle(fontSize:14, fontWeight:FontWeight.bold))]),
                          ]),
                          const SizedBox(height:16),
                          Row(mainAxisAlignment:MainAxisAlignment.spaceAround, children:[Text(game['homePitcher'], style: const TextStyle(fontSize:12)), const Text('선발투수', style: TextStyle(fontSize:12, color:Colors.grey)), Text(game['awayPitcher'], style: const TextStyle(fontSize:12))]),
                          const SizedBox(height:16),
                          SizedBox(width:double.infinity, child: ElevatedButton(onPressed:() => Navigator.push(context, MaterialPageRoute(builder:(_)=>const PredictionScreen())), style: ElevatedButton.styleFrom(backgroundColor:Colors.blue, foregroundColor:Colors.white, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))), child: const Text('예측 보기'))),
                        ],
                      ),
                    ),
                  );
                }
            ),
          ),
        ],
      ),
    );
  }
}


//day (요일)