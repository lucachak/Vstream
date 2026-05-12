class Env {
  static const supabaseUrl = 'YOUR_SUPABASE_URL';
  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static bool get isConfigured => !supabaseUrl.startsWith('YOUR');
}
