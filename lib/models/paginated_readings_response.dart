import 'reading_model.dart';

class PaginatedReadingsResponse {
  final List<ReadingModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  PaginatedReadingsResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory PaginatedReadingsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['content'] as List<dynamic>? ?? const [];
    return PaginatedReadingsResponse(
      content: list
          .whereType<Map<String, dynamic>>()
          .map(ReadingModel.fromJson)
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
