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

// History imports 👈 NUEVOS
import '../data/datasources/history_datasource.dart';
import '../data/repositories/history_repository_impl.dart';
import '../domain/repositories/history_repository.dart';
import '../domain/usecases/get_analysis_history_usecase.dart';
import '../domain/usecases/delete_analysis_usecase.dart';
import '../domain/usecases/save_analysis_usecase.dart';
import '../presentation/bloc/history/history_bloc.dart';

class InjectionContainer {
  static late final AuthBloc authBloc;
  static late final SkinAnalysisBloc skinAnalysisBloc;
  static late final HistoryBloc historyBloc; // 👈 NUEVO
  static late final HistoryRepository historyRepository;

  static Future<void> init() async {
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    final supabaseClient = Supabase.instance.client;

    // ========== AUTH ==========
    
    final SupabaseAuthDataSource authDataSource = SupabaseAuthDataSourceImpl(
      supabaseClient: supabaseClient,
    );

    final AuthRepository authRepository = AuthRepositoryImpl(
      dataSource: authDataSource,
    );

    final signInUseCase = SignInUseCase(authRepository);
    final signUpUseCase = SignUpUseCase(authRepository);
    final signOutUseCase = SignOutUseCase(authRepository);
    final getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);

    authBloc = AuthBloc(
      signInUseCase: signInUseCase,
      signUpUseCase: signUpUseCase,
      signOutUseCase: signOutUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
    );

    // ========== SKIN ANALYSIS ==========

    final httpClient = http.Client();

    final OpenAIDataSource skinAnalysisDataSource = OpenAIDataSourceImpl(
      client: httpClient,
    );

    final SkinAnalysisRepository skinAnalysisRepository =
        SkinAnalysisRepositoryImpl(
      remoteDataSource: skinAnalysisDataSource,
    );

    final analyzeSkinImage = AnalyzeSkinImage(skinAnalysisRepository);

    skinAnalysisBloc = SkinAnalysisBloc(
      analyzeSkinImage: analyzeSkinImage,
    );

    // ========== HISTORY (NUEVO) ==========

    final HistoryDataSource historyDataSource = HistoryDataSourceImpl(
      supabaseClient: supabaseClient,
    );

    final HistoryRepository historyRepository = HistoryRepositoryImpl(
      dataSource: historyDataSource,
    );

    final getHistoryUseCase = GetAnalysisHistoryUseCase(historyRepository);
    final deleteAnalysisUseCase = DeleteAnalysisUseCase(historyRepository);

    historyBloc = HistoryBloc(
      getHistoryUseCase: getHistoryUseCase,
      deleteAnalysisUseCase: deleteAnalysisUseCase,
    );
  }

  static void dispose() {
    authBloc.close();
    skinAnalysisBloc.close();
    historyBloc.close(); // 👈 NUEVO
  }
}