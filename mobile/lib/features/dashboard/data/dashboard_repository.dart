import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../sales/data/sales_repository.dart';

class DashboardSummaryModel {
  final String period;
  final int revenue;
  final int expenses;
  final int net;
  final List<SaleModel> recentSales;

  DashboardSummaryModel({
    required this.period,
    required this.revenue,
    required this.expenses,
    required this.net,
    required this.recentSales,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      period: json['period'] as String,
      revenue: json['revenue'] as int,
      expenses: json['expenses'] as int,
      net: json['net'] as int,
      recentSales: (json['recentSales'] as List)
          .map((s) => SaleModel.fromJson(s))
          .toList(),
    );
  }
}

class BestProductModel {
  final String productId;
  final String productName;
  final int revenue;

  BestProductModel({
    required this.productId,
    required this.productName,
    required this.revenue,
  });

  factory BestProductModel.fromJson(Map<String, dynamic> json) {
    return BestProductModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      revenue: json['revenue'] as int,
    );
  }
}

class RankedCafeModel {
  final String cafeId;
  final String cafeName;
  final int totalRevenue;
  final int salesCount;
  final BestProductModel? bestProduct;

  RankedCafeModel({
    required this.cafeId,
    required this.cafeName,
    required this.totalRevenue,
    required this.salesCount,
    this.bestProduct,
  });

  factory RankedCafeModel.fromJson(Map<String, dynamic> json) {
    return RankedCafeModel(
      cafeId: json['cafeId'] as String,
      cafeName: json['cafeName'] as String,
      totalRevenue: json['totalRevenue'] as int,
      salesCount: json['salesCount'] as int,
      bestProduct: json['bestProduct'] != null
          ? BestProductModel.fromJson(json['bestProduct'])
          : null,
    );
  }
}

class RankedProductModel {
  final String productId;
  final String productName;
  final int totalRevenue;
  final int salesCount;

  RankedProductModel({
    required this.productId,
    required this.productName,
    required this.totalRevenue,
    required this.salesCount,
  });

  factory RankedProductModel.fromJson(Map<String, dynamic> json) {
    return RankedProductModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      totalRevenue: json['totalRevenue'] as int,
      salesCount: json['salesCount'] as int,
    );
  }
}

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<DashboardSummaryModel> getSummary({required String period, String? month}) async {
    final response = await _dio.get(
      ApiEndpoints.dashboardSummary,
      queryParameters: {
        'period': period,
        if (month != null && month.isNotEmpty) 'month': month,
      },
    );
    return DashboardSummaryModel.fromJson(response.data);
  }

  Future<List<RankedCafeModel>> getTopCafes({required String period, String? month}) async {
    final response = await _dio.get(
      ApiEndpoints.dashboardCafes,
      queryParameters: {
        'period': period,
        if (month != null && month.isNotEmpty) 'month': month,
      },
    );
    final list = response.data['topCafes'] as List;
    return list.map((c) => RankedCafeModel.fromJson(c)).toList();
  }

  Future<List<RankedProductModel>> getTopProducts({required String period, String? month}) async {
    final response = await _dio.get(
      ApiEndpoints.dashboardProducts,
      queryParameters: {
        'period': period,
        if (month != null && month.isNotEmpty) 'month': month,
      },
    );
    final list = response.data['topProducts'] as List;
    return list.map((p) => RankedProductModel.fromJson(p)).toList();
  }
}
