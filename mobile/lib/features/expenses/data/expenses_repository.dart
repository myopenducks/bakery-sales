import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';

class ExpenseModel {
  final String id;
  final String name;
  final num? quantity;
  final String? unit;
  final int totalCost;
  final DateTime? createdAt;

  ExpenseModel({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    required this.totalCost,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] != null ? num.tryParse(json['quantity'].toString()) : null,
      unit: json['unit'] as String?,
      totalCost: json['totalCost'] as int,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class ExpensesRepository {
  final Dio _dio;

  ExpensesRepository(this._dio);

  Future<List<ExpenseModel>> getExpenses() async {
    final response = await _dio.get(ApiEndpoints.expenses);
    final list = response.data['expenses'] as List;
    return list.map((json) => ExpenseModel.fromJson(json)).toList();
  }

  Future<void> createExpense({
    required String name,
    num? quantity,
    String? unit,
    required int totalCost,
  }) async {
    await _dio.post(
      ApiEndpoints.expenses,
      data: {
        'name': name,
        ...?quantity != null ? {'quantity': quantity} : null,
        if (unit != null && unit.isNotEmpty) 'unit': unit,
        'totalCost': totalCost,
      },
    );
  }

  Future<void> updateExpense({
    required String id,
    required String name,
    num? quantity,
    String? unit,
    required int totalCost,
  }) async {
    await _dio.patch(
      ApiEndpoints.expense(id),
      data: {
        'name': name,
        'quantity': quantity,
        'unit': (unit != null && unit.isNotEmpty) ? unit : null,
        'totalCost': totalCost,
      },
    );
  }

  Future<void> deleteExpense(String id) async {
    await _dio.delete(ApiEndpoints.expense(id));
  }
}
