/// 笔记/便利贴模型
///
/// 代表一个便利贴或笔记卡片
class NoteModel {
  final String id;
  final String content;
  final String tag;

  NoteModel({
    required this.id,
    required this.content,
    required this.tag,
  });
}
