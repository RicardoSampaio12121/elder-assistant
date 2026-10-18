import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/authenticated_dio.dart';
import '../domain/care_recipient.dart';
import '../domain/care_recipient_repository.dart';
import 'contracts/care_recipient_request.dart';
import 'contracts/care_recipient_response.dart';

class CareRecipientRepositoryImpl implements CareRecipientRepository {
  const CareRecipientRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<CareRecipient>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/api/care-recipients');
    return (response.data!)
        .cast<Map<String, dynamic>>()
        .map(CareRecipientResponse.fromJson)
        .map((r) => r.toDomain())
        .toList();
  }

  @override
  Future<CareRecipient> getById(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/care-recipients/$id');
    return CareRecipientResponse.fromJson(response.data!).toDomain();
  }

  @override
  Future<CareRecipient> create({
    required String name,
    required DateTime dateOfBirth,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/care-recipients',
      data: CareRecipientRequest(
        name: name,
        dateOfBirth: dateOfBirth,
        notes: notes,
      ).toJson(),
    );
    return CareRecipientResponse.fromJson(response.data!).toDomain();
  }

  @override
  Future<CareRecipient> update({
    required String id,
    required String name,
    required DateTime dateOfBirth,
    String? notes,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/care-recipients/$id',
      data: CareRecipientRequest(
        name: name,
        dateOfBirth: dateOfBirth,
        notes: notes,
      ).toJson(),
    );
    return CareRecipientResponse.fromJson(response.data!).toDomain();
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('/api/care-recipients/$id');
  }
}

final careRecipientRepositoryProvider = Provider<CareRecipientRepository>((ref) {
  return CareRecipientRepositoryImpl(ref.watch(authenticatedDioProvider));
});
