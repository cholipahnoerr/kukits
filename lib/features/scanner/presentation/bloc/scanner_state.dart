import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../data/ai_service.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();
  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {
  const ScannerInitial();
}

class ScannerLoading extends ScannerState {
  const ScannerLoading();
}

class ScannerSuccess extends ScannerState {
  final ScanResult result;
  final File imageFile;
  const ScannerSuccess({required this.result, required this.imageFile});
  @override
  List<Object?> get props => [result, imageFile.path];
}

class ScannerNotFood extends ScannerState {
  const ScannerNotFood();
}

class ScannerError extends ScannerState {
  final String message;
  const ScannerError(this.message);
  @override
  List<Object?> get props => [message];
}
