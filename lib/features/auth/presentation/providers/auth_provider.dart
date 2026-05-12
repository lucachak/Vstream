import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vstream/shared/providers/supabase_provider.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream.empty();
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user;
});

class AuthNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithEmail(String email, String password) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
    });
  }

  Future<void> signUpWithEmail(String email, String password) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.auth.signUp(
            email: email,
            password: password,
          );
    });
  }

  Future<void> signOut() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    await client.auth.signOut();
  }
}

final authNotifierProvider =
    AsyncNotifierProvider.autoDispose<AuthNotifier, void>(AuthNotifier.new);
