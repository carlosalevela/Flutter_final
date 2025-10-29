import 'package:flutter/material.dart';
import '../../domain/entities/skin_analysis_entity.dart';

class AnalysisResultWidget extends StatelessWidget {
  final SkinAnalysisEntity analysis;

  const AnalysisResultWidget({
    super.key,
    required this.analysis,
  });

  Color _getRiskColor() {
    switch (analysis.riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  String _getRiskText() {
    switch (analysis.riskLevel.toLowerCase()) {
      case 'high':
        return 'ALTO';
      case 'medium':
        return 'MEDIO';
      case 'low':
      default:
        return 'BAJO';
    }
  }

  IconData _getRiskIcon() {
    switch (analysis.riskLevel.toLowerCase()) {
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.warning;
      case 'low':
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Colors.teal,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Resultados del Análisis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // Diagnóstico
            _buildSection(
              icon: Icons.medical_information,
              title: 'Diagnóstico Preliminar',
              content: analysis.diagnosis,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),

            // Nivel de Riesgo
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _getRiskColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _getRiskColor(), width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    _getRiskIcon(),
                    color: _getRiskColor(),
                    size: 30,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nivel de Riesgo',
                          style: TextStyle(
                            color: _getRiskColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getRiskText(),
                          style: TextStyle(
                            color: _getRiskColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Descripción
            _buildSection(
              icon: Icons.description,
              title: 'Descripción',
              content: analysis.description,
              color: Colors.purple,
            ),
            const SizedBox(height: 20),

            // Recomendaciones
            _buildRecommendations(),
            const SizedBox(height: 20),

            // Atención médica
            if (analysis.requiresMedicalAttention) ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      color: Colors.red,
                      size: 30,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'Se recomienda consultar con un dermatólogo lo antes posible',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Recomendaciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...analysis.recommendations.map(
          (recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}