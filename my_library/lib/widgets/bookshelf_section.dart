import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../themes/colors.dart';
import 'book_widget.dart';

/// 书架的一层展示组件
///
/// 显示一个分类标题和该分类下的书籍列表
class BookshelfSection extends StatelessWidget {
  final String title;
  final int bookCount;

  const BookshelfSection({
    super.key,
    required this.title,
    required this.bookCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 书架分类标题 (贴在墙上的标签)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ClaudeColors.textMain,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // 2. 书籍区域 + 书架板
        SizedBox(
          height: 140, // 书籍区域高度
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // A. 书架底板 (视觉上的托盘)
              Positioned(
                bottom: 0,
                left: 16,
                right: 16,
                height: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2B28), // 比背景稍亮
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 5),
                        blurRadius: 10,
                      )
                    ],
                    border: const Border(
                      top: BorderSide(color: ClaudeColors.border, width: 1),
                    ),
                  ),
                ),
              ),

              // B. 书籍列表 (水平滚动)
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: bookCount,
                itemBuilder: (context, index) {
                  // 生成一些随机变体，让书看起来不一样
                  final random = index * 100;
                  final pageCount = 50 + (random % 200); // 页数随机
                  final colorIndex = (index + title.length) % ClaudeColors.bookSpines.length;

                  return BookWidget(
                    book: BookModel(
                      id: 'book_${title}_$index',
                      title: 'Book $index',
                      pageCount: pageCount,
                      color: ClaudeColors.bookSpines[colorIndex],
                      lastEdited: DateTime.now(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20), // 层架之间的距离
      ],
    );
  }
}
