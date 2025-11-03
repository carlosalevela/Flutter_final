import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth imports
import '../data/datasources/auth/supabase_auth_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth/auth_repository.dart';
import '../domain/usecases/auth/sign_in_usecase.dart';
import '../domain/usecases/auth/sign_up_usecase.dart';
import '../domain/usecases/auth/sign_out_usecase.dart';
import '../domain/usecases/auth/get_current_user_usecase.dart';
import '../presentation/bloc/auth/auth_bloc.dart';

// Skin Analysis imports
import '../data/datasources/openai_datasource.dart';
import '../data/repositories/skin_analysis_repository_impl.dart';
import '../domain/repositories/skin_analysis_repository.dart';
import '../domain/usecases/analyze_skin_image.dart';
import '../presentation/bloc/skin_analysis_bloc.dart';

class InjectionContainer {
  // Auth BLoC
  static late final AuthBloc authBloc;
  
  // Skin Analysis BLoC (tu existente)
  static late final SkinAnalysisBloc skinAnalysisBloc;

  static Future<void> init() async {
    // Cargar variables de entorno
    await dotenv.load(fileName: ".env");

    // ========== INICIALIZAR SUPABASE ==========
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    final supabaseClient = Supabase.instance.client;

    // ========== AUTH (NUEVO) ==========
    
    // Data sources
    final SupabaseAuthDataSource authDataSource = SupabaseAuthDataSourceImpl(
      supabaseClient: supabaseClient,
    );

    // Repositories
    final AuthRepository authRepository = AuthRepositoryImpl(
      dataSource: authDataSource,
    );

    // Use cases
    final signInUseCase = SignInUseCase(authRepository);
    final signUpUseCase = SignUpUseCase(authRepository);
    final signOutUseCase = SignOutUseCase(authRepository);
    final getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);

    // BLoC
    authBloc = AuthBloc(
      signInUseCase: signInUseCase,
      signUpUseCase: signUpUseCase,
      signOutUseCase: signOutUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
    );

    // ========== SKIN ANALYSIS (TU CÓDIGO EXISTENTE) ==========

    final httpClient = http.Client();

    final OpenAIDataSource remoteDataSource = OpenAIDataSourceImpl(
      client: httpClient,
    );

    final SkinAnalysisRepository repository = SkinAnalysisRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    final analyzeSkinImage = AnalyzeSkinImage(repository);

    skinAnalysisBloc = SkinAnalysisBloc(
      analyzeSkinImage: analyzeSkinImage,
    );
  }

  static void dispose() {
    authBloc.close();
    skinAnalysisBloc.close();
  }
}