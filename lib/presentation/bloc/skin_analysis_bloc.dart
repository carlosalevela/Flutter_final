import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/skin_analysis_entity.dart';
import '../../domain/usecases/analyze_skin_image.dart';

// Events
abstract class SkinAnalysisEvent extends Equatable {
  const SkinAnalysisEvent();

  @override
  List<Object> get props => [];
}

class AnalyzeImageEvent extends SkinAnalysisEvent {
  final File imageFile;

  const AnalyzeImageEvent(this.imageFile);

  @override
  List<Object> get props => [imageFile];
}

class ResetAnalysisEvent extends SkinAnalysisEvent {}

// States
abstract class SkinAnalysisState extends Equatable {
  const SkinAnalysisState();

  @override
  List<Object> get props => [];
}

class SkinAnalysisInitial extends SkinAnalysisState {}

class SkinAnalysisLoading extends SkinAnalysisState {}

class SkinAnalysisLoaded extends SkinAnalysisState {
  final SkinAnalysisEntity analysis;

  const SkinAnalysisLoaded(this.analysis);

  @override
  List<Object> get props => [analysis];
}

class SkinAnalysisError extends SkinAnalysisState {
  final String message;

  const SkinAnalysisError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class SkinAnalysisBloc extends Bloc<SkinAnalysisEvent, SkinAnalysisState> {
  final AnalyzeSkinImage analyzeSkinImage;

  SkinAnalysisBloc({
    required this.analyzeSkinImage,
  }) : super(SkinAnalysisInitial()) {
    on<AnalyzeImageEvent>(_onAnalyzeImage);
    on<ResetAnalysisEvent>(_onResetAnalysis);
  }

  Future<void> _onAnalyzeImage(
    AnalyzeImageEvent event,
    Emitter<SkinAnalysisState> emit,
  ) async {
    emit(SkinAnalysisLoading());

    final result = await analyzeSkinImage(event.imageFile);

    result.fold(
      (failure) => emit(SkinAnalysisError(failure.message)),
      (analysis) => emit(SkinAnalysisLoaded(analysis)),
    );
  }

  void _onResetAnalysis(
    ResetAnalysisEvent event,
    Emitter<SkinAnalysisState> emit,
  ) {
    emit(SkinAnalysisInitial());
  }
}