import 'package:flutter/material.dart';
import 'player_detail_page.dart';

class PlayerListPage extends StatelessWidget {
  const PlayerListPage({super.key});

  final List<String> playerNames = const [
    "이정후", "류현진", "김하성", "최지만", "강백호",
    "박병호", "양의지", "김광현", "손아섭", "오승환",
    "정찬헌", "안우진", "문승원", "박건우", "구자욱",
    "김재환", "최정", "이대호", "나성범", "김도영"
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: playerNames.length,
      itemBuilder: (context, index) {
        final name = playerNames[index];
        return ListTile(
          title: Text(name),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerDetailPage(playerName: name),
              ),
            );
          },
        );
      },
    );
  }
}
