import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vstream/core/theme/app_theme.dart';
import 'package:vstream/shared/providers/local_movies_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String videoId;
  const PlayerScreen({super.key, required this.videoId});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Force landscape when playing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final movie = ref.read(movieByIdProvider(widget.videoId));
    final url = movie?.videoUrl ??
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

    try {
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoCtrl!.initialize();

      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoCtrl!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.red,
          handleColor: AppColors.red,
          bufferedColor: AppColors.redGlow,
          backgroundColor: const Color(0xFF1A1A1A),
        ),
        errorBuilder: (ctx, msg) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'Playback Error',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(msg,
                  style: TextStyle(
                      color: AppColors.textSecondary(ctx), fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    // Reset orientations
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movie = ref.watch(movieByIdProvider(widget.videoId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ── Video player ──────────────────────────────────────────────────
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _initializing
                    ? const _LoadingView()
                    : _error != null
                        ? _ErrorView(error: _error!)
                        : Chewie(controller: _chewieCtrl!),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 10,
                child: ClipOval(
                  child: Material(
                    color: Colors.black.withAlpha(120),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Info panel ────────────────────────────────────────────────────
          Expanded(
            child: Container(
              color: AppColors.bg(context),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (movie != null) ...[
                    // Title
                    Text(
                      movie.title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Meta
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: AppColors.star(context), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: TextStyle(
                              color: AppColors.textSecondary(context), fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        _MetaChip(movie.genre),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/player/${movie.id}');
                          },
                          child: _MetaChip('${movie.year}'),
                        ),
                        const SizedBox(width: 6),
                        _MetaChip(movie.duration),
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
                    const SizedBox(height: 20),
                    // Tags
                    if (movie.tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: movie.tags
                            .map((t) => _MetaChip(t))
                            .toList(),
                      ),
                  ] else ...[
                    Text(
                      'Playing video…',
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Back button overlay ──────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black),
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.red, strokeWidth: 2),
              SizedBox(height: 16),
              Text('Loading…',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.red, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load video',
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(error,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip(this.label);

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
