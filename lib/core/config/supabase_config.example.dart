// =============================================================================
// SUPABASE CONFIG — TEMPLATE
//
// This file is checked into git so the project stays buildable for anyone
// who clones it. The REAL keys never go here and never go into git.
//
// ONE-TIME SETUP ON EACH PC THAT BUILDS THIS APP:
//   1. Copy this file and rename the copy to `supabase_config.dart`
//      (same folder — lib/core/config/).
//   2. Fill in the real url/anonKey below in that copy.
//   3. That's it — `supabase_config.dart` is listed in .gitignore, so it
//      will never be picked up by `git add` / committed / pushed, even
//      by accident.
//
// Where to find the real values: Supabase project → Settings → API.
// Only ever use the "anon" / "publishable" key here — NEVER the
// "service_role" key (that one bypasses all security rules and must
// never exist on a client machine at all).
// =============================================================================

class SupabaseConfig {
  static const String url = 'PASTE_YOUR_SUPABASE_PROJECT_URL_HERE';
  static const String anonKey = 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE';
}