import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/skin_analysis_history_entity.dart';
import '../../../domain/usecases/get_analysis_history_usecase.dart';
import '../../../domain/usecases/delete_analysis_usecase.dart';

// Events
abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object> get props => [];
}

class LoadHistoryEvent extends HistoryEvent {}

class DeleteAnalysisEvent extends HistoryEvent {
  final String analysisId;

  const DeleteAnalysisEvent(this.analysisId);

  @override
  List<Object> get props => [analysisId];
}

// States
abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<SkinAnalysisHistoryEntity> analyses;

  const HistoryLoaded(this.analyses);

  @override
  List<Object> get props => [analyses];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetAnalysisHistoryUseCase getHistoryUseCase;
  final DeleteAnalysisUseCase deleteAnalysisUseCase;

  HistoryBloc({
    required this.getHistoryUseCase,
    required this.deleteAnalysisUseCase,
  }) : super(HistoryInitial()) {
    on<LoadHistoryEvent>(_onLoadHistory);
    on<DeleteAnalysisEvent>(_onDeleteAnalysis);
  }

  Future<void> _onLoadHistory(
    LoadHistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());

    final result = await getHistoryUseCase();

    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (analyses) => emit(HistoryLoaded(analyses)),
    );
  }

  Future<void> _onDeleteAnalysis(
    DeleteAnalysisEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is HistoryLoaded) {
      emit(HistoryLoading());

      final result = await deleteAnalysisUseCase(event.analysisId);

      result.fold(
        (failure) => emit(HistoryError(failure.message)),
        (_) {
          // Recargar el historial después de eliminar
          add(LoadHistoryEvent());
        },
      );
    }
  }
}