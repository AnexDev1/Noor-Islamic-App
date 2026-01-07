import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoService {
  final YoutubeExplode _yt = YoutubeExplode();

  // Temporary list of channel IDs - Replace with real IDs from usage
  // final List<String> _channelIds = [
  //   // Add channel IDs here
  //   "UCoOae5nYA7VqaXzerajD0lg",
  //   "UCTX8ZbNDi_HBoyjTWRw9fAg",
  // ];

  Future<List<Video>> fetchVideosFromChannels(List<String> channelUrls) async {
    final List<Video> allVideos = [];

    for (final url in channelUrls) {
      try {
        ChannelId id;
        if (url.contains('/channel/')) {
          final part = url.split('/channel/').last;
          id = ChannelId(part.split('?').first);
        } else if (url.contains('@')) {
          var handle = url.substring(url.indexOf('@'));
          if (handle.contains('?')) handle = handle.split('?').first;
          if (handle.contains('/')) handle = handle.split('/').first;

          final channel = await _yt.channels.getByHandle(handle);
          id = channel.id;
        } else {
          id = ChannelId(url.split('?').first);
        }

        final uploads = await _yt.channels.getUploads(id).take(10).toList();
        allVideos.addAll(uploads);
      } catch (e) {
        // ignore: avoid_print
        print('Error fetching from $url: $e');
      }
    }

    // Sort by upload date if possible, currently just mixing them
    allVideos.shuffle();
    return allVideos;
  }

  void dispose() {
    _yt.close();
  }
}
