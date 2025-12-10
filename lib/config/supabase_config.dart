// Supabase Configuration
// IMPORTANT: Replace these with your actual Supabase credentials
// Get them from: https://app.supabase.com/project/_/settings/api

class SupabaseConfig {
  // TODO: Replace with your Supabase URL
  static const String supabaseUrl = 'https://ndkxgzfbsnlgepeofxcm.supabase.co';

  // TODO: Replace with your Supabase Anon Key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ka3hnemZic25sZ2VwZW9meGNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzMzUyNjIsImV4cCI6MjA4MDkxMTI2Mn0.lj9tmOMxUBckibeeLNx19oVt4SykwMZuZM5axrRiLhU';

  // Storage bucket names
  static const String profileImagesBucket = 'profile_images';
  static const String documentsBoucket = 'documents';
  static const String kycDocumentsBucket = 'kyc_documents';
}
