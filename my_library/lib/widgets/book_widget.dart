import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../pages/book_detail_page.dart';

/// 书籍组件 (根据页数计算尺寸)
///
/// 渲染一本书的书脊，包含：
/// - 根据页数自动计算厚度和高度
/// - 渐变效果模拟光泽
/// - 点击可跳转到书籍详情页
class BookWidget extends StatelessWidget {
  final BookModel book;

  const BookWidget({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    // 算法：页数越多越厚(width)，越高(height)
    // 限制最小厚度 20，最大 60
    final double thickness = (20 + (book.pageCount / 30)).clamp(20.0, 60.0);
    // 限制高度 90 - 120
    final double height = (90 + (book.pageCount / 40)).clamp(90.0, 120.0);

    return Container(
      margin: const EdgeInsets.only(right: 6),
      alignment: Alignment.bottomCenter,
      child: InkWell(
        onTap: () {
          // 跳转到详情页
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookDetailPage(book: book)),
          );
        },
        // 长按触发拖拽由 ReorderableListView 自动处理
        child: Container(
          width: thickness,
          height: height,
          decoration: BoxDecoration(
            color: book.color,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(3), right: Radius.circular(2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
            // 模拟书脊光泽
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                book.color.withValues(alpha: book.color.a * 0.7),
                book.color,
                book.color.withValues(alpha: book.color.a * 0.9),
                Colors.black.withValues(alpha: 0.3),
              ],
              stops: const [0.0, 0.2, 0.8, 1.0],
            ),
          ),
          // 这里可以加书名缩写或者纹理
        ),
      ),
    );
  }
}
