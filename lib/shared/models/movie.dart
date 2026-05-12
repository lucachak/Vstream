class Movie {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String backdropUrl;
  final String videoUrl;
  final String genre;
  final double rating;
  final int year;
  final String duration;
  final bool isFeatured;
  final List<String> tags;

  const Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.backdropUrl = '',
    required this.videoUrl,
    required this.genre,
    this.rating = 7.5,
    required this.year,
    this.duration = '1h 30m',
    this.isFeatured = false,
    this.tags = const [],
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      backdropUrl: (json['backdrop_url'] as String?) ?? '',
      videoUrl: json['video_url'] as String,
      genre: (json['genre'] as String?) ?? 'Other',
      rating: ((json['rating'] as num?) ?? 7.5).toDouble(),
      year: (json['year'] as int?) ?? 2024,
      duration: (json['duration'] as String?) ?? '1h 30m',
      isFeatured: (json['is_featured'] as bool?) ?? false,
      tags: ((json['tags'] as List?)?.cast<String>()) ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'thumbnail_url': thumbnailUrl,
        'backdrop_url': backdropUrl,
        'video_url': videoUrl,
        'genre': genre,
        'rating': rating,
        'year': year,
        'duration': duration,
        'is_featured': isFeatured,
        'tags': tags,
      };
}
