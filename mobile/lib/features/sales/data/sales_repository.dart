import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';

class SaleItemInput {
  final String productId;
  final String sellingMode; // 'UNIT' | 'KG'
  final num quantity;

  SaleItemInput({
    required this.productId,
    required this.sellingMode,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'sellingMode': sellingMode,
        'quantity': quantity,
      };
}

class SaleItemModel {
  final String id;
  final String productId;
  final String productName;
  final String sellingMode;
  final num quantity;
  final int unitPriceSnapshot;
  final int totalAmount;

  SaleItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sellingMode,
    required this.quantity,
    required this.unitPriceSnapshot,
    required this.totalAmount,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: (json['productName'] as String?) ?? 'Unknown Product',
      sellingMode: json['sellingMode'] as String,
      quantity: num.tryParse(json['quantity'].toString()) ?? 0,
      unitPriceSnapshot: json['unitPriceSnapshot'] as int,
      totalAmount: json['totalAmount'] as int,
    );
  }
}

class SaleModel {
  final String id;
  final String? cafeId;
  final String? cafeName;
  final int totalAmount;
  final DateTime? createdAt;
  final List<SaleItemModel>? items;

  SaleModel({
    required this.id,
    this.cafeId,
    this.cafeName,
    required this.totalAmount,
    this.createdAt,
    this.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] as String,
      cafeId: json['cafeId'] as String?,
      cafeName: json['cafeName'] as String?,
      totalAmount: json['totalAmount'] as int,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => SaleItemModel.fromJson(i)).toList()
          : null,
    );
  }
}

class SalesRepository {
  final Dio _dio;

  SalesRepository(this._dio);

  Future<List<SaleModel>> getSales() async {
    final response = await _dio.get(ApiEndpoints.sales);
    final list = response.data['sales'] as List;
    return list.map((json) => SaleModel.fromJson(json)).toList();
  }

  Future<SaleModel> getSaleDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.sale(id));
    return SaleModel.fromJson(response.data['sale']);
  }

  Future<void> createSale({
    required String cafeId,
    required List<SaleItemInput> items,
  }) async {
    await _dio.post(
      ApiEndpoints.sales,
      data: {
        'cafeId': cafeId,
        'items': items.map((i) => i.toJson()).toList(),
      },
    );
  }
}
