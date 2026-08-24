import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';

class CafeModel {
  final String id;
  final String name;
  final String? phone;
  final DateTime? createdAt;

  CafeModel({
    required this.id,
    required this.name,
    this.phone,
    this.createdAt,
  });

  factory CafeModel.fromJson(Map<String, dynamic> json) {
    return CafeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class CafesRepository {
  final Dio _dio;

  CafesRepository(this._dio);

  Future<List<CafeModel>> getCafes() async {
    final response = await _dio.get(ApiEndpoints.cafes);
    final list = response.data['cafes'] as List;
    return list.map((json) => CafeModel.fromJson(json)).toList();
  }

  Future<void> createCafe(String name, String? phone) async {
    await _dio.post(
      ApiEndpoints.cafes,
      data: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  Future<void> updateCafe(String id, String name, String? phone) async {
    await _dio.patch(
      ApiEndpoints.cafe(id),
      data: {
        'name': name,
        'phone': (phone != null && phone.isNotEmpty) ? phone : null,
      },
    );
  }

  Future<void> deleteCafe(String id) async {
    await _dio.delete(ApiEndpoints.cafe(id));
  }
}
