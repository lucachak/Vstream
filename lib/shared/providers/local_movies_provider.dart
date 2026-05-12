import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vstream/shared/models/movie.dart';
import 'package:vstream/shared/models/user_profile.dart';
import 'package:vstream/shared/services/auth_service.dart';
import 'package:vstream/shared/services/local_db_service.dart';

// ─── Movie Providers ──────────────────────────────────────────────────────────

final allMoviesProvider = Provider<List<Movie>>((ref) {
  return LocalDbService.getAllMovies();
});

final moviesByGenreProvider = Provider<Map<String, List<Movie>>>((ref) {
  return LocalDbService.getMoviesByGenre();
});

final featuredMovieProvider = Provider<Movie?>((ref) {
  return LocalDbService.getFeaturedMovie();
});

final movieByIdProvider = Provider.family<Movie?, String>((ref, id) {
  final movies = ref.watch(allMoviesProvider);
  try {
    return movies.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
});

// ─── Session / Auth ───────────────────────────────────────────────────────────

class SessionNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => AuthService.currentUser();

  Future<AuthResult> signIn(String email, String password) async {
    final result = await AuthService.signIn(email, password);
    if (result.success) state = result.profile;
    return result;
  }

  Future<AuthResult> signUp(String name, String email, String password) async {
    final result = await AuthService.signUp(name, email, password);
    if (result.success) state = result.profile;
    return result;
  }

  Future<void> logout() async {
    await AuthService.signOut();
    state = null;
  }

  Future<AuthResult> deleteAccount() async {
    final result = await AuthService.deleteAccount();
    if (result.success) state = null;
    return result;
  }

  Future<AuthResult> signInAsGuest() async {
    final result = await AuthService.signInAsGuest();
    if (result.success) state = result.profile;
    return result;
  }

  Future<void> toggleWatchlist(String movieId) async {
    final current = state;
    if (current == null) return;
    await LocalDbService.toggleWatchlist(current.id, movieId);
    state = LocalDbService.loadSession();
  }

  Future<void> updateProfile(UserProfile profile) async {
    await LocalDbService.saveProfile(profile);
    await LocalDbService.saveSession(profile);
    state = profile;
  }

  bool isInWatchlist(String movieId) =>
      state?.watchlistIds.contains(movieId) ?? false;
}

final sessionProvider = NotifierProvider<SessionNotifier, UserProfile?>(
  SessionNotifier.new,
);

final watchlistMoviesProvider = Provider<List<Movie>>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return [];
  final all = ref.watch(allMoviesProvider);
  return all.where((m) => session.watchlistIds.contains(m.id)).toList();
});
