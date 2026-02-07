import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class VideoItem {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final int? durationSeconds;
  final String? uploadDateIso;
  final int? viewCount;
  final int? likeCount;

  VideoItem({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    this.durationSeconds,
    this.uploadDateIso,
    this.viewCount,
    this.likeCount,
  });

  factory VideoItem.fromYt(yt.Video v) {
    return VideoItem(
      id: v.id.value,
      title: v.title,
      author: v.author,
      thumbnailUrl: v.thumbnails.highResUrl,
      durationSeconds: v.duration?.inSeconds,
      uploadDateIso: v.uploadDate?.toIso8601String(),
      viewCount: v.engagement.viewCount,
      likeCount: v.engagement.likeCount,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'uploadDateIso': uploadDateIso,
        'viewCount': viewCount,
        'likeCount': likeCount,
      };

  factory VideoItem.fromMap(Map<String, dynamic> m) => VideoItem(
        id: m['id'] as String,
        title: m['title'] as String,
        author: m['author'] as String,
        thumbnailUrl: m['thumbnailUrl'] as String,
        durationSeconds: m['durationSeconds'] as int?,
        uploadDateIso: m['uploadDateIso'] as String?,
        viewCount: m['viewCount'] as int?,
        likeCount: m['likeCount'] as int?,
      );

  DateTime? get uploadDate =>
      uploadDateIso != null ? DateTime.tryParse(uploadDateIso!) : null;
}
