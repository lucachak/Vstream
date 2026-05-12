import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vstream/shared/models/movie.dart';
import 'package:vstream/shared/models/user_profile.dart';

class LocalDbService {
  static const String _moviesBox = 'movies';
  static const String _profileBox = 'profile';
  static const String _sessionBox = 'session';

  static Future<void> init() async {
    await Hive.openBox(_moviesBox);
    await Hive.openBox(_profileBox);
    await Hive.openBox(_sessionBox);

    final box = Hive.box(_moviesBox);
    if (box.isEmpty) {
      await _seedMovies(box);
    }
  }

  // ─── Session ──────────────────────────────────────────────────────────────

  static Future<void> saveSession(UserProfile profile) async {
    final box = Hive.box(_sessionBox);
    await box.put('current_user', jsonEncode(profile.toJson()));
  }

  static UserProfile? loadSession() {
    final box = Hive.box(_sessionBox);
    final raw = box.get('current_user');
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw as String));
  }

  static Future<void> clearSession() async {
    final box = Hive.box(_sessionBox);
    await box.delete('current_user');
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  static Future<void> saveThemeMode(String mode) async {
    final box = Hive.box(_sessionBox);
    await box.put('theme_mode', mode);
  }

  static String? loadThemeMode() {
    final box = Hive.box(_sessionBox);
    return box.get('theme_mode') as String?;
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  static Future<void> saveProfile(UserProfile profile) async {
    final box = Hive.box(_profileBox);
    await box.put(profile.id, jsonEncode(profile.toJson()));
  }

  static UserProfile? loadProfile(String id) {
    final box = Hive.box(_profileBox);
    final raw = box.get(id);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw as String));
  }

  // ─── Movies ───────────────────────────────────────────────────────────────

  static List<Movie> getAllMovies() {
    final box = Hive.box(_moviesBox);
    return box.values
        .map((raw) => Movie.fromJson(jsonDecode(raw as String)))
        .toList();
  }

  static Map<String, List<Movie>> getMoviesByGenre() {
    final movies = getAllMovies();
    final Map<String, List<Movie>> result = {};
    for (final m in movies) {
      result.putIfAbsent(m.genre, () => []).add(m);
    }
    return result;
  }

  static Movie? getFeaturedMovie() {
    final movies = getAllMovies();
    try {
      return movies.firstWhere((m) => m.isFeatured);
    } catch (_) {
      return movies.isNotEmpty ? movies.first : null;
    }
  }

  static Future<void> toggleWatchlist(String userId, String movieId) async {
    final profile = loadProfile(userId);
    if (profile == null) return;
    final list = List<String>.from(profile.watchlistIds);
    if (list.contains(movieId)) {
      list.remove(movieId);
    } else {
      list.add(movieId);
    }
    await saveProfile(profile.copyWith(watchlistIds: list));
    // Also update session
    final session = loadSession();
    if (session?.id == userId) {
      await saveSession(profile.copyWith(watchlistIds: list));
    }
  }

  // ─── Seed Data ────────────────────────────────────────────────────────────

  static Future<void> _seedMovies(Box box) async {
    const movies = _catalog;
    for (final m in movies) {
      await box.put(m.id, jsonEncode(m.toJson()));
    }
  }

  static const List<Movie> _catalog = [
    // FEATURED
    Movie(
      id: 'bbb',
      title: 'Big Buck Bunny',
      description:
          'A large, obese rabbit lives a peaceful life in the forest. Three small animals bully him, stealing his flowers and scaring his friends. He decides to have his revenge using elaborate traps. An epic tale of courage and redemption.',
      thumbnailUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/Big_Buck_Bunny_Screenshot_5.png/640px-Big_Buck_Bunny_Screenshot_5.png',
      backdropUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/Big_Buck_Bunny_Screenshot_5.png/1280px-Big_Buck_Bunny_Screenshot_5.png',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      genre: 'Animation',
      rating: 8.1,
      year: 2008,
      duration: '9m 56s',
      isFeatured: true,
      tags: ['Comedy', 'Family', 'Open Source'],
    ),
    Movie(
      id: 'ed',
      title: 'Elephants Dream',
      description:
          'Two strange characters explore a capricious and seemingly infinite machine. The elder, Proog, insists the machine is wonderful, while the younger Emo, struggles to find meaning in it all.',
      thumbnailUrl:
          'https://upload.wikimedia.org/wikipedia/commons/e/e8/Elephants_Dream_s1_proog.jpg',
      backdropUrl:
          'https://upload.wikimedia.org/wikipedia/commons/e/e8/Elephants_Dream_s1_proog.jpg',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      genre: 'Sci-Fi',
      rating: 7.4,
      year: 2006,
      duration: '10m 54s',
      tags: ['Surreal', 'Open Source', 'Animation'],
    ),
    Movie(
      id: 'subaru',
      title: 'Subaru Outback',
      description:
          'Experience the power and versatility of the Subaru Outback. Adventure awaits around every corner in this award-winning SUV built for those who dare to explore.',
      thumbnailUrl:
          'https://picsum.photos/seed/subaru/400/600',
      backdropUrl: 'https://picsum.photos/seed/subaru/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
      genre: 'Action',
      rating: 6.8,
      year: 2023,
      duration: '2m 21s',
      tags: ['Adventure', 'Cars'],
    ),
    Movie(
      id: 'teaarsenal',
      title: 'We Are Going to Ibiza',
      description:
          'A wild comedy road trip to Ibiza with friends who have nothing in common except their love of adventure, music, and questionable decisions.',
      thumbnailUrl: 'https://picsum.photos/seed/ibiza/400/600',
      backdropUrl: 'https://picsum.photos/seed/ibiza/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
      genre: 'Comedy',
      rating: 7.1,
      year: 2020,
      duration: '1h 32m',
      tags: ['Road Trip', 'Friends'],
    ),
    Movie(
      id: 'fordv',
      title: 'Ford vs Ferrari',
      description:
          'American car designer Carroll Shelby and fearless British driver Ken Miles battle corporate interference, the laws of physics, and their own personal demons to build a race car for Ford.',
      thumbnailUrl: 'https://picsum.photos/seed/fordrace/400/600',
      backdropUrl: 'https://picsum.photos/seed/fordrace/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      genre: 'Action',
      rating: 8.3,
      year: 2019,
      duration: '2h 32m',
      tags: ['Racing', 'True Story', 'Drama'],
    ),
    Movie(
      id: 'jbj',
      title: 'Joy & Escape',
      description:
          'A breathtaking escape through neon-lit cities and desert highways. When everything falls apart, two strangers find freedom, laughter and something unexpected.',
      thumbnailUrl: 'https://picsum.photos/seed/joyescape/400/600',
      backdropUrl: 'https://picsum.photos/seed/joyescape/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      genre: 'Drama',
      rating: 7.9,
      year: 2022,
      duration: '1h 48m',
      tags: ['Romance', 'Travel'],
    ),
    Movie(
      id: 'fnf1',
      title: 'Chrome & Thunder',
      description:
          'The streets never sleep. A crew of elite street racers must outrun a corrupt task force determined to destroy everything they built.',
      thumbnailUrl: 'https://picsum.photos/seed/chrome/400/600',
      backdropUrl: 'https://picsum.photos/seed/chrome/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      genre: 'Action',
      rating: 7.5,
      year: 2023,
      duration: '1h 58m',
      tags: ['Cars', 'Heist', 'Adrenaline'],
    ),
    Movie(
      id: 'tear',
      title: 'Tears of Steel',
      description:
          'In Amsterdam a group of warriors fights to defend Earth from an army of robots. A gritty sci-fi short film with stunning VFX and an emotional core.',
      thumbnailUrl: 'https://picsum.photos/seed/tearssteel/400/600',
      backdropUrl: 'https://picsum.photos/seed/tearssteel/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      genre: 'Sci-Fi',
      rating: 7.2,
      year: 2012,
      duration: '12m',
      tags: ['Robots', 'Open Source', 'VFX'],
    ),
    Movie(
      id: 'cosmos',
      title: 'Cosmos Laundromat',
      description:
          'On a desolate island, a suicidal sheep meets his fate in the form of Franck, a well-intentioned but inept god-figure who offers him the gift of a lifetime.',
      thumbnailUrl: 'https://picsum.photos/seed/cosmos/400/600',
      backdropUrl: 'https://picsum.photos/seed/cosmos/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      genre: 'Animation',
      rating: 7.7,
      year: 2015,
      duration: '12m',
      tags: ['Philosophical', 'Open Source'],
    ),
    Movie(
      id: 'sintel',
      title: 'Sintel',
      description:
          'A lonely young woman, Sintel, is searching for her lost friend, a small dragon she calls Scales. Her quest leads her through vast and treacherous lands. A short but masterful animated film.',
      thumbnailUrl: 'https://picsum.photos/seed/sintel/400/600',
      backdropUrl: 'https://picsum.photos/seed/sintel/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      genre: 'Animation',
      rating: 8.0,
      year: 2010,
      duration: '14m 48s',
      tags: ['Fantasy', 'Dragons', 'Open Source'],
    ),
    Movie(
      id: 'moto1',
      title: 'Desert Riders',
      description:
          'Three motorcycle daredevils race through the Sahara chasing an ancient legend. High octane action meets breathtaking visuals in this sun-scorched adventure.',
      thumbnailUrl: 'https://picsum.photos/seed/desert/400/600',
      backdropUrl: 'https://picsum.photos/seed/desert/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
      genre: 'Action',
      rating: 7.3,
      year: 2021,
      duration: '1h 44m',
      tags: ['Motorcycles', 'Desert', 'Thriller'],
    ),
    Movie(
      id: 'laugh1',
      title: 'The Misunderstanding',
      description:
          'A perfectly ordinary man accidentally becomes the most wanted person in the city due to a comical chain of misidentifications. Hilarity ensues.',
      thumbnailUrl: 'https://picsum.photos/seed/misunder/400/600',
      backdropUrl: 'https://picsum.photos/seed/misunder/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      genre: 'Comedy',
      rating: 7.8,
      year: 2019,
      duration: '1h 38m',
      tags: ['Slapstick', 'Mistaken Identity'],
    ),
    Movie(
      id: 'noir1',
      title: 'Midnight Protocol',
      description:
          'A veteran detective is pulled back into the underworld she swore to leave behind when her former partner is found dead with a cryptic message in his pocket.',
      thumbnailUrl: 'https://picsum.photos/seed/midnight/400/600',
      backdropUrl: 'https://picsum.photos/seed/midnight/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      genre: 'Drama',
      rating: 8.2,
      year: 2022,
      duration: '2h 4m',
      tags: ['Noir', 'Crime', 'Mystery'],
    ),
    Movie(
      id: 'space1',
      title: 'Orbital Drift',
      description:
          'When a rogue satellite disrupts Earth\'s communications, a crew of astronauts must venture outside the station on the most dangerous EVA in history.',
      thumbnailUrl: 'https://picsum.photos/seed/orbital/400/600',
      backdropUrl: 'https://picsum.photos/seed/orbital/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      genre: 'Sci-Fi',
      rating: 8.4,
      year: 2024,
      duration: '1h 56m',
      tags: ['Space', 'Survival', 'Thriller'],
    ),
    Movie(
      id: 'horror1',
      title: 'The Hollow Hour',
      description:
          'Every night at 3am, the lights flicker and the shadows whisper. A family moves into their dream home only to discover the previous owners never truly left.',
      thumbnailUrl: 'https://picsum.photos/seed/hollow/400/600',
      backdropUrl: 'https://picsum.photos/seed/hollow/1280/720',
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      genre: 'Horror',
      rating: 7.6,
      year: 2023,
      duration: '1h 42m',
      tags: ['Haunted', 'Supernatural', 'Atmospheric'],
    ),
  ];
}
