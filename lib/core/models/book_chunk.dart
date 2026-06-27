import 'package:equatable/equatable.dart';

class BookSection extends Equatable {
  final String level; // 'book', 'part', 'chapter', 'section', 'subsection'
  final String title;
  final int? pageNumber;

  const BookSection({
    required this.level,
    required this.title,
    this.pageNumber,
  });

  Map<String, dynamic> toJson() => {
    'level': level,
    'title': title,
    'pageNumber': pageNumber,
  };

  factory BookSection.fromJson(Map<String, dynamic> json) => BookSection(
    level: json['level'] as String,
    title: json['title'] as String,
    pageNumber: json['pageNumber'] as int?,
  );

  @override
  List<Object?> get props => [level, title, pageNumber];
}

class BookChunk extends Equatable {
  final String id;
  final String bookTitle;
  final List<BookSection> hierarchy;
  final String content;
  final int chunkIndex;
  final int totalChunks;
  final int totalChapters;

  const BookChunk({
    required this.id,
    required this.bookTitle,
    required this.hierarchy,
    required this.content,
    required this.chunkIndex,
    required this.totalChunks,
    this.totalChapters = 1,
  });

  String get chapterTitle {
    final ch = hierarchy.where((h) => h.level == 'chapter').toList();
    return ch.isNotEmpty ? ch.last.title : 'عام';
  }

  String get sectionTitle {
    final sc = hierarchy.where((h) => h.level == 'section').toList();
    return sc.isNotEmpty ? sc.last.title : '';
  }

  String get pathLabel {
    return hierarchy.map((h) => h.title).join(' > ');
  }

  String get sourceLabel {
    final parts = <String>[bookTitle];
    for (final h in hierarchy) {
      if (h.level == 'part') {
        parts.add('الباب ${h.title}');
      } else if (h.level == 'chapter') {
        parts.add(h.title);
      } else if (h.level == 'section') {
        parts.add(h.title);
      }
    }
    return parts.join(' > ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookTitle': bookTitle,
    'hierarchy': hierarchy.map((h) => h.toJson()).toList(),
    'content': content,
    'chunkIndex': chunkIndex,
    'totalChunks': totalChunks,
    'totalChapters': totalChapters,
  };

  factory BookChunk.fromJson(Map<String, dynamic> json) => BookChunk(
    id: json['id'] as String,
    bookTitle: json['bookTitle'] as String,
    hierarchy: (json['hierarchy'] as List<dynamic>)
        .map((e) => BookSection.fromJson(e as Map<String, dynamic>))
        .toList(),
    content: json['content'] as String,
    chunkIndex: json['chunkIndex'] as int,
    totalChunks: json['totalChunks'] as int,
    totalChapters: json['totalChapters'] as int? ?? 1,
  );

  @override
  List<Object?> get props => [id, bookTitle, chunkIndex, content];
}
