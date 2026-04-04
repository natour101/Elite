import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mediator.dart';
import '../services/mediators_service.dart';
import 'products_controller.dart';

final mediatorsServiceProvider = Provider<MediatorsService>((ref) {
  return MediatorsService(ref.watch(firestoreProvider));
});

final mediatorsProvider = StreamProvider<List<MediatorProfile>>((ref) {
  return ref.watch(mediatorsServiceProvider).watchMediators();
});

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
  }

  Future<void> delete(MediatorProfile mediator) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(mediatorsServiceProvider).deleteMediator(mediator),
    );
  }
}

final mediatorActionsControllerProvider =
    AsyncNotifierProvider<MediatorActionsController, void>(
  MediatorActionsController.new,
);
