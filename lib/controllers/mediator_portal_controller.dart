import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_order.dart';
import '../models/mediator.dart';
import '../models/product.dart';
import '../models/publication_request.dart';
import '../services/publication_requests_service.dart';
import 'mediators_controller.dart';
import 'orders_controller.dart';
import 'products_controller.dart';

final mediatorSessionProvider =
    StateNotifierProvider<MediatorSessionController, MediatorProfile?>(
  (ref) => MediatorSessionController(ref),
);

class MediatorSessionController extends StateNotifier<MediatorProfile?> {
  MediatorSessionController(this._ref) : super(null);

  final Ref _ref;

  Future<void> signInWithCode(String code) async {
    final mediator =
        await _ref.read(mediatorsServiceProvider).getMediatorByCode(code);
    if (mediator == null) {
      throw Exception('الرمز غير صحيح أو لا يوجد وسيط بهذا الرمز.');
    }
    state = mediator;
  }

  void signOut() {
    state = null;
  }
}

final mediatorOwnedProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final mediator = ref.watch(mediatorSessionProvider);
  if (mediator == null) {
    return const AsyncValue.data(<Product>[]);
  }
  return ref.watch(_mediatorProductsStreamProvider(mediator.code));
});

final _mediatorProductsStreamProvider =
    StreamProvider.family<List<Product>, String>((ref, code) {
  return ref.watch(productsServiceProvider).watchMediatorProducts(code);
});

final publicationRequestsServiceProvider =
    Provider<PublicationRequestsService>((ref) {
  return PublicationRequestsService(ref.watch(firestoreProvider));
});

final mediatorPublicationRequestsProvider =
    Provider<AsyncValue<List<PublicationRequest>>>((ref) {
  final mediator = ref.watch(mediatorSessionProvider);
  if (mediator == null) {
    return const AsyncValue.data(<PublicationRequest>[]);
  }
  return ref.watch(_mediatorRequestsStreamProvider(mediator.code));
});

final _mediatorRequestsStreamProvider =
    StreamProvider.family<List<PublicationRequest>, String>((ref, code) {
  return ref
      .watch(publicationRequestsServiceProvider)
      .watchMediatorRequests(code);
});

class PublicationRequestInput {
  const PublicationRequestInput({
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    this.price,
    this.imageUrl = '',
  });

  final String name;
  final String brand;
  final String category;
  final String description;
  final double? price;
  final String imageUrl;
}

class MediatorPublicationRequestController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit(PublicationRequestInput input) async {
    final mediator = ref.read(mediatorSessionProvider);
    if (mediator == null) {
      throw Exception('يجب تسجيل الدخول كوسيط أولًا.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final request = PublicationRequest(
        id: '',
        mediatorId: mediator.id,
        mediatorCode: mediator.code,
        mediatorName: mediator.name,
        name: input.name,
        brand: input.brand,
        category: input.category,
        description: input.description,
        createdAt: DateTime.now(),
        price: input.price,
        imageUrl: input.imageUrl,
      );
      return ref.read(publicationRequestsServiceProvider).createRequest(request);
    });
  }
}

final mediatorPublicationRequestControllerProvider =
    AsyncNotifierProvider<MediatorPublicationRequestController, void>(
  MediatorPublicationRequestController.new,
);

class MediatorSummary {
  const MediatorSummary({
    required this.balance,
    required this.totalOrders,
    required this.productsSold,
    required this.reservedProducts,
  });

  final double balance;
  final int totalOrders;
  final int productsSold;
  final int reservedProducts;
}

final mediatorSummaryProvider = Provider<MediatorSummary>((ref) {
  final mediator = ref.watch(mediatorSessionProvider);
  if (mediator == null) {
    return const MediatorSummary(
      balance: 0,
      totalOrders: 0,
      productsSold: 0,
      reservedProducts: 0,
    );
  }

  final orders = ref.watch(ordersProvider).valueOrNull ?? const <AppOrder>[];
  final products =
      ref.watch(mediatorOwnedProductsProvider).valueOrNull ?? const <Product>[];

  final relatedOrders =
      orders.where((order) => order.mediatorId == mediator.id).toList();
  final completedOrders =
      relatedOrders.where((order) => order.status == 'completed').toList();

  return MediatorSummary(
    balance: completedOrders.fold<double>(
      mediator.currentBalance,
      (sum, order) => sum + order.totalAmount,
    ),
    totalOrders: relatedOrders.length,
    productsSold: products.where((product) => product.isSold).length,
    reservedProducts: products.where((product) => product.isReserved).length,
  );
});
