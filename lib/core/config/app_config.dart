import 'dart:io';

class AppConfig {
  static const supabaseUrl = 'https://iwqkefgzvuirrtrpluew.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3cWtlZmd6dnVpcnJ0cnBsdWV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczMDMxMjIsImV4cCI6MjA5Mjg3OTEyMn0.zLqijo_Xjbm9bK-dTB6UvpsBL_qf-0N6J0oEfP_MHEE';

  // Android emülatöründe host localhost = 10.0.2.2
  static String get backendUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }
}
