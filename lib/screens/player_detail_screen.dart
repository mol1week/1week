import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/my_team_provider.dart';
// 팀별 primary 컬러 매핑
const Map<String, Color> _primaryColors = {
  'KIA 타이거즈': Color(0xFFEA0029),
  '롯데 자이언츠': Color(0xFFA60C27),
  '삼성 라이온즈': Color(0xFF074CA1),
  '두산 베어스':   Color(0xFF1A1748),
  'LG 트윈스':     Color(0xFFC30452),
  '한화 이글스':   Color(0xFFEA5C24),
  'KT 위즈':      Color(0xFF000000),
  'NC 다이노스':   Color(0xFF315288),
  '키움 히어로즈': Color(0xFF570514),
  'SSG 랜더스':    Color(0xFFCE0E2D),
  '전체':         Color(0xFFF0F0F0),
};

/// 팀 이름으로 primary 컬러 반환
Color getPrimaryColor(String teamName) {
  return _primaryColors[teamName] ?? _primaryColors['전체']!;
}

class PlayerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> player;
  const PlayerDetailScreen({super.key, required this.player});
  @override
  Widget build(BuildContext context) {
    final isPitcher = player['isPitcher'] as bool;
    final stats = player['stats'] as Map<String, Map<String, String>>;

    // 선택된 선수 팀 이름으로 배경색 가져오기
    final teamName = player['team'] as String;
    final primaryColor = getPrimaryColor(teamName);

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(player['name'], style: const TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 프로필
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: (player['imageUrl'] != null &&
                    player['imageUrl'].toString().isNotEmpty)
                    ? NetworkImage(player['imageUrl'])
                    : null,
                child: (player['imageUrl'] == null ||
                    player['imageUrl'].toString().isEmpty)
                    ? Text(player['name'][0],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(height: 16),
              Text(player['name'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('#${player['number']} | ${player['position']}',
                  style: const TextStyle(color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 32),

          // 기본 정보
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('기본 정보',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildInfoRow('팀', player['team']),
                _buildInfoRow('등번호', '#${player['number']}'),
                _buildInfoRow('포지션', player['positionDetail']),
                _buildInfoRow('신체', player['heightWeight']),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // 스탯 카드 (타자/투수별)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isPitcher ? '투수 기록' : '타자 기록',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildStatsSection('2025 시즌', stats['2025']!, isPitcher),
                    const SizedBox(height: 16),
                    _buildStatsSection('통산', stats['통산']!, isPitcher),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(val ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildStatsSection(String title, Map<String, String> stat, bool isPitcher) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        if (isPitcher) ...[
          _buildStatItem('ERA', stat['era']!),
          _buildStatItem('승', stat['win']!),
          _buildStatItem('패', stat['lose']!),
        ] else ...[
          _buildStatItem('타율', stat['avg']!),
          _buildStatItem('안타', stat['hits']!),
          _buildStatItem('홈런', stat['hr']!),
        ],
      ]),
    ]);
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
