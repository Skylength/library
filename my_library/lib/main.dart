import 'package:flutter/material.dart';
import 'themes/colors.dart';
import 'pages/door_transition_page.dart';

/// My Library - 一个带有推门动画效果的图书馆应用
///
/// 这个应用展示了：
/// - Claude 风格的暗色主题设计
/// - 流畅的推门过渡动画
/// - 书架式的笔记展示界面
void main() {
  runApp(const MyApp());
}

/// 应用根组件
///
/// 配置全局主题和启动页面
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obsidian Library',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ClaudeColors.background,
        useMaterial3: true,
        // 自定义字体样式
        fontFamily: 'Roboto', // 或者使用类似 Inter/Menlo 的字体
        colorScheme: const ColorScheme.dark(
          primary: ClaudeColors.accent,
          surface: ClaudeColors.surface,
          onSurface: ClaudeColors.textMain,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: ClaudeColors.surface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: ClaudeColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
          iconTheme: IconThemeData(color: ClaudeColors.textMuted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ClaudeColors.accent,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(8), // Obsidian 风格通常圆角较小
            ),
          ),
        ),
      ),
      home: const DoorTransitionPage(),
    );
  }
}
