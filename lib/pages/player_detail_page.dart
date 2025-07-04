import 'package:flutter/material.dart';
import '../models/player.dart';

/// PlayerDetailPage: 클릭된 선수의 상세 이미지 페이지
class PlayerDetailPage extends StatelessWidget {
  final Player player; // 전달받은 Player 객체

  const PlayerDetailPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name} 상세'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 선수 이름
            Text(
              player.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // 네트워크 이미지
            Image.network(
              player.imageUrl,
              width: 400,
              height: 500,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }
}
