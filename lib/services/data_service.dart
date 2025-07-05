import '../models/game.dart';
import '../models/player.dart';

class DataService {
  static List<Game> getGames() {
    return [
      Game(
        homeTeam: '삼성',
        awayTeam: '한화',
        homeTeamLogo: '🦁',
        awayTeamLogo: '🦅',
        time: '18:30',
        stadium: 'SPO-T',
        homePitcher: '원태인',
        awayPitcher: '안영명',
        status: '경기예정',
      ),
      Game(
        homeTeam: '롯데',
        awayTeam: 'KIA',
        homeTeamLogo: '🦭',
        awayTeamLogo: '🐅',
        time: '18:30',
        stadium: 'SPO-T',
        homePitcher: '윤동희',
        awayPitcher: '양현종',
        status: '경기예정',
        homeWinProbability: 16,
        awayWinProbability: 84,
      ),
      Game(
        homeTeam: '한화',
        awayTeam: 'LG',
        homeTeamLogo: '🦅',
        awayTeamLogo: '🦁',
        time: '18:30',
        stadium: 'SPO-T',
        homePitcher: '류현진',
        awayPitcher: '이민호',
        status: '경기예정',
      ),
    ];
  }

  static List<Player> getPlayers() {
    return [
      Player(
        name: '김도영',
        position: '3B',
        number: '5',
        birthDate: '2003년 10월 02일',
        positionDetail: '내야수(우투우타)',
        team: 'KIA 타이거즈',
        stats: {
          '2022': PlayerStats(avg: '0.237', hits: '53', hr: '3'),
          '2023': PlayerStats(avg: '0.309', hits: '103', hr: '7'),
          '2024': PlayerStats(avg: '0.347', hits: '200', hr: '38'),
          '2025': PlayerStats(avg: '0.330', hits: '33', hr: '7'),
          '통산': PlayerStats(avg: '0.313', hits: '378', hr: '55'),
        },
      ),
      Player(
        name: '나성범',
        position: 'OF',
        number: '51',
        birthDate: '1989년 04월 03일',
        positionDetail: '외야수(우투좌타)',
        team: 'KIA 타이거즈',
        stats: {
          '2022': PlayerStats(avg: '0.284', hits: '142', hr: '24'),
          '2023': PlayerStats(avg: '0.327', hits: '158', hr: '23'),
          '2024': PlayerStats(avg: '0.292', hits: '134', hr: '18'),
          '2025': PlayerStats(avg: '0.315', hits: '45', hr: '8'),
          '통산': PlayerStats(avg: '0.298', hits: '1245', hr: '156'),
        },
      ),
      Player(
        name: '최형우',
        position: 'OF',
        number: '17',
        birthDate: '1987년 01월 29일',
        positionDetail: '외야수(우투우타)',
        team: 'KIA 타이거즈',
        stats: {
          '2022': PlayerStats(avg: '0.301', hits: '156', hr: '22'),
          '2023': PlayerStats(avg: '0.315', hits: '167', hr: '19'),
          '2024': PlayerStats(avg: '0.288', hits: '145', hr: '15'),
          '2025': PlayerStats(avg: '0.342', hits: '52', hr: '9'),
          '통산': PlayerStats(avg: '0.305', hits: '1876', hr: '198'),
        },
      ),
      Player(
        name: '박찬호',
        position: 'OF',
        number: '6',
        birthDate: '1999년 07월 30일',
        positionDetail: '외야수(우투좌타)',
        team: 'KIA 타이거즈',
        stats: {
          '2022': PlayerStats(avg: '0.265', hits: '89', hr: '12'),
          '2023': PlayerStats(avg: '0.278', hits: '98', hr: '15'),
          '2024': PlayerStats(avg: '0.312', hits: '134', hr: '20'),
          '2025': PlayerStats(avg: '0.298', hits: '42', hr: '6'),
          '통산': PlayerStats(avg: '0.289', hits: '363', hr: '53'),
        },
      ),
      Player(
        name: '소크라테스',
        position: '1B',
        number: '50',
        birthDate: '1988년 02월 07일',
        positionDetail: '내야수(우투우타)',
        team: 'KIA 타이거즈',
        stats: {
          '2022': PlayerStats(avg: '0.0', hits: '0', hr: '0'),
          '2023': PlayerStats(avg: '0.0', hits: '0', hr: '0'),
          '2024': PlayerStats(avg: '0.233', hits: '67', hr: '15'),
          '2025': PlayerStats(avg: '0.267', hits: '28', hr: '5'),
          '통산': PlayerStats(avg: '0.245', hits: '95', hr: '20'),
        },
      ),
      Player(
        name: '김선빈',
        position: '2B',
        number: '23',
        birthDate: '1997년 09월 14일',
        positionDetail: '내야수(우투우타)',
        team: 'KIA 타이거즈',
        stats: {
          '2022': PlayerStats(avg: '0.289', hits: '112', hr: '8'),
          '2023': PlayerStats(avg: '0.267', hits: '98', hr: '6'),
          '2024': PlayerStats(avg: '0.301', hits: '145', hr: '12'),
          '2025': PlayerStats(avg: '0.278', hits: '38', hr: '3'),
          '통산': PlayerStats(avg: '0.285', hits: '393', hr: '29'),
        },
      ),
      Player(
        name: '이우성',
        position: 'C',
        number: '27',
        birthDate: '1996년 05월 21일',
        positionDetail: '포수(우투우타)',
        team: 'KIA 타이거즈',
        stats: {
          '2022': PlayerStats(avg: '0.245', hits: '78', hr: '9'),
          '2023': PlayerStats(avg: '0.256', hits: '89', hr: '11'),
          '2024': PlayerStats(avg: '0.278', hits: '102', hr: '14'),
          '2025': PlayerStats(avg: '0.289', hits: '34', hr: '4'),
          '통산': PlayerStats(avg: '0.267', hits: '303', hr: '38'),
        },
      ),
      Player(
        name: '서건창',
        position: 'SS',
        number: '7',
        birthDate: '1989년 08월 22일',
        positionDetail: '내야수(우투우타)',
        team: 'KIA 타이거즈',
        stats: {
          '2022': PlayerStats(avg: '0.267', hits: '134', hr: '16'),
          '2023': PlayerStats(avg: '0.289', hits: '156', hr: '18'),
          '2024': PlayerStats(avg: '0.301', hits: '167', hr: '21'),
          '2025': PlayerStats(avg: '0.278', hits: '45', hr: '5'),
          '통산': PlayerStats(avg: '0.284', hits: '1234', hr: '145'),
        },
      ),
      Player(
        name: '양현종',
        position: 'P',
        number: '54',
        birthDate: '1988년 03월 01일',
        positionDetail: '투수(좌투좌타)',
        team: 'KIA 타이거즈',
        stats: {
          '2022': PlayerStats(avg: '0.0', hits: '0', hr: '0'),
          '2023': PlayerStats(avg: '0.0', hits: '0', hr: '0'),
          '2024': PlayerStats(avg: '0.0', hits: '0', hr: '0'),
          '2025': PlayerStats(avg: '0.0', hits: '0', hr: '0'),
          '통산': PlayerStats(avg: '0.0', hits: '0', hr: '0'),
        },
      ),
    ];
  }

  static List<String> getTeams() {
    return [
      'KIA 타이거즈',
      '롯데 자이언츠',
      '삼성 라이온즈',
      'LG 트윈스',
      '한화 이글스',
    ];
  }
}

