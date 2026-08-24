import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Support --dart-define=API_BASE_URL=https://...
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      final base = _envBaseUrl.endsWith('/') 
          ? _envBaseUrl.substring(0, _envBaseUrl.length - 1) 
          : _envBaseUrl;
      return base.endsWith('/api/v1') ? base : '$base/api/v1';
    }

    // Default to live Railway deployment
    return 'https://bakery-sales-production.up.railway.app/api/v1';
  }

  // Auth
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Cafes
  static const String cafes = '/cafes';
  static String cafe(String id) => '/cafes/$id';

  // Products
  static const String products = '/products';
  static String product(String id) => '/products/$id';

  // Sales
  static const String sales = '/sales';
  static String sale(String id) => '/sales/$id';

  // Expenses
  static const String expenses = '/expenses';
  static String expense(String id) => '/expenses/$id';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';
  static const String dashboardCafes = '/dashboard/cafes';
  static const String dashboardProducts = '/dashboard/products';
}
