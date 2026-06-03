import 'package:equatable/equatable.dart';

abstract class ShopEvent extends Equatable {
  const ShopEvent();
  @override
  List<Object?> get props => [];
}

class ShopLoadProducts extends ShopEvent {
  final String? category;
  const ShopLoadProducts({this.category});
  @override
  List<Object?> get props => [category];
}
