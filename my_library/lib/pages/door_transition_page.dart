import 'package:flutter/material.dart';
import '../themes/colors.dart';
import 'second_page.dart';

/// 带推门动画的过渡页
///
/// 这里的逻辑是：底层放着 SecondPage，上层盖着欢迎页（作为两扇门）
/// 点击按钮后，两扇门向左右滑开，露出后面的主页面
class DoorTransitionPage extends StatefulWidget {
  const DoorTransitionPage({super.key});

  @override
  State<DoorTransitionPage> createState() => _DoorTransitionPageState();
}

class _DoorTransitionPageState extends State<DoorTransitionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _doorSlideAnim;
  late Animation<double> _contentFadeAnim;
  late Animation<double> _scaleAnim;

  bool _isDoorOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // 动画时长，慢一点更有沉浸感
    );

    // 门向两侧滑动的动画 (0 -> 1)
    _doorSlideAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    // 欢迎页文字淡出的动画
    _contentFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // 背后内容从小变大的缩放动画 (模拟进门景深)
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDoor() {
    setState(() {
      _isDoorOpen = true;
    });
    _controller.forward();
  }

  void _closeDoor() {
    setState(() {
      _isDoorOpen = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final doorWidth = size.width / 2;

    return Scaffold(
      body: Stack(
        children: [
          // --- 层级 1: 真正的主页 (藏在门后) ---
          Transform.scale(
            scale: _isDoorOpen ? _scaleAnim.value : 0.9, // 配合动画缩放
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return SecondPage(onBack: _closeDoor);
              },
            ),
          ),

          // --- 层级 2: 左门 ---
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-doorWidth * _doorSlideAnim.value, 0),
                child: child,
              );
            },
            child: Container(
              width: doorWidth,
              height: size.height,
              decoration: const BoxDecoration(
                color: ClaudeColors.background,
                border: Border(
                  right: BorderSide(color: ClaudeColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(5, 0),
                  )
                ],
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 100,
                      color: ClaudeColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- 层级 3: 右门 ---
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(doorWidth * _doorSlideAnim.value, 0),
                child: child, // 这里的 child 是右边的门板
              );
            },
            child: Align(
              alignment: Alignment.centerRight, // 确保靠右
              child: Container(
                width: doorWidth,
                height: size.height,
                decoration: const BoxDecoration(
                  color: ClaudeColors.background,
                  border: Border(
                    left: BorderSide(color: ClaudeColors.border, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(-5, 0),
                    )
                  ],
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 100,
                        color: ClaudeColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- 层级 4: 欢迎页内容 (按钮和文字) ---
          // 这一层需要随着动画消失，不能挡住后面的操作
          IgnorePointer(
            ignoring: _isDoorOpen && _controller.isCompleted,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _contentFadeAnim.value,
                  child: Visibility(
                    visible: _contentFadeAnim.value > 0,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 图标改为更像 Claude 的四角星/火花
                          const Icon(
                            Icons.auto_awesome,
                            size: 64,
                            color: ClaudeColors.accent,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Claude Notes', // 更改标题
                            style: TextStyle(
                              fontSize: 32,
                              fontFamily: 'Georgia', // 衬线体更有文学感
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: ClaudeColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Helpful, harmless, and honest.',
                            style: TextStyle(
                              fontSize: 16,
                              color: ClaudeColors.textMuted,
                              letterSpacing: 0.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 60),
                          if (!_isDoorOpen)
                            InkWell(
                              onTap: _openDoor,
                              borderRadius: BorderRadius.circular(
                                  8), // Claude 风格圆角通常较小，更利落
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 48, vertical: 16),
                                decoration: BoxDecoration(
                                  color: ClaudeColors.surface, // 按钮背景深沉一点
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: ClaudeColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: const Text(
                                  '开卷有益',
                                  style: TextStyle(
                                    color: ClaudeColors.accent, // 文字用焦橙色
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
