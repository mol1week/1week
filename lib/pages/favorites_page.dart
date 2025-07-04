import 'package:flutter/material.dart';
import '../models/player.dart';

/// 즐겨찾기된 선수들만 보여주는 페이지
class FavoritesPage extends StatelessWidget {
  final List<Player> players;               // 전체 선수 리스트
  final void Function(Player) onFavoriteToggle; // 즐겨찾기 토글 콜백

  const FavoritesPage({
    Key? key,
    required this.players,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 즐겨찾기된 선수만 필터
    final favs = players.where((p) => p.isFavorite).toList();

    if (favs.isEmpty) {
      return const Center(child: Text('즐겨찾기한 선수가 없습니다.'));
    }

    return ListView.builder(
      itemCount: favs.length,
      itemBuilder: (context, index) {
        final p = favs[index];
        return ListTile(
          title: Text(p.name),
          trailing: IconButton(
            icon: Icon(
              p.isFavorite ? Icons.star : Icons.star_border,
              color: p.isFavorite ? Colors.amber : null,
            ),
            onPressed: () => onFavoriteToggle(p),
          ),
        );
      },
    );
  }
}
