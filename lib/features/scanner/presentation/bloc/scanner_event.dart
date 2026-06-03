import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class ScannerEvent extends Equatable {
  const ScannerEvent();
  @override
  List<Object?> get props => [];
}

class ScannerAnalyze extends ScannerEvent {
  final File imageFile;
  const ScannerAnalyze(this.imageFile);
  @override
  List<Object?> get props => [imageFile.path];
}

class ScannerReset extends ScannerEvent {
  const ScannerReset();
}
