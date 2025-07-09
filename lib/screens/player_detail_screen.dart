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
    final secondaryColor = getSecondaryColor(teamName);

    return Scaffold(
      backgroundColor: Colors.grey[100],
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
              const SizedBox(height: 16),
              Container(
                width: 160, // = radius * 2
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor, // 원하는 색상
                    width: 4.0,         // 테두리 두께
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (player['imageUrl'] != null &&
                      player['imageUrl'].toString().isNotEmpty)
                      ? NetworkImage(player['imageUrl'])
                      : null,
                  child: (player['imageUrl'] == null ||
                      player['imageUrl'].toString().isEmpty)
                      ? Text(
                    player['name'][0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ) : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(player['name'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 8),
              Text('#${player['number']} | ${player['position']}',
                  style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 32),

          // 기본 정보
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // 모서리 둥글기
              side: BorderSide(
                color: primaryColor, // 테두리 색
                width: 4.0,         // 테두리 두께
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('기본 정보',
                    style:
                    TextStyle(fontSize: 18,color: primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildInfoRow('팀', player['team'],secondaryColor),
                _buildInfoRow('등번호', '#${player['number']}', secondaryColor),
                _buildInfoRow('포지션', player['positionDetail'], secondaryColor),
                _buildInfoRow('신체', player['heightWeight'], secondaryColor),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // 스탯 카드 (타자/투수별)
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // 모서리 둥글기
              side: BorderSide(
                color: primaryColor, // 테두리 색
                width: 4.0,         // 테두리 두께
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isPitcher ? '투수 기록' : '타자 기록',
                        style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.bold)),
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

  Widget _buildInfoRow(String label, String? val, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(color: secondaryColor))),
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
