/// VStream — Unified Auth Service
///
/// Switches automatically between Supabase (when [Env.isConfigured]) and a
/// local Hive fallback so the app is fully functional without credentials.
///
/// ─── Supabase setup (one-time) ───────────────────────────────────────────────
/// Run the following in your Supabase SQL Editor to enable account deletion:
///
///   CREATE OR REPLACE FUNCTION public.delete_user()
///   RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
///   BEGIN DELETE FROM auth.users WHERE id = auth.uid(); END; $$;
///
///   GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;
///
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vstream/core/config/env.dart';
import 'package:vstream/shared/models/user_profile.dart';
import 'package:vstream/shared/services/local_db_service.dart';

class AuthResult {
  final bool success;
  final String? error;
  final UserProfile? profile;

  const AuthResult({required this.success, this.error, this.profile});
}

class AuthService {
  AuthService._();

  // ─── Internal helpers ───────────────────────────────────────────────────────

  static SupabaseClient? get _sb =>
      Env.isConfigured ? Supabase.instance.client : null;

  static UserProfile _profileFromSupabaseUser(User user) {
    final cached = LocalDbService.loadProfile(user.id);
    return UserProfile(
      id: user.id,
      name: (user.userMetadata?['name'] as String?)?.isNotEmpty == true
          ? user.userMetadata!['name'] as String
          : (user.email ?? '').split('@').first,
      email: user.email ?? '',
      avatarColorValue: 0xFFE50914,
      watchlistIds: cached?.watchlistIds ?? [],
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Returns the currently authenticated user, or null.
  static UserProfile? currentUser() {
    if (_sb != null) {
      final user = _sb!.auth.currentUser;
      if (user == null) return null;
      return _profileFromSupabaseUser(user);
    }
    return LocalDbService.loadSession();
  }

  /// Sign in with email + password.
  static Future<AuthResult> signIn(String email, String password) async {
    if (_sb != null) {
      try {
        final res = await _sb!.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = res.user;
        if (user == null) {
          return const AuthResult(success: false, error: 'Sign-in failed.');
        }
        final profile = _profileFromSupabaseUser(user);
        await LocalDbService.saveProfile(profile);
        await LocalDbService.saveSession(profile);
        return AuthResult(success: true, profile: profile);
      } on AuthException catch (e) {
        return AuthResult(success: false, error: e.message);
      } catch (e) {
        return AuthResult(success: false, error: 'Unexpected error: $e');
      }
    }

    // ── Local fallback ────────────────────────────────────────────────────────
    if (email.isEmpty || password.isEmpty) {
      return const AuthResult(success: false, error: 'Please fill in all fields.');
    }

    // Specific Mock Users
    if (email == 'user@local.com' && password == 'password') {
      final profile = UserProfile(
        id: 'mock_user',
        name: 'Local User',
        email: email,
        avatarColorValue: 0xFF2196F3,
        plan: SubscriptionPlan.premium,
      );
      await LocalDbService.saveProfile(profile);
      await LocalDbService.saveSession(profile);
      return AuthResult(success: true, profile: profile);
    }
    if (email == 'admin@local.com' && password == 'admin123') {
      final profile = UserProfile(
        id: 'mock_admin',
        name: 'Local Admin',
        email: email,
        avatarColorValue: 0xFF4CAF50,
        plan: SubscriptionPlan.vip,
      );
      await LocalDbService.saveProfile(profile);
      await LocalDbService.saveSession(profile);
      return AuthResult(success: true, profile: profile);
    }

    final profile = UserProfile(
      id: email.hashCode.abs().toString(),
      name: _capitalize(email.split('@').first),
      email: email,
    );
    await LocalDbService.saveProfile(profile);
    await LocalDbService.saveSession(profile);
    return AuthResult(success: true, profile: profile);
  }

  /// Create a new account.
  static Future<AuthResult> signUp(
      String name, String email, String password) async {
    if (_sb != null) {
      try {
        final res = await _sb!.auth.signUp(
          email: email,
          password: password,
          data: {'name': name.trim()},
        );
        final user = res.user;
        if (user == null) {
          return const AuthResult(success: false, error: 'Sign-up failed.');
        }
        final profile = _profileFromSupabaseUser(user);
        await LocalDbService.saveProfile(profile);
        await LocalDbService.saveSession(profile);
        return AuthResult(success: true, profile: profile);
      } on AuthException catch (e) {
        return AuthResult(success: false, error: e.message);
      } catch (e) {
        return AuthResult(success: false, error: 'Unexpected error: $e');
      }
    }

    // ── Local fallback: sign-up = sign-in (any credentials accepted) ──────────
    return signIn(email, password);
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    if (_sb != null) {
      try {
        await _sb!.auth.signOut();
      } catch (_) {}
    }
    await LocalDbService.clearSession();
  }

  /// Permanently delete the authenticated account.
  ///
  /// Requires the `delete_user` SQL function to be deployed in Supabase.
  static Future<AuthResult> deleteAccount() async {
    if (_sb != null) {
      try {
        await _sb!.rpc('delete_user');
        await _sb!.auth.signOut();
        await LocalDbService.clearSession();
        return const AuthResult(success: true);
      } on AuthException catch (e) {
        return AuthResult(success: false, error: e.message);
      } catch (_) {
        return const AuthResult(
          success: false,
          error:
              'Could not delete account automatically.\nPlease contact support.',
        );
      }
    }

    // ── Local fallback ────────────────────────────────────────────────────────
    await LocalDbService.clearSession();
    return const AuthResult(success: true);
  }

  /// Guest login — creates a temporary local-only profile.
  static Future<AuthResult> signInAsGuest() async {
    if (_sb != null) {
      try {
        final res = await _sb!.auth.signInAnonymously();
        final user = res.user;
        if (user == null) {
          return const AuthResult(success: false, error: 'Guest sign-in failed.');
        }
        final profile = UserProfile(
          id: user.id,
          name: 'Guest',
          email: '',
          avatarColorValue: 0xFF666666,
        );
        await LocalDbService.saveProfile(profile);
        await LocalDbService.saveSession(profile);
        return AuthResult(success: true, profile: profile);
      } catch (_) {
        // Supabase anonymous auth may not be enabled — fall through to local.
      }
    }

    const profile = UserProfile(
      id: 'guest',
      name: 'Guest',
      email: '',
      avatarColorValue: 0xFF666666,
    );
    await LocalDbService.saveProfile(profile);
    await LocalDbService.saveSession(profile);
    return const AuthResult(success: true, profile: profile);
  }
}

