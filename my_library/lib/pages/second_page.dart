import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../themes/colors.dart';
import '../utils/mock_data.dart';
import 'book_detail_page.dart';

class SecondPage extends StatefulWidget {
  final VoidCallback onBack;

  const SecondPage({super.key, required this.onBack});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  late List<ShelfData> _shelves;

  @override
  void initState() {
    super.initState();
    _shelves = [
      ShelfData(title: "Favorites", books: generateBooks(6)),
      ShelfData(title: "Recent Readings", books: generateBooks(8)),
      ShelfData(title: "Archive", books: generateBooks(5)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClaudeColors.background,
      appBar: AppBar(
        title: const Text('My Library'),
        centerTitle: false,
        backgroundColor: ClaudeColors.background, // 保持与背景一致
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ClaudeColors.textMuted),
          onPressed: widget.onBack,
          tooltip: '返回欢迎页',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: ClaudeColors.textMuted),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: _shelves.length,
        itemBuilder: (context, shelfIndex) {
          return _buildShelfRow(shelfIndex);
        },
      ),
    );
  }

  Widget _buildShelfRow(int shelfIndex) {
    final shelf = _shelves[shelfIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 书架标题
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Row(
            children: [
              Text(
                shelf.title,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ClaudeColors.textMain,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ClaudeColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${shelf.books.length}",
                  style: const TextStyle(fontSize: 12, color: ClaudeColors.textMuted),
                ),
              )
            ],
          ),
        ),

        // 2. 书架主体区域 (DragTarget)
        DragTarget<DragData>(
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            final data = details.data;
            if (data.fromShelfIndex == shelfIndex) return; // 同书架暂不处理排序
            setState(() {
              _shelves[data.fromShelfIndex].books.remove(data.book);
              _shelves[shelfIndex].books.add(data.book);
            });
          },
          builder: (context, candidateData, rejectedData) {
            final isHoveringShelf = candidateData.isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 160, // 增加高度，给悬浮动画留空间
              decoration: BoxDecoration(
                color: isHoveringShelf ? ClaudeColors.accent.withValues(alpha: 0.05) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none, // 关键：允许阴影和悬浮超出边界
                children: [
                  // A. 书架板 (Shelf Board)
                  // 使用 Positioned 确保它永远在底部
                  Positioned(
                    bottom: 10, // 距离底部留一点空隙
                    left: 16,
                    right: 16,
                    height: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF32302D), // 深木色
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5), // 向下的投影
                          )
                        ],
                        // 给书架板加一个顶部亮边，增加厚度感
                        border: const Border(
                          top: BorderSide(color: Color(0xFF4D4A45), width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  // B. 书籍列表
                  // 底部对齐到书架板的上方
                  Positioned.fill(
                    bottom: 22, // 10(margin) + 12(board visual height correction)
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none, // 关键：防止书本阴影被切
                      itemCount: shelf.books.length,
                      itemBuilder: (context, bookIndex) {
                        final book = shelf.books[bookIndex];
                        return _buildDraggableBook(book, shelfIndex);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDraggableBook(BookModel book, int shelfIndex) {
    // 限制尺寸算法
    final double thickness = (24 + (book.pageCount / 30)).clamp(24.0, 55.0);
    final double height = (95 + (book.pageCount / 40)).clamp(95.0, 130.0);

    return LongPressDraggable<DragData>(
      data: DragData(book: book, fromShelfIndex: shelfIndex),
      delay: const Duration(milliseconds: 200), // 添加延迟，区分点击和拖拽
      hapticFeedbackOnStart: true, // 开始拖拽时震动反馈
      feedback: Material(
        color: Colors.transparent,
        child: _BookVisual(
          book: book,
          width: thickness,
          height: height,
          isDragging: true,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: _BookVisual(
          book: book,
          width: thickness,
          height: height,
          isPlaceholder: true,
        ),
      ),
      // 这里的 child 是正常状态下的书
      child: _InteractiveBook(
        book: book,
        width: thickness,
        height: height,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookDetailPage(book: book)),
          );
        },
      ),
    );
  }
}

/// 一个处理鼠标悬停和点击交互的 Widget
class _InteractiveBook extends StatefulWidget {
  final BookModel book;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _InteractiveBook({
    required this.book,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  State<_InteractiveBook> createState() => _InteractiveBookState();
}

class _InteractiveBookState extends State<_InteractiveBook> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // 1. 关键修复：鼠标放上去变小手
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          // 悬停时向上位移，模拟抽书动作
          transform: Matrix4.translationValues(0, _isHovering ? -8 : 0, 0),
          child: _BookVisual(
            book: widget.book,
            width: widget.width,
            height: widget.height,
            isHovering: _isHovering,
          ),
        ),
      ),
    );
  }
}

/// 纯粹的视觉组件：绘制书本
class _BookVisual extends StatelessWidget {
  final BookModel book;
  final double width;
  final double height;
  final bool isDragging;
  final bool isHovering;
  final bool isPlaceholder;

  const _BookVisual({
    required this.book,
    required this.width,
    required this.height,
    this.isDragging = false,
    this.isHovering = false,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    // 拖拽时放大一点
    final double scale = isDragging ? 1.1 : 1.0;
    
    return Transform.scale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(right: 5), // 书之间的间距
        alignment: Alignment.bottomCenter, // 确保底部对齐
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: book.color,
            // 只有左边有圆角，模拟书脊
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              bottomLeft: Radius.circular(2),
              topRight: Radius.circular(1),
              bottomRight: Radius.circular(1),
            ),
            boxShadow: isPlaceholder ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDragging ? 0.6 : (isHovering ? 0.5 : 0.3)),
                // 悬停时阴影更远，增加悬浮感
                offset: Offset(isDragging ? 8 : 2, isDragging ? 8 : (isHovering ? 4 : 2)),
                blurRadius: isDragging ? 15 : (isHovering ? 8 : 3),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                // 书脊暗部
                Color.lerp(book.color, Colors.black, 0.2)!,
                // 书脊高光
                Color.lerp(book.color, Colors.white, 0.1)!,
                book.color,
                // 封面连接处阴影
                Color.lerp(book.color, Colors.black, 0.4)!,
              ],
              stops: const [0.05, 0.15, 0.85, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // 模拟书脊上的纹理/标题条
              if (height > 100)
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 12,
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                ),
              // 底部装饰线
               Positioned(
                  bottom: 10,
                  left: 4,
                  right: 4,
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShelfData {
  final String title;
  final List<BookModel> books;
  ShelfData({required this.title, required this.books});
}

class DragData {
  final BookModel book;
  final int fromShelfIndex;
  DragData({required this.book, required this.fromShelfIndex});
}