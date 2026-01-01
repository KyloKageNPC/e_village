// Supabase Configuration
// IMPORTANT: Replace these with your actual Supabase credentials
// Get them from: https://app.supabase.com/project/_/settings/api

class SupabaseConfig {
  // TODO: Replace with your Supabase URL
  static const String supabaseUrl = 'https://hijypqlxwcbkjgpferce.supabase.co';

  // TODO: Replace with your Supabase Anon Key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpanlwcWx4d2Nia2pncGZlcmNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcyMTg2NTAsImV4cCI6MjA4Mjc5NDY1MH0.5QwXyaz7iyDSjb_Ar5kaEm1lbXScDXB_Xm_NS0wg9aI';

  // Storage bucket names
  static const String profileImagesBucket = 'profile_images';
  static const String documentsBoucket = 'documents';
  static const String kycDocumentsBucket = 'kyc_documents';
}
