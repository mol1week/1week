import 'package:flutter/material.dart';
import 'models/player.dart';
import 'pages/player_list_page.dart';
import 'pages/player_detail_page.dart';
import 'pages/gallery_page.dart';
import 'pages/favorites_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '야구 선수 앱',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 전체 선수 목록
  final List<Player> _players = [
    Player(name: '김현수', team: '두산 베어스',        imageUrl: 'https://picsum.photos/seed/1/400'),
    Player(name: '박병호', team: '키움 히어로즈',     imageUrl: 'https://picsum.photos/seed/2/400'),
    // … 나머지 20명
  ];

  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // PlayerListPage에 콜백 2개(onFavoriteToggle, onTapPlayer) 전달
      PlayerListPage(
        players: _players,
        onFavoriteToggle: _toggleFavorite,
        onTapPlayer: (player) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerDetailPage(player: player),
            ),
          );
        },
      ),
      const GalleryPage(),
      FavoritesPage(
        players: _players,
        onFavoriteToggle: _toggleFavorite,
      ),
    ];
  }

  // 즐겨찾기 상태 뒤집기
  void _toggleFavorite(Player p) {
    setState(() {
      p.isFavorite = !p.isFavorite;
    });
  }

  void _onItemTapped(int idx) => setState(() => _selectedIndex = idx);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('팀 선수 앱')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list),          label: '선수 리스트'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: '갤러리'),
          BottomNavigationBarItem(icon: Icon(Icons.star),          label: '즐겨찾기'),
        ],
      ),
    );
  }
}
