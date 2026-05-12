import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vstream/core/theme/app_theme.dart';
import 'package:vstream/shared/models/user_profile.dart';
import 'package:vstream/shared/models/movie.dart';
import 'package:vstream/shared/providers/local_movies_provider.dart';
import 'package:vstream/shared/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final watchlist = ref.watch(watchlistMoviesProvider);

    if (session == null) {
      return _NotLoggedIn();
    }

    final initial = session.name.isNotEmpty ? session.name[0].toUpperCase() : 'G';
    final avatarColor = Color(session.avatarColorValue);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF150000), AppColors.bg(context)],
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          avatarColor,
                          Color.lerp(avatarColor, Colors.black, 0.5)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: avatarColor.withAlpha(100),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    session.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Member badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: session.plan == SubscriptionPlan.vip 
                        ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)])
                        : AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${session.plan.label} MEMBER',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── My Watchlist ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              icon: Icons.bookmark_rounded,
              title: 'My List',
              count: watchlist.length,
            ),
          ),
          SliverToBoxAdapter(
            child: watchlist.isEmpty
                ? const _EmptyState(
                    icon: Icons.bookmark_add_outlined,
                    message: 'Movies you save will appear here',
                  )
                : SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: watchlist.length,
                      itemBuilder: (ctx, i) =>
                          _MiniMovieCard(movie: watchlist[i]),
                    ),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Stats row ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  _StatCard(label: 'Saved', value: '${watchlist.length}'),
                  const SizedBox(width: 12),
                  const _StatCard(label: 'Watched', value: '0'),
                  const SizedBox(width: 12),
                  const _StatCard(label: 'Reviews', value: '0'),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Settings ────────────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: _SectionHeader(
              icon: Icons.settings_rounded,
              title: 'Settings',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Account Settings',
                    subtitle: 'Manage profile & subscription',
                    onTap: () => context.go('/profile/account'),
                  ),
                  _SettingsTile(
                    icon: Icons.dark_mode_rounded,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: ref.watch(themeProvider) == ThemeMode.dark,
                      onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                      activeColor: AppColors.red,
                      inactiveTrackColor: AppColors.textSecondary(context).withAlpha(50),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'New releases & updates',
                    trailing: Switch(
                      value: false,
                      onChanged: (_) {},
                      activeColor: AppColors.red,
                      inactiveTrackColor: AppColors.border(context),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.hd_outlined,
                    title: 'Streaming Quality',
                    subtitle: 'Auto (recommended)',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {},
                  ),
                  const _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'App Version',
                    subtitle: '1.0.0',
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove your data',
                    isDanger: true,
                    onTap: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Sign Out ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(sessionProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: Icon(Icons.logout_rounded,
                      size: 18, color: AppColors.textSecondary(context)),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.border(context)),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// ─── Delete Account Confirmation ──────────────────────────────────────────────

Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      title: Text(
        'Delete Account?',
        style: TextStyle(
            color: AppColors.textPrimary(context), fontWeight: FontWeight.w700),
      ),
      content: Text(
        'This will permanently delete your account and all saved data. '
        'This action cannot be undone.',
        style: TextStyle(
            color: AppColors.textSecondary(context), fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary(context))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCF6679),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Delete',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final result = await ref.read(sessionProvider.notifier).deleteAccount();

  if (!context.mounted) return;
  if (result.success) {
    context.go('/login');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.error ?? 'Failed to delete account.'),
        backgroundColor: const Color(0xFFCF6679),
      ),
    );
  }
}

// ─── Not Logged In ────────────────────────────────────────────────────────────

class _NotLoggedIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined,
                size: 72, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Not signed in',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Sign in to access your profile',
                style: TextStyle(color: AppColors.textSecondary(context))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;

  const _SectionHeader({required this.icon, required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.red, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bgSurface(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    color: AppColors.textSecondary(context), fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Mini Movie Card ──────────────────────────────────────────────────────────

class _MiniMovieCard extends StatelessWidget {
  final Movie movie;
  const _MiniMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
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
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
                decoration: const BoxDecoration(
                  gradient: AppColors.cardGradient,
                ),
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
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDanger;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.error(context) : AppColors.textPrimary(context);
    final iconColor = isDanger ? AppColors.error(context) : AppColors.textSecondary(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDanger
                  ? AppColors.error(context).withAlpha(40)
                  : AppColors.border(context).withAlpha(80)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight:
                              isDanger ? FontWeight.w600 : FontWeight.normal)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(
                            color: isDanger
                                ? const Color(0xFFCF6679).withAlpha(150)
                                : AppColors.textMuted,
                            fontSize: 12)),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right_rounded,
                        color: isDanger
                            ? const Color(0xFFCF6679).withAlpha(100)
                            : AppColors.textMuted,
                        size: 18)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 36),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
