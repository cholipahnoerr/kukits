import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/product_repository.dart';
import 'shop_event.dart';
import 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final ProductRepository _repository;

  ShopBloc({ProductRepository? repository})
      : _repository = repository ?? ProductRepository(),
        super(const ShopInitial()) {
    on<ShopLoadProducts>(_onLoadProducts);
  }

  Future<void> _onLoadProducts(
    ShopLoadProducts event,
    Emitter<ShopState> emit,
  ) async {
    emit(const ShopLoading());
    try {
      await emit.forEach(
        _repository.watchProducts(category: event.category),
        onData: (products) => ShopLoaded(products),
        onError: (_, _) => const ShopError('Gagal memuat produk. Cek koneksi internet.'),
      );
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }
}
