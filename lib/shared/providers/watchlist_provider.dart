import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';
import '../models/movie.dart';

final watchlistProvider = AsyncNotifierProvider<WatchlistNotifier, List<Movie>>(WatchlistNotifier.new);

class WatchlistNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() async {
    final client = ref.watch(supabaseClientProvider);
    if (client == null) return [];
    
    final user = client.auth.currentUser;
    if (user == null) return [];

    final response = await client
        .from('watchlist')
        .select('*, movies(*)')
        .eq('user_id', user.id);

    return (response as List).map((item) => Movie.fromJson(item['movies'])).toList();
  }

  Future<void> addToWatchlist(Movie movie) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.from('watchlist').insert({
      'user_id': user.id,
      'movie_id': movie.id,
    });
    
    ref.invalidateSelf();
  }

  Future<void> removeFromWatchlist(String movieId) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    final user = client.auth.currentUser;
    if (user == null) return;

    await client
        .from('watchlist')
        .delete()
        .eq('user_id', user.id)
        .eq('movie_id', movieId);
    
    ref.invalidateSelf();
  }
}
