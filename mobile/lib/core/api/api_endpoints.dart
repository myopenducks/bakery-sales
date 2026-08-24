import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Configurable base url: defaults to 10.0.2.2 for Android emulator, 127.0.0.1 for desktop/web
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
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
