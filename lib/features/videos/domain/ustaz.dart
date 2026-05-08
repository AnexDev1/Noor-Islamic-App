class Ustaz {
  final String id;
  final String name;
  final String? bio;
  final String imageUrl;
  final String? channelId;
  final String? playlistId;

  Ustaz({
    required this.id,
    required this.name,
    this.bio,
    required this.imageUrl,
    this.channelId,
    this.playlistId,
  });

  factory Ustaz.fromMap(Map<String, dynamic> map) {
    return Ustaz(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      bio: map['bio'],
      imageUrl: map['imageUrl'] ?? '',
      channelId: map['channelId'],
      playlistId: map['playlistId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'imageUrl': imageUrl,
      'channelId': channelId,
      'playlistId': playlistId,
    };
  }
}
