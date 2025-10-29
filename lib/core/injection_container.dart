import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/datasources/openai_datasource.dart';
import '../data/repositories/skin_analysis_repository_impl.dart';
import '../domain/repositories/skin_analysis_repository.dart';
import '../domain/usecases/analyze_skin_image.dart';
import '../presentation/bloc/skin_analysis_bloc.dart';

class InjectionContainer {
  static late final SkinAnalysisBloc skinAnalysisBloc;

  static Future<void> init() async {
    await dotenv.load(fileName: ".env");

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
    skinAnalysisBloc.close();
  }
}