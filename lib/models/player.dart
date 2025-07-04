/// 선수 정보를 담는 모델 클래스
class Player {
  final String name;      // 선수 이름
  final String team;      // 소속 팀
  final String imageUrl;  // 상세 페이지용 이미지 URL

  // 즐겨찾기 여부(기본값 false)
  bool isFavorite;

  Player({
    required this.name,
    required this.team,
    required this.imageUrl,
    this.isFavorite = false,  // 초기에는 즐겨찾기 아니라고 설정
  });
}
