import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vstream/core/theme/app_theme.dart';
import 'package:vstream/shared/models/movie.dart';
import 'package:vstream/shared/providers/local_movies_provider.dart';

// Search query provider
final _searchQueryProvider = StateProvider<String>((ref) => '');

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);
    final all = ref.watch(allMoviesProvider);
    final byGenre = ref.watch(moviesByGenreProvider);

    final results = query.isEmpty
        ? <Movie>[]
        : all
            .where((m) =>
                m.title.toLowerCase().contains(query.toLowerCase()) ||
                m.genre.toLowerCase().contains(query.toLowerCase()) ||
                m.tags.any(
                    (t) => t.toLowerCase().contains(query.toLowerCase())))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Search',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Search field ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focus.hasFocus ? AppColors.red : AppColors.border(context),
                  ),
                ),
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onChanged: (v) =>
                      ref.read(_searchQueryProvider.notifier).state = v,
                  style: TextStyle(color: AppColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Search titles, genres, tags…',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMuted),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textMuted),
                            onPressed: () {
                              _ctrl.clear();
                              ref
                                  .read(_searchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Results or genre grid ─────────────────────────────────────────
            Expanded(
              child: query.isEmpty
                  ? _GenreBrowse(byGenre: byGenre)
                  : results.isEmpty
                      ? _NoResults(query: query)
                      : _SearchResults(results: results),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Genre Browse (default) ───────────────────────────────────────────────────

class _GenreBrowse extends StatelessWidget {
  final Map<String, List<Movie>> byGenre;
  const _GenreBrowse({required this.byGenre});

  static const _genreColors = {
    'Action': Color(0xFFE53935),
    'Drama': Color(0xFF1E88E5),
    'Sci-Fi': Color(0xFF00ACC1),
    'Animation': Color(0xFF43A047),
    'Comedy': Color(0xFFFB8C00),
    'Horror': Color(0xFF8E24AA),
  };

  Color _colorFor(BuildContext context, String genre) =>
      _genreColors[genre] ?? AppColors.bgSurface(context);

  @override
  Widget build(BuildContext context) {
    final genres = byGenre.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Browse by Genre',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
            ),
            itemCount: genres.length,
            itemBuilder: (ctx, i) {
              final genre = genres[i];
              final color = _colorFor(context, genre);
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Material(
                  color: color.withAlpha(40),
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: color.withAlpha(80)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  genre,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${byGenre[genre]!.length} titles',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: Icon(
                              _iconFor(genre),
                              size: 60,
                              color: color.withAlpha(30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String genre) {
    switch (genre) {
      case 'Action':
        return Icons.bolt_rounded;
      case 'Drama':
        return Icons.theater_comedy_rounded;
      case 'Sci-Fi':
        return Icons.rocket_launch_rounded;
      case 'Animation':
        return Icons.animation_rounded;
      case 'Comedy':
        return Icons.sentiment_very_satisfied_rounded;
      case 'Horror':
        return Icons.nightlight_round;
      default:
        return Icons.movie_rounded;
    }
  }
}

// ─── Search Results ───────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final List<Movie> results;
  const _SearchResults({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: results.length,
      itemBuilder: (ctx, i) => _SearchResultTile(movie: results[i]),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Movie movie;
  const _SearchResultTile({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/player/${movie.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10)),
              child: SizedBox(
                width: 80,
                height: 80,
                child: CachedNetworkImage(
                  imageUrl: movie.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.bgSurface(context),
                    child: const Icon(Icons.movie_outlined,
                        color: AppColors.textMuted),
                  ),
                  memCacheHeight: 200,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _TagChip(movie.genre),
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded,
                            color: AppColors.star(context), size: 12),
                        const SizedBox(width: 2),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: TextStyle(
                              color: AppColors.textSecondary(context), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${movie.year} • ${movie.duration}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.play_circle_outline_rounded,
                  color: AppColors.red, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.bgSurface(context),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                color: AppColors.textSecondary(context), fontSize: 10)),
      );
}

// ─── No Results ───────────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try different keywords or browse by genre',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
