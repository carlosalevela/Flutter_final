import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/injection_container.dart';
import '../../domain/entities/skin_analysis_entity.dart'; // 👈 AGREGADO
import '../../domain/usecases/save_analysis_usecase.dart';
import '../bloc/auth/auth_bloc.dart' as auth; // 👈 CON ALIAS
import '../bloc/history/history_bloc.dart';
import '../bloc/skin_analysis_bloc.dart';
import '../widgets/analysis_result_widget.dart';
import 'auth/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSavingToHistory = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  void _analyzeImage() {
    if (_selectedImage != null) {
      context.read<SkinAnalysisBloc>().add(AnalyzeImageEvent(_selectedImage!));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar imagen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
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
              context.read<auth.AuthBloc>().add(auth.SignOutEvent()); // 👈 CON PREFIJO
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

  Future<void> _saveToHistory(SkinAnalysisEntity analysis) async {
  if (_selectedImage == null || _isSavingToHistory) return;

  setState(() {
    _isSavingToHistory = true;
  });

  try {
    // 1. Subir imagen a Supabase Storage
    final imageUrl = await _uploadImage(_selectedImage!);

    // 2. Usar el UseCase del container 👇
    final result = await InjectionContainer.saveAnalysisUseCase(
      imageUrl: imageUrl,
      diagnosis: analysis.diagnosis,
      description: analysis.description,
      riskLevel: analysis.riskLevel,
      recommendations: analysis.recommendations,
      requiresMedicalAttention: analysis.requiresMedicalAttention,
    );

    result.fold(
      (failure) {
        _showError('Error al guardar: ${failure.message}');
      },
      (_) {
        _showSuccess('✅ Análisis guardado en el historial');
        // Recargar historial
        context.read<HistoryBloc>().add(LoadHistoryEvent());
      },
    );
  } catch (e) {
    _showError('Error al guardar en historial: $e');
  } finally {
    setState(() {
      _isSavingToHistory = false;
    });
  }
}

  Future<String> _uploadImage(File imageFile) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = '$userId/$timestamp.$extension';

      // Subir archivo
      await supabase.storage.from('skin-images').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Obtener URL pública
      final imageUrl = supabase.storage.from('skin-images').getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<auth.AuthBloc, auth.AuthState>( // 👈 CON PREFIJO
      listener: (context, authState) {
        // Cuando el usuario cierra sesión, ir a LoginPage
        if (authState is auth.Unauthenticated) { // 👈 CON PREFIJO
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SkinCheck AI'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.teal,
          actions: [
            // Botón de cerrar sesión
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: _showLogoutDialog,
            ),
          ],
        ),
        body: BlocConsumer<SkinAnalysisBloc, SkinAnalysisState>(
          listener: (context, state) {
            if (state is SkinAnalysisError) {
              _showError(state.message);
            } else if (state is SkinAnalysisLoaded) {
              _saveToHistory(state.analysis);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(
                    Icons.medical_services,
                    size: 80,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Detección Temprana de\nEnfermedades de la Piel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Analiza imágenes de tu piel con inteligencia artificial',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Imagen seleccionada o placeholder
                  if (_selectedImage != null) ...[
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No hay imagen seleccionada',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Botones
                  ElevatedButton.icon(
                    onPressed: state is SkinAnalysisLoading
                        ? null
                        : _showImageSourceDialog,
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(
                      _selectedImage == null
                          ? 'Seleccionar Imagen'
                          : 'Cambiar Imagen',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  if (_selectedImage != null) ...[
                    ElevatedButton.icon(
                      onPressed: state is SkinAnalysisLoading || _isSavingToHistory
                          ? null
                          : _analyzeImage,
                      icon: state is SkinAnalysisLoading || _isSavingToHistory
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.analytics),
                      label: Text(
                        state is SkinAnalysisLoading
                            ? 'Analizando...'
                            : _isSavingToHistory
                                ? 'Guardando...'
                                : 'Analizar con IA',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Resultados
                  if (state is SkinAnalysisLoaded) ...[
                    AnalysisResultWidget(analysis: state.analysis),
                  ],

                  // Disclaimer
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Este NO es un diagnóstico médico. Siempre consulta con un profesional.',
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}