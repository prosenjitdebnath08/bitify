enum MusicSource {
  youtube,
  spotify,
  jiosaavn,
  local;

  String get displayName {
    switch (this) {
      case MusicSource.youtube:
        return 'YouTube';
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
  final String language;
  final String genre;
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
    this.language = 'English',
    this.genre = 'Pop',
    this.lyrics = const [],
  });

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationSeconds': durationSeconds,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'source': source.name,
      'isLossless': isLossless,
      'isDolbyAtmos': isDolbyAtmos,
      'isLiked': isLiked,
      'language': language,
      'genre': genre,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    MusicSource src = MusicSource.spotify;
    try {
      src = MusicSource.values.byName(json['source'] ?? 'spotify');
    } catch (_) {}
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown Artist',
      album: json['album'] ?? 'Unknown Album',
      durationSeconds: json['durationSeconds'] ?? 200,
      coverUrl: json['coverUrl'] ?? '',
      audioUrl: json['audioUrl'],
      source: src,
      isLossless: json['isLossless'] ?? true,
      isDolbyAtmos: json['isDolbyAtmos'] ?? false,
      isLiked: json['isLiked'] ?? false,
      language: json['language'] ?? 'English',
      genre: json['genre'] ?? 'Pop',
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
  final MusicSource source;

  const Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    this.songs = const [],
    this.isCustom = false,
    this.source = MusicSource.spotify,
  });
}
