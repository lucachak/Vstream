import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vstream/core/theme/app_theme.dart';
import 'package:vstream/shared/models/movie.dart';
import 'package:vstream/shared/providers/local_movies_provider.dart';

class MyListScreen extends ConsumerWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final watchlist = ref.watch(watchlistMoviesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My List',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  if (watchlist.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${watchlist.length} saved',
                        style: TextStyle(
                            color: AppColors.textSecondary(context), fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Movies and shows you\'ve saved',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: session == null
                  ? _NotLoggedInState()
                  : watchlist.isEmpty
                      ? _EmptyState()
                      : _WatchlistGrid(movies: watchlist, ref: ref),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Watchlist Grid ───────────────────────────────────────────────────────────

class _WatchlistGrid extends StatelessWidget {
  final List<Movie> movies;
  final WidgetRef ref;
  const _WatchlistGrid({required this.movies, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: movies.length,
      itemBuilder: (ctx, i) => _WatchlistCard(movie: movies[i], ref: ref),
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  final Movie movie;
  final WidgetRef ref;
  const _WatchlistCard({required this.movie, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: movie.thumbnailUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: AppColors.bgCard(context),
                child: const Icon(Icons.movie_outlined,
                    color: AppColors.textMuted),
              ),
              memCacheHeight: 300,
            ),
            // Bottom gradient + title
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 30, 8, 8),
                decoration: const BoxDecoration(gradient: AppColors.cardGradient),
                child: Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
            // Long press hint
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xCC000000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bookmark_rounded,
                    color: AppColors.red, size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 48,
                      height: 64,
                      child: CachedNetworkImage(
                        imageUrl: movie.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.bgCard(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(movie.title,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                                fontSize: 14)),
                        Text(
                            '${movie.year} • ${movie.duration}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.border(context), height: 1),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded, color: AppColors.red),
              title: Text('Play Now',
                  style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(context);
                context.push('/player/${movie.id}');
              },
            ),
            ListTile(
              leading: Icon(Icons.bookmark_remove_outlined,
                  color: AppColors.textSecondary(context)),
              title: Text('Remove from My List',
                  style: TextStyle(color: AppColors.textSecondary(context))),
              onTap: () {
                ref.read(sessionProvider.notifier).toggleWatchlist(movie.id);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Empty States ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgCard(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(context)),
            ),
            child: const Icon(Icons.bookmark_add_outlined,
                size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text(
            'Your list is empty',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save movies from the home screen\nto watch them later',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_rounded, size: 18, color: Colors.white),
            label: const Text('Browse Movies'),
          ),
        ],
      ),
    );
  }
}

class _NotLoggedInState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Sign in to save movies',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
