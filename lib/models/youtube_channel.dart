class YouTubeChannel {
  final String id;
  final String channelId;
  final String channelName;
  final DateTime createdAt;

  YouTubeChannel({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.createdAt,
  });

  factory YouTubeChannel.fromJson(Map<String, dynamic> json) {
    return YouTubeChannel(
      id: json['id'],
      channelId: json['channel_id'],
      channelName: json['channel_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'channel_name': channelName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
