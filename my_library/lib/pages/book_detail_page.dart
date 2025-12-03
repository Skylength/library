import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/note_model.dart';
import '../themes/colors.dart';
import 'pdf_reader_page.dart';

/// 书籍详情页
class BookDetailPage extends StatefulWidget {
  final BookModel book;

  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool _isSidebarVisible = false;
  late List<NoteModel> _notes;

  @override
  void initState() {
    super.initState();
    _notes = List.generate(
      12,
      (index) => NoteModel(
        id: 'n_$index',
        tag: index % 3 == 0
            ? '#idea'
            : (index % 3 == 1 ? '#quote' : '#todo'),
        content:
            'This is a mock note content for item $index. Thinking about architecture and design patterns in Flutter...',
      ),
    );
  }

  // 根据标签获取对应的强调色
  Color _getTagColor(String tag) {
    if (tag.contains('idea')) return Colors.orangeAccent;
    if (tag.contains('quote')) return Colors.blueAccent;
    if (tag.contains('todo')) return Colors.greenAccent;
    return ClaudeColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClaudeColors.background,
      appBar: AppBar(
        backgroundColor: ClaudeColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.book.title,
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1, 
            thickness: 1, 
            // 使用 withValues 替代 withOpacity
            color: ClaudeColors.border.withValues(alpha: 0.3),
          ),
        ),
        actions: [
          IconButton(
            // 添加简单的旋转/切换动画效果
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isSidebarVisible ? Icons.fullscreen_exit : Icons.vertical_split,
                key: ValueKey(_isSidebarVisible),
                size: 20,
              ),
            ),
            tooltip: 'Toggle Sidebar',
            onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 300 && !_isSidebarVisible) {
            setState(() => _isSidebarVisible = true);
          }
          if (details.primaryVelocity! < -300 && _isSidebarVisible) {
            setState(() => _isSidebarVisible = false);
          }
        },
        child: Row(
          children: [
            // 1. 侧边栏区域
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              width: _isSidebarVisible ? 280 : 0, // 稍微加宽一点
              child: ClipRect(
                child: OverflowBox(
                  minWidth: 0,
                  maxWidth: 280,
                  alignment: Alignment.topLeft,
                  child: _buildSidebar(context),
                ),
              ),
            ),

            // 分割线
            if (_isSidebarVisible)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: ClaudeColors.border.withValues(alpha: 0.3),
              ),

            // 2. 主要内容区域
            Expanded(
              child: Container(
                // 使用带一点点纹理颜色的背景
                color: const Color(0xFF1A1A1A), 
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) => _buildStickyNote(_notes[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: ClaudeColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面区域 - 点击打开PDF阅读器
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfReaderPage(
                      pdfAssetPath: 'test.pdf',
                      title: widget.book.title,
                    ),
                  ),
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 150,
                      decoration: BoxDecoration(
                        color: widget.book.color,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                        // 模拟书脊纹理
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    // 阅读图标提示
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // 标题信息
          Text(
            widget.book.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ClaudeColors.textMain,
              fontFamily: 'Georgia',
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.book.pageCount} Pages • Non-Fiction',
            style: TextStyle(
              color: ClaudeColors.textMuted.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          
          const SizedBox(height: 32),
          Divider(color: ClaudeColors.border.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          
          // 元数据区域
          const Text(
            'PROPERTIES',
            style: TextStyle(
              color: ClaudeColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_outlined, 'Created', 'Oct 24, 2023'),
          _buildInfoRow(Icons.edit_outlined, 'Status', 'Reading'),
          _buildInfoRow(Icons.tag, 'Tags', '#flutter #arch'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ClaudeColors.textMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: ClaudeColors.textMuted.withValues(alpha: 0.8), 
              fontSize: 13
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: ClaudeColors.textMain, 
              fontSize: 13,
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyNote(NoteModel note) {
    final accentColor = _getTagColor(note.tag);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClaudeColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          // 边框更淡更细
          color: ClaudeColors.border.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：胶囊标签
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  note.tag,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 装饰性小圆点
              Icon(Icons.more_horiz, 
                size: 16, 
                color: ClaudeColors.textMuted.withValues(alpha: 0.5)
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 内容
          Expanded(
            child: Text(
              note.content,
              style: TextStyle(
                color: ClaudeColors.textMain.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.5, // 增加行高，提升阅读体验
                fontFamily: 'Roboto', // 或者使用 Monospace 字体增加笔记感
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // 底部：ID 或 时间
          const SizedBox(height: 8),
          Text(
            note.id,
            style: TextStyle(
              fontSize: 10,
              color: ClaudeColors.textMuted.withValues(alpha: 0.4),
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}
