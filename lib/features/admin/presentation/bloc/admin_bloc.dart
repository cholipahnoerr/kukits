import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repository;

  AdminBloc({AdminRepository? repository})
      : _repository = repository ?? AdminRepository(),
        super(const AdminState()) {
    on<AdminLoadOrders>(_onLoadOrders);
    on<AdminLoadProducts>(_onLoadProducts);
    on<AdminConfirmPayment>(_onConfirmPayment);
    on<AdminUpdateOrderStatus>(_onUpdateStatus);
    on<AdminSaveProduct>(_onSaveProduct);
    on<AdminDeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onLoadOrders(AdminLoadOrders event, Emitter<AdminState> emit) async {
    await emit.forEach(
      _repository.watchAllOrders(),
      onData: (orders) => state.copyWith(orders: orders, isLoading: false),
      onError: (_, __) => state.copyWith(isLoading: false, error: 'Gagal memuat pesanan'),
    );
  }

  Future<void> _onLoadProducts(AdminLoadProducts event, Emitter<AdminState> emit) async {
    await emit.forEach(
      _repository.watchAllProducts(),
      onData: (products) => state.copyWith(products: products),
      onError: (_, __) => state.copyWith(error: 'Gagal memuat produk'),
    );
  }

  Future<void> _onConfirmPayment(AdminConfirmPayment event, Emitter<AdminState> emit) async {
    try {
      await _repository.confirmPayment(event.orderId, event.adminUid);
      emit(state.copyWith(successMessage: 'Pembayaran dikonfirmasi'));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateStatus(AdminUpdateOrderStatus event, Emitter<AdminState> emit) async {
    try {
      await _repository.updateOrderStatus(event.orderId, event.status);
      emit(state.copyWith(successMessage: 'Status diperbarui'));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSaveProduct(AdminSaveProduct event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.saveProduct(event.product, event.isNew);
      emit(state.copyWith(isLoading: false, successMessage: 'Produk disimpan'));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onDeleteProduct(AdminDeleteProduct event, Emitter<AdminState> emit) async {
    try {
      await _repository.deleteProduct(event.productId);
      emit(state.copyWith(successMessage: 'Produk dihapus'));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
