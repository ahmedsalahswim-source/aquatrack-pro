import 'package:equatable/equatable.dart';

class WebSearchResult extends Equatable {
  final String title;
  final String snippet;
  final String url;
  final String source;

  const WebSearchResult({
    required this.title,
    required this.snippet,
    required this.url,
    this.source = 'web',
  });

  String get sourceLabel {
    switch (source) {
      case 'duckduckgo':
        return '🌐 DuckDuckGo';
      case 'wikipedia':
        return '📖 Wikipedia';
      case 'trusted':
        return '✅ ${Uri.tryParse(url)?.host ?? 'مصدر موثوق'}';
      default:
        return '🌐 $source';
    }
  }

  @override
  List<Object?> get props => [title, url, source];
}
