import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTeamProvider with ChangeNotifier {
  String? _myTeam;

  String? get myTeam => _myTeam;

  Future<void> loadMyTeam() async {
    final prefs = await SharedPreferences.getInstance();
    _myTeam = prefs.getString('myTeam');
    notifyListeners();
  }

  Future<void> setMyTeam(String team) async {
    _myTeam = team;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myTeam', team);
    notifyListeners();
  }

  void clearMyTeam() {
    _myTeam = null;
    notifyListeners();
  }
}

const Map<String, Map<String, Color>> teamColors = {
  'KIA 타이거즈': {
    'primary': Color(0xFFEA0029),
    'secondary': Color(0xFF06141F),
  },
  '삼성 라이온즈': {
    'primary': Color(0xFF074CA1),
    'secondary': Color(0xFFBFC1C3),
  },
  'LG 트윈스': {
    'primary': Color(0xFFC30452),
    'secondary': Color(0xFF727071),
  },
  '두산 베어스': {
    'primary': Color(0xFF1A1748),
    'secondary': Color(0xFFEF1C26),
  },
  'KT 위즈': {
    'primary': Color(0xFF000000),
    'secondary': Color(0xFFED1B24),
  },
  'SSG 랜더스': {
    'primary': Color(0xFFCE0E2D),
    'secondary': Color(0xFFFDBB2F),
  },
  '키움 히어로즈': {
    'primary': Color(0xFF570514),
    'secondary': Color(0xFFDF057D),
  },
  'NC 다이노스': {
    'primary': Color(0xFF315288),
    'secondary': Color(0xFFC7A079),
  },
  '한화 이글스': {
    'primary': Color(0xFFEA5C24),
    'secondary': Color(0xFF000000),
  },
  '롯데 자이언츠': {
    'primary': Color(0xFF041E42),
    'secondary': Color(0xFFA60C27),
  },
};

Color getPrimaryColor(String? teamName) {
  return teamColors[teamName]?['primary'] ?? Colors.blue;
}

Color getSecondaryColor(String? teamName) {
  return teamColors[teamName]?['secondary'] ?? Colors.grey;
}
