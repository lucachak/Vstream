import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vstream/core/theme/app_theme.dart';
import 'package:vstream/shared/models/movie.dart';
import 'package:vstream/shared/providers/local_movies_provider.dart';
import 'package:vstream/features/browse/presentation/widgets/notification_center_sheet.dart';
import 'package:flutter/services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  bool _appBarSolid = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final solid = _scrollController.offset > 40;
      if (solid != _appBarSolid) setState(() => _appBarSolid = solid);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featured = ref.watch(featuredMovieProvider);
    final byGenre = ref.watch(moviesByGenreProvider);
    final session = ref.watch(sessionProvider);

    // Filter and Sort based on user preferences
    var filteredByGenre = Map<String, List<Movie>>.from(byGenre);
    if (session != null && !session.isAdultContentEnabled) {
      filteredByGenre = filteredByGenre.map((g, list) => MapEntry(
            g,
            list.where((m) => !m.tags.contains('18+') && !m.tags.contains('Adult')).toList(),
          ));
    }

    final genres = filteredByGenre.keys.toList();
    if (session != null && session.favoriteGenres.isNotEmpty) {
      genres.sort((a, b) {
        final aFav = session.favoriteGenres.contains(a);
        final bFav = session.favoriteGenres.contains(b);
        if (aFav && !bFav) return -1;
        if (!aFav && bFav) return 1;
        return 0;
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _appBarSolid
            ? AppColors.bg(context).withAlpha(230)
            : Colors.transparent,
        elevation: 0,
        title: Text(
          'VSTREAM',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.red,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded),
                Positioned(
                  right: 2, top: 2,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => const NotificationCenterSheet(),
              );
            },
          ),
          if (session != null)
            Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/profile');
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(session.avatarColorValue),
                  child: Text(
                    session.name.isNotEmpty ? session.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Hero Banner
          if (featured != null)
            SliverToBoxAdapter(child: _HeroBanner(movie: featured)),

          // Genre rows
          for (final genre in genres)
            if (filteredByGenre[genre]!.isNotEmpty)
              SliverToBoxAdapter(
                child: _GenreRow(
                  genre: genre,
                  movies: filteredByGenre[genre]!,
                ),
              ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends ConsumerWidget {
  final Movie movie;
  const _HeroBanner({required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inWatchlist = ref.watch(sessionProvider
        .select((s) => s?.watchlistIds.contains(movie.id) ?? false));

    return SizedBox(
      height: 520,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop image
          CachedNetworkImage(
            imageUrl:
                movie.backdropUrl.isNotEmpty ? movie.backdropUrl : movie.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: AppColors.bgCard(context),
              highlightColor: AppColors.bgSurface(context),
              child: Container(color: AppColors.bgCard(context)),
            ),
            errorWidget: (_, __, ___) => Container(color: AppColors.bgCard(context)),
            memCacheHeight: 800,
          ),

          // Gradient overlay
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.heroGradient(context)))),

          // Left side gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.bg(context).withAlpha(200), AppColors.bg(context).withAlpha(0)],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre chips
                Wrap(
                  spacing: 6,
                  children: movie.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.textMuted),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context),
                        letterSpacing: 1,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  movie.title,
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    shadows: [
                      const Shadow(blurRadius: 20, color: Colors.black),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Meta row
                Flexible(
                  child: Row(
                    children: [
                        Icon(Icons.star_rounded, color: AppColors.star(context), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        movie.rating.toStringAsFixed(1),
                        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      Text('${movie.year}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(width: 10),
                      Text(movie.duration, style: TextStyle(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  movie.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),

                // Buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push('/player/${movie.id}'),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                      label: const Text('Play', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(sessionProvider.notifier).toggleWatchlist(movie.id);
                      },
                      icon: Icon(
                        inWatchlist ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                        size: 18,
                        color: AppColors.textPrimary(context),
                      ),
                      label: Text(
                        inWatchlist ? 'In My List' : 'My List',
                        style: TextStyle(color: AppColors.textPrimary(context)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        side: BorderSide(color: AppColors.border(context)),
                      ),
                    ),
                    const Spacer(),
                    // More info
                    IconButton(
                      onPressed: () => _showMovieDetail(context, ref, movie),
                      icon: Icon(Icons.info_outline_rounded, color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Genre Row ────────────────────────────────────────────────────────────────

class _GenreRow extends StatelessWidget {
  final String genre;
  final List<Movie> movies;
  const _GenreRow({required this.genre, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                genre,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (context, index) => _MovieCard(movie: movies[index]),
          ),
        ),
      ],
    );
  }
}

// ─── Movie Card ───────────────────────────────────────────────────────────────

class _MovieCard extends ConsumerWidget {
  final Movie movie;
  const _MovieCard({required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showMovieDetail(context, ref, movie),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
              CachedNetworkImage(
                imageUrl: movie.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: AppColors.bgCard(context),
                  highlightColor: AppColors.bgSurface(context),
                  child: Container(color: AppColors.bgCard(context)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.bgCard(context),
                  child: const Icon(Icons.movie_outlined, color: AppColors.textMuted),
                ),
                memCacheHeight: 400,
              ),
              // Bottom gradient + title
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: const BoxDecoration(gradient: AppColors.cardGradient),
                  child: Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Rating badge
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: AppColors.star(context), size: 10),
                      const SizedBox(width: 2),
                      Text(
                        movie.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

// ─── Movie Detail Bottom Sheet ────────────────────────────────────────────────

void _showMovieDetail(BuildContext context, WidgetRef ref, Movie movie) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _MovieDetailSheet(movie: movie, ref: ref),
  );
}

class _MovieDetailSheet extends ConsumerWidget {
  final Movie movie;
  final WidgetRef ref;
  const _MovieDetailSheet({required this.movie, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef consumerRef) {
    final inWatchlist = consumerRef.watch(
        sessionProvider.select((s) => s?.watchlistIds.contains(movie.id) ?? false));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: ctrl,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Backdrop
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: movie.backdropUrl.isNotEmpty
                          ? movie.backdropUrl
                          : movie.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.bgCard(context)),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.bgCard(context)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(movie.title, style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 8),

                  // Meta
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16),
                      const SizedBox(width: 4),
                      Text(movie.rating.toStringAsFixed(1),
                          style: TextStyle(color: AppColors.textSecondary(context))),
                      const SizedBox(width: 12),
                      _Chip(movie.genre),
                      const SizedBox(width: 8),
                      _Chip('${movie.year}'),
                      const SizedBox(width: 8),
                      _Chip(movie.duration),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    movie.description,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tags
                  if (movie.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: movie.tags
                          .map((t) => _Chip(t))
                          .toList(),
                    ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/player/${movie.id}');
                          },
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                          label: const Text('Play Now', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => consumerRef
                              .read(sessionProvider.notifier)
                              .toggleWatchlist(movie.id),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            side: BorderSide(color: AppColors.border(context)),
                          ),
                          child: Icon(
                            inWatchlist
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_add_outlined,
                            color: inWatchlist ? AppColors.red : AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.bgSurface(context),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(color: AppColors.textSecondary(context), fontSize: 11),
        ),
      );
}
