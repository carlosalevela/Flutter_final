import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analysis_history_model.dart';

abstract class HistoryDataSource {
  Future<List<AnalysisHistoryModel>> getHistory();
  
  Future<void> saveAnalysis({
    required String imageUrl,
    required String diagnosis,
    required String description,
    required String riskLevel,
    required List<String> recommendations,
    required bool requiresMedicalAttention,
  });
  
  Future<void> deleteAnalysis(String analysisId);
}

class HistoryDataSourceImpl implements HistoryDataSource {
  final SupabaseClient supabaseClient;

  HistoryDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<AnalysisHistoryModel>> getHistory() async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await supabaseClient
          .from('skin_analyses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AnalysisHistoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }

  @override
  Future<void> saveAnalysis({
    required String imageUrl,
    required String diagnosis,
    required String description,
    required String riskLevel,
    required List<String> recommendations,
    required bool requiresMedicalAttention,
  }) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await supabaseClient.from('skin_analyses').insert({
        'user_id': userId,
        'image_url': imageUrl,
        'diagnosis': diagnosis,
        'description': description,
        'risk_level': riskLevel,
        'recommendations': recommendations,
        'requires_medical_attention': requiresMedicalAttention,
      });
    } catch (e) {
      throw Exception('Error al guardar análisis: $e');
    }
  }

  @override
  Future<void> deleteAnalysis(String analysisId) async {
    try {
      await supabaseClient
          .from('skin_analyses')
          .delete()
          .eq('id', analysisId);
    } catch (e) {
      throw Exception('Error al eliminar análisis: $e');
    }
  }
}