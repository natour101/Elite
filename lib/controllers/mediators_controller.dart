import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mediator.dart';
import '../services/mediators_service.dart';
import 'products_controller.dart';

final mediatorsServiceProvider = Provider<MediatorsService>((ref) {
  return MediatorsService(ref.watch(firestoreProvider));
});

class MediatorsCatalogController extends AsyncNotifier<List<MediatorProfile>> {
  Timer? _timer;

  @override
  Future<List<MediatorProfile>> build() async {
    ref.onDispose(() => _timer?.cancel());
    _timer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(refresh(silent: true)),
    );
    return _load();
  }

  Future<List<MediatorProfile>> _load() {
    return ref.read(mediatorsServiceProvider).fetchMediators();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      final previous = state.valueOrNull ?? const <MediatorProfile>[];
      state = AsyncValue.data(previous);
    }
    state = await AsyncValue.guard(_load);
  }
}

final mediatorsProvider =
    AsyncNotifierProvider<MediatorsCatalogController, List<MediatorProfile>>(
  MediatorsCatalogController.new,
);

final mediatorSearchProvider = StateProvider<String>((ref) => '');

final filteredMediatorsProvider = Provider<AsyncValue<List<MediatorProfile>>>((ref) {
  final mediatorsAsync = ref.watch(mediatorsProvider);
  final search = ref.watch(mediatorSearchProvider).trim().toLowerCase();
  return mediatorsAsync.whenData((mediators) {
    if (search.isEmpty) return mediators;
    return mediators.where((mediator) {
      return mediator.name.toLowerCase().contains(search) ||
          mediator.code.toLowerCase().contains(search);
    }).toList();
  });
});

class MediatorFormData {
  const MediatorFormData({
    required this.name,
    required this.location,
    required this.phone,
    required this.code,
    this.id = '',
    this.createdAt,
  });

  final String id;
  final DateTime? createdAt;
  final String name;
  final String location;
  final String phone;
  final String code;

  MediatorProfile toMediator() {
    return MediatorProfile(
      id: id,
      name: name,
      location: location,
      phone: phone,
      code: code.trim().toUpperCase(),
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}

class MediatorActionsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> save(MediatorFormData form) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(mediatorsServiceProvider).saveMediator(form.toMediator()),
    );
    await ref.read(mediatorsProvider.notifier).refresh();
  }

  Future<void> delete(MediatorProfile mediator) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(mediatorsServiceProvider).deleteMediator(mediator),
    );
    await ref.read(mediatorsProvider.notifier).refresh();
  }
}

final mediatorActionsControllerProvider =
    AsyncNotifierProvider<MediatorActionsController, void>(
  MediatorActionsController.new,
);
