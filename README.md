# Next Game Predictor

야구 경기 일정 조회부터 승률 예측, 선수 검색 및 상세 정보 열람까지 한 번에 할 수 있는 Flutter 앱입니다.

---

## 🔖 주요 기능

1. **일정 보기**
    - KBO 리그 등의 경기 일정을 카드 형태로 조회
    - 홈/어웨이 팀 로고, 구장, 시간, 투수 정보 표시
    - `예측 보기` 버튼으로 해당 경기의 승률 예측 화면으로 이동

2. **예측 보기**
    - 홈팀·어웨이팀 간 승률 바 차트
    - 승률 수치(%) 표시
    - 리그(시범경기·퓨처스리그 등) & 경기장 필터
    - 키 플레이어 예측 성적 자리(플레이스홀더)

3. **선수 보기**
    - 전체 선수 그리드 조회
    - 선수/팀명으로 실시간 검색 필터
    - 즐겨찾기 토글(★)
    - 선수 클릭 시 상세 정보 페이지로 이동

4. **선수 상세**
    - 기본 정보(이름·팀·등번호·포지션·생년월일) 표시
    - 연도별 타율·안타·홈런 통계 표(데이터테이블)

---

## 📂 폴더 구조

lib/
├── main.dart # 앱 진입점 & BottomNavigation 세팅
├── models/
│ ├── game.dart # Game 모델 + 샘플 데이터
│ ├── player.dart # Player 모델 + 샘플 데이터
│ ├── player_prediction.dart # 선수별 예측 성적 모델
│ └── match_prediction.dart # 경기 승률 예측 모델
└── pages/
├── schedule_page.dart # 일정 보기
├── prediction_page.dart # 예측 보기
├── players_page.dart # 선수 그리드 조회
├── player_detail_page.dart # 선수 상세 정보
└── … # (추후 즐겨찾기·설정 페이지 등)

---

## 🚀 설치 및 실행

1. Flutter SDK 설치
    - [Flutter 공식 문서](https://flutter.dev) 참고

2. 의존성 가져오기
   ```bash
   flutter pub get
디바이스 연결 또는 에뮬레이터 실행 후

flutter run

✏️ 모델 설명
Game
class Game {
final String homeTeam, awayTeam;
final DateTime date;
final String homeLogoUrl, awayLogoUrl;
final String homePitcher, awayPitcher;
final String venue;
// + static List<Game> sampleGames
}
Player


Player {
final String name, team;
final int number;
final String position;
final DateTime birthDate;
final Map<int, Map<String,num>> statsByYear;
// + static List<Player> samplePlayers
}

PlayerPrediction

class PlayerPrediction {
final Player player;
final double battingAverage;
final int hits, homeRuns;
}

MatchPrediction
class MatchPrediction {
final double homeWinProb;
}


🛠️ 향후 개선 사항
API 연동
KBO 오픈 API 또는 자체 서버에서 실제 경기/선수 데이터 가져오기
로컬 샘플 데이터를 실시간 API 호출로 대체
깊이 있는 예측 알고리즘
머신러닝 모델 연동
선수별·경기장별 성능 가중치 반영
UI/UX 다듬기
애니메이션 추가
다크 모드 지원
네트워크 상태·로딩 상태 처리
즐겨찾기·설정 기능 확장
Shared Preferences 연동
알림 설정 (경기 시작 알림 등)

📄 라이선스
MIT © 2025 Next Game Predictor