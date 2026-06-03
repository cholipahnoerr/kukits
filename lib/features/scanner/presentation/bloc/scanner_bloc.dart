import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/ai_service.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final AiService _service;

  ScannerBloc({AiService? service})
      : _service = service ?? AiService(),
        super(const ScannerInitial()) {
    on<ScannerAnalyze>(_onAnalyze);
    on<ScannerReset>((_, emit) => emit(const ScannerInitial()));
  }

  Future<void> _onAnalyze(ScannerAnalyze event, Emitter<ScannerState> emit) async {
    emit(const ScannerLoading());
    try {
      final result = await _service.analyzeFood(event.imageFile);
      if (result == null) {
        emit(const ScannerNotFood());
      } else {
        emit(ScannerSuccess(result: result, imageFile: event.imageFile));
      }
    } catch (e) {
      emit(ScannerError(e.toString()));
    }
  }
}
