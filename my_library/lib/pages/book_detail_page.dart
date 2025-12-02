import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/note_model.dart';
import '../themes/colors.dart';

/// 书籍详情页
///
/// 显示书籍的详细信息和笔记列表
/// 包含可收起的侧边栏和便利贴展示
class BookDetailPage extends StatefulWidget {
  final BookModel book;

  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool _isSidebarVisible = true;
  late List<NoteModel> _notes;

  @override
  void initState() {
    super.initState();
    // 生成 Mock 笔记数据
    _notes = List.generate(
      12,
      (index) => NoteModel(
        id: 'n_$index',
        tag: index % 3 == 0
            ? '#idea'
            : (index % 3 == 1 ? '#quote' : '#todo'),
        content:
            'This is a mock note content for item $index. It simulates a sticky note or a card in Obsidian Canvas. \n\nThinking about architecture...',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClaudeColors.background, // 整个背景统一
      appBar: AppBar(
        title: Text(widget.book.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 控制侧边栏显示的按钮
          IconButton(
            icon: Icon(_isSidebarVisible
                ? Icons.fullscreen
                : Icons.vertical_split),
            tooltip: 'Toggle Sidebar',
            onPressed: () {
              setState(() {
                _isSidebarVisible = !_isSidebarVisible;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // 1. 左侧可隐藏侧边栏
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: _isSidebarVisible ? 260 : 0, // 控制宽度实现隐藏
            child: ClipRect(
              // 防止内容溢出
              child: OverflowBox(
                minWidth: 0,
                maxWidth: 260,
                alignment: Alignment.topLeft,
                child: _buildSidebar(),
              ),
            ),
          ),

          // 分割线 (仅当侧边栏显示时有一条细线)
          if (_isSidebarVisible)
            VerticalDivider(
              width: 1,
              color: ClaudeColors.border.withValues(alpha: 0.5),
            ),

          // 2. 中间主要内容区域 (便利贴/Canvas)
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E), // 比背景略深，模拟桌布或画布背景
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, // 卡片最大宽度
                  childAspectRatio: 0.85, // 卡片长宽比
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  return _buildStickyNote(_notes[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 侧边栏内容
  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: ClaudeColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面预览
          Center(
            child: Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: widget.book.color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.book.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ClaudeColors.textMain,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.book.pageCount} Pages',
            style: const TextStyle(color: ClaudeColors.textMuted),
          ),
          const SizedBox(height: 24),
          const Divider(color: ClaudeColors.border),
          const SizedBox(height: 16),
          const Text(
            'METADATA',
            style: TextStyle(
              color: ClaudeColors.textMuted,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.calendar_today, 'Created: Oct 24'),
          _buildInfoRow(Icons.edit, 'Modified: Just now'),
          _buildInfoRow(Icons.tag, '#architecture #flutter'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ClaudeColors.textMuted),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: ClaudeColors.textMain, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 便利贴/卡片样式
  Widget _buildStickyNote(NoteModel note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClaudeColors.surface, // 使用深色卡片，符合 Obsidian 风格
        borderRadius: BorderRadius.circular(4), // 方正一点
        border: Border.all(color: ClaudeColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sticky_note_2_outlined,
                  size: 14, color: ClaudeColors.accent),
              const SizedBox(width: 5),
              Text(
                note.tag,
                style: const TextStyle(
                  color: ClaudeColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              note.content,
              style: const TextStyle(
                color: ClaudeColors.textMain,
                fontSize: 13,
                height: 1.4, // 行高宽松一点
              ),
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }
}
