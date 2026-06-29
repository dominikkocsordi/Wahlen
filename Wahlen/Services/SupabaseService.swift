import Foundation
import Supabase

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: AppConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }
}
