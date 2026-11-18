enum MusicSource {
  youtube,
  spotify,
  jiosaavn,
  local;

  String get displayName {
    switch (this) {
      case MusicSource.youtube:
        return 'YouTube Music';
      case MusicSource.spotify:
        return 'Spotify';
      case MusicSource.jiosaavn:
        return 'JioSaavn';
      case MusicSource.local:
        return 'Local Storage';
    }
  }

  String get iconName {
    switch (this) {
      case MusicSource.youtube:
        return 'YT';
      case MusicSource.spotify:
        return 'SP';
      case MusicSource.jiosaavn:
        return 'JS';
      case MusicSource.local:
        return 'FL';
    }
  }
}

class LyricLine {
  final int second;
  final String text;

  const LyricLine({required this.second, required this.text});
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationSeconds;
  final String coverUrl;
  final String? audioUrl;
  final MusicSource source;
  final bool isLossless;
  final bool isDolbyAtmos;
  final bool isLiked;
  final List<LyricLine> lyrics;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSeconds,
    required this.coverUrl,
    this.audioUrl,
    this.source = MusicSource.youtube,
    this.isLossless = true,
    this.isDolbyAtmos = false,
    this.isLiked = false,
    this.lyrics = const [],
  });

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? durationSeconds,
    String? coverUrl,
    String? audioUrl,
    MusicSource? source,
    bool? isLossless,
    bool? isDolbyAtmos,
    bool? isLiked,
    List<LyricLine>? lyrics,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      source: source ?? this.source,
      isLossless: isLossless ?? this.isLossless,
      isDolbyAtmos: isDolbyAtmos ?? this.isDolbyAtmos,
      isLiked: isLiked ?? this.isLiked,
      lyrics: lyrics ?? this.lyrics,
    );
  }
}

class Album {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final int year;
  final List<Song> songs;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.year,
    this.songs = const [],
  });
}

class Artist {
  final String id;
  final String name;
  final String avatarUrl;
  final String monthlyListeners;
  final List<String> genres;

  const Artist({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.monthlyListeners,
    this.genres = const [],
  });
}

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<Song> songs;
  final bool isCustom;

  const Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    this.songs = const [],
    this.isCustom = false,
  });
}
