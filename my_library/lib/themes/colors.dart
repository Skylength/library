import 'package:flutter/material.dart';

/// Claude 风格配色方案 (Warm Dark Mode)
///
/// 使用暖色调的暗色系配色，营造舒适的阅读氛围
class ClaudeColors {
  static const Color background = Color(0xFF262523);
  static const Color surface = Color(0xFF373532);
  static const Color accent = Color(0xFFD97757);
  static const Color textMain = Color(0xFFF0EBE6);
  static const Color textMuted = Color(0xFF9E9A95);
  static const Color border = Color(0xFF454340);

  /// 书脊的配色盘 (低饱和度的暖色系)
  static const List<Color> bookSpines = [
    Color(0xFF8D6E63), // 棕色
    Color(0xFF5D4037), // 深棕
    Color(0xFFD97757), // 焦橙 (Accent)
    Color(0xFF795548), // 褐色
    Color(0xFF4E342E), // 深咖
    Color(0xFF616161), // 深灰
    Color(0xFF757575), // 灰
    Color(0xFF3E2723), // 极深棕
  ];
}
