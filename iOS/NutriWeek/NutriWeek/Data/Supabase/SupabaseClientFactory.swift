import Foundation
import Supabase

enum SupabaseClientFactory {
    static let shared: SupabaseClient = {
        let rawURL = SupabaseConfig.url
        let trimmedURL = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)

        print("[Supabase] raw SupabaseConfig.url = '\(rawURL)'")
        print("[Supabase] trimmed SupabaseConfig.url = '\(trimmedURL)'")

        let supabaseURL = URL(string: trimmedURL)!
        let supabaseAnonKey = SupabaseConfig.anonKey

        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }()
}
