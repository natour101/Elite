import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mediator.dart';
import '../services/mediators_service.dart';
import 'products_controller.dart';

final mediatorsServiceProvider = Provider<MediatorsService>((ref) {
  return MediatorsService(ref.watch(firestoreProvider));
});

final mediatorsProvider = FutureProvider<List<Mediator>>((ref) async {
  return ref.watch(mediatorsServiceProvider).fetchMediators();
});
