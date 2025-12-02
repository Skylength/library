import 'dart:math' as math;
import '../models/book_model.dart';
import '../themes/colors.dart';

/// 生成 Mock 书籍数据
List<BookModel> generateBooks(int count) {
  final random = math.Random();
  return List.generate(count, (index) {
    return BookModel(
      id: 'book_$index',
      title: 'Note Book ${index + 1}',
      // 页数在 100 到 800 之间随机
      pageCount: 100 + random.nextInt(700),
      color: ClaudeColors.bookSpines[random.nextInt(ClaudeColors.bookSpines.length)],
      lastEdited: DateTime.now().subtract(Duration(days: random.nextInt(30))),
    );
  });
}
