import 'package:flutter/material.dart';
import '../models/player.dart';

/// 선수 리스트 페이지
/// - 상단에 팀별 드롭다운 필터
/// - 각 항목 우측에 즐겨찾기 토글 별표
/// - 항목 클릭 시 상세 페이지 이동 콜백 실행
class PlayerListPage extends StatefulWidget {
  final List<Player> players;                      // 전체 선수 데이터
  final void Function(Player) onFavoriteToggle;    // 즐겨찾기 토글 콜백
  final void Function(Player) onTapPlayer;         // 상세 페이지 이동 콜백

  const PlayerListPage({
    Key? key,
    required this.players,
    required this.onFavoriteToggle,
    required this.onTapPlayer,
  }) : super(key: key);

  @override
  State<PlayerListPage> createState() => _PlayerListPageState();
}

class _PlayerListPageState extends State<PlayerListPage> {
  String? _selectedTeam;  // 드롭다운에서 선택된 팀 (null = 전체)

  @override
  Widget build(BuildContext context) {
    // 1) 전체 선수 목록에서 팀 이름만 뽑아서 정렬
    final teams = widget.players
        .map((p) => p.team)
        .toSet()
        .toList()
      ..sort();
    // 2) "전체" 옵션을 추가
    teams.insert(0, '전체');

    // 3) 필터링된 선수 리스트
    final filtered = ( _selectedTeam == null || _selectedTeam == '전체' )
        ? widget.players
        : widget.players.where((p) => p.team == _selectedTeam).toList();

    return Column(
      children: [
        // ────────────────────────────────────────
        // 팀 선택용 드롭다운
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('팀 필터:'),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedTeam ?? '전체',
                  items: teams.map((team) {
                    return DropdownMenuItem(
                      value: team,
                      child: Text(team),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedTeam = v;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ────────────────────────────────────────
        // 리스트뷰
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final p = filtered[index];
              return ListTile(
                title: Text(p.name),
                subtitle: Text(p.team),
                // 즐겨찾기 토글 버튼
                trailing: IconButton(
                  icon: Icon(
                    p.isFavorite ? Icons.star : Icons.star_border,
                    color: p.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: () => widget.onFavoriteToggle(p),
                ),
                // 상세 페이지 이동
                onTap: () => widget.onTapPlayer(p),
              );
            },
          ),
        ),
      ],
    );
  }
}
