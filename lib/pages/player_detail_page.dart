import 'package:flutter/material.dart';

class PlayerDetailPage extends StatelessWidget {
  final String playerName;

  const PlayerDetailPage({super.key, required this.playerName});

  @override
  Widget build(BuildContext context) {
    // 임시 이미지 URL
    final imageUrl = 'https://picsum.photos/seed/$playerName/400/600';

    return Scaffold(
      appBar: AppBar(
        title: Text('$playerName 상세정보'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              playerName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Image.network(imageUrl),
          ],
        ),
      ),
    );
  }
}
