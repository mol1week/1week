import 'package:flutter/material.dart';

/// GalleryPage: 20개 이상의 이미지를 GridView로 보여줍니다.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 이미지 URL 20개 생성
    final imageUrls = List.generate(
      20,
          (i) => 'https://picsum.photos/seed/gallery$i/200/200',
    );

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,          // 한 줄에 3개 이미지
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrls[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
