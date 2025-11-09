import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart' as auth;
import 'auth/login_page.dart';

class InfoPage extends StatelessWidget {
  final VoidCallback onAnalyze;
  final VoidCallback onHistory;

  const InfoPage({
    super.key,
    required this.onAnalyze,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<auth.AuthBloc, auth.AuthState>(
      listener: (context, authState) {
        if (authState is auth.Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: CustomScrollView(
          slivers: [
            // AppBar con botones
            _buildAppBar(context),
            
            // Contenido
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildWelcomeCard(),
                  const SizedBox(height: 20),
                  _buildStatsSection(),
                  const SizedBox(height: 20),
                  _buildDiseasesGrid(context),
                  const SizedBox(height: 20),
                  _buildABCDECard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.teal,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'SkinCheck AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      actions: [
        // Botón Analizar
        IconButton(
          icon: const Icon(Icons.add_a_photo),
          tooltip: 'Realizar Análisis',
          onPressed: onAnalyze,
        ),
        // Botón Historial
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Ver Historial',
          onPressed: onHistory,
        ),
        // Botón Cerrar sesión
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar Sesión',
          onPressed: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Detección Temprana\nde Enfermedades de la Piel',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tecnología de IA para análisis dermatológico',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas Globales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '3,000+',
                  'Enfermedades\nde la Piel',
                  Icons.healing,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '1 de 3',
                  'Personas\nafectadas',
                  Icons.people,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '95%',
                  'Curables si\nse detectan a tiempo',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '2M+',
                  'Casos de cáncer\nde piel al año',
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            number,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseasesGrid(BuildContext context) {
    final diseases = [
      {
        'name': 'Acné',
        'icon': Icons.face,
        'color': const Color(0xFFFF6B6B),
        'description': 'Condición común que afecta principalmente la cara, espalda y pecho.',
      },
      {
        'name': 'Eczema',
        'icon': Icons.healing,
        'color': const Color(0xFF4ECDC4),
        'description': 'Inflamación crónica que causa picazón y enrojecimiento.',
      },
      {
        'name': 'Psoriasis',
        'icon': Icons.layers,
        'color': const Color(0xFFFFBE0B),
        'description': 'Enfermedad autoinmune que acelera el ciclo de células de la piel.',
      },
      {
        'name': 'Melanoma',
        'icon': Icons.warning_amber,
        'color': const Color(0xFFFF006E),
        'description': 'Tipo más grave de cáncer de piel. Detectable con regla ABCDE.',
      },
      {
        'name': 'Dermatitis',
        'icon': Icons.local_fire_department,
        'color': const Color(0xFFFB5607),
        'description': 'Inflamación de la piel que causa enrojecimiento y picazón.',
      },
      {
        'name': 'Vitiligo',
        'icon': Icons.palette,
        'color': const Color(0xFF8338EC),
        'description': 'Pérdida de pigmento que causa manchas blancas en la piel.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enfermedades Comunes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: diseases.length,
            itemBuilder: (context, index) {
              final disease = diseases[index];
              return _buildDiseaseCard(
                disease['name'] as String,
                disease['icon'] as IconData,
                disease['color'] as Color,
                disease['description'] as String,
                context,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(
    String name,
    IconData icon,
    Color color,
    String description,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () => _showDiseaseInfo(context, name, description, icon, color),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildABCDECard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Regla ABCDE del Melanoma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildABCDEItem('A', 'Asimetría', 'Una mitad es diferente a la otra'),
          _buildABCDEItem('B', 'Bordes', 'Irregulares o poco definidos'),
          _buildABCDEItem('C', 'Color', 'Varios colores o tonos'),
          _buildABCDEItem('D', 'Diámetro', 'Mayor a 6mm (tamaño de un borrador)'),
          _buildABCDEItem('E', 'Evolución', 'Cambios en tamaño, forma o color'),
        ],
      ),
    );
  }

  Widget _buildABCDEItem(String letter, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onAnalyze,
              icon: const Icon(Icons.camera_alt, size: 24),
              label: const Text(
                'Realizar Análisis Ahora',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: onHistory,
              icon: const Icon(Icons.history, size: 24),
              label: const Text(
                'Ver Mi Historial',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDiseaseInfo(
    BuildContext context,
    String name,
    String description,
    IconData icon,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name),
            ),
          ],
        ),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<auth.AuthBloc>().add(auth.SignOutEvent());
            },
            child: const Text(
              'Salir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}