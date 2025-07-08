import 'package:flutter/material.dart';
import 'schedule_screen.dart';
import 'my_team_screen.dart';
import 'player_screen.dart';
import 'package:provider/provider.dart';
import '../providers/my_team_provider.dart';

/// HomeScreen:
/// 하단 탭바로 "일정 보기", "마이팀", "선수 보기" 화면을 전환하는 메인 화면입니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 현재 선택된 탭 인덱스 (0: 일정 보기, 1: 마이팀, 2: 선수 보기)
  int _currentIndex = 0;

  /// 화면 목록
  final List<Widget> _screens = const [
    ScheduleScreen(),
    MyTeamScreen(),
    PlayerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final myTeam = context.watch<MyTeamProvider>().myTeam;
    final primaryColor = getPrimaryColor(myTeam);
    return Scaffold(
      // 모든 스크린을 트리에 남겨두고, 현재 인덱스만 보여줍니다.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '일정 보기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: '마이팀',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '선수 보기',
          ),
        ],
      ),
    );
  }
}
