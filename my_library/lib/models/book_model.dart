import 'package:flutter/material.dart';

/// 书籍模型
///
/// 代表图书馆中的一本书
class BookModel {
  final String id;
  final String title;
  final int pageCount; // 页数决定厚度
  final Color color;
  final DateTime lastEdited;

  BookModel({
    required this.id,
    required this.title,
    required this.pageCount,
    required this.color,
    required this.lastEdited,
  });
}
