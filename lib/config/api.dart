class ApiConfig {
  // Using different possible URLs for development environments
  // Uncomment the one that works for your setup:

  // For Android Emulator (using 10.0.2.2 to access host machine)
  // static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Use your actual server IP address
  // static const String baseUrl = 'http://192.168.1.100:3000/api';

  // For local development (web)
  static const String baseUrl = 'http://localhost:3000/api';

  // Set to FALSE to ensure we always use real server connection
  static const bool useOfflineMode = false;

  // Disable role validation for all users
  static const bool disableRoleValidation = true;

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String logout = '$baseUrl/auth/logout';
  static const String changePassword = '$baseUrl/auth/change-password';

  // Attendance endpoints
  static const String attendance = '$baseUrl/attendance';

  // Batch endpoints
  static const String batches = '$baseUrl/batches';

  // Task endpoints
  static const String tasks = '$baseUrl/tasks';

  // Seedling endpoints
  static const String seedlings = '$baseUrl/seedlings';

  // Transplant endpoints
  static const String transplants = '$baseUrl/transplants';

  // Notification endpoints
  static const String notifications = '$baseUrl/notifications';
}
