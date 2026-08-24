import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';

class ProductModel {
  final String id;
  final String name;
  final bool supportsUnitSale;
  final bool supportsKgSale;
  final int? unitPrice;
  final int? pricePerKg;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.supportsUnitSale,
    required this.supportsKgSale,
    this.unitPrice,
    this.pricePerKg,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      supportsUnitSale: json['supportsUnitSale'] == true || json['supportsUnitSale'] == 1,
      supportsKgSale: json['supportsKgSale'] == true || json['supportsKgSale'] == 1,
      unitPrice: json['unitPrice'] as int?,
      pricePerKg: json['pricePerKg'] as int?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class ProductsRepository {
  final Dio _dio;

  ProductsRepository(this._dio);

  Future<List<ProductModel>> getProducts() async {
    final response = await _dio.get(ApiEndpoints.products);
    final list = response.data['products'] as List;
    return list.map((json) => ProductModel.fromJson(json)).toList();
  }

  Future<void> createProduct({
    required String name,
    required bool supportsUnitSale,
    required bool supportsKgSale,
    int? unitPrice,
    int? pricePerKg,
  }) async {
    await _dio.post(
      ApiEndpoints.products,
      data: {
        'name': name,
        'supportsUnitSale': supportsUnitSale,
        'supportsKgSale': supportsKgSale,
        if (supportsUnitSale) 'unitPrice': unitPrice,
        if (supportsKgSale) 'pricePerKg': pricePerKg,
      },
    );
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required bool supportsUnitSale,
    required bool supportsKgSale,
    int? unitPrice,
    int? pricePerKg,
  }) async {
    await _dio.patch(
      ApiEndpoints.product(id),
      data: {
        'name': name,
        'supportsUnitSale': supportsUnitSale,
        'supportsKgSale': supportsKgSale,
        'unitPrice': supportsUnitSale ? unitPrice : null,
        'pricePerKg': supportsKgSale ? pricePerKg : null,
      },
    );
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete(ApiEndpoints.product(id));
  }
}
