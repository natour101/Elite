import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/portal_session.dart';
import 'mediators_controller.dart';

class PortalSessionController extends AsyncNotifier<PortalSession?> {
  @override
  Future<PortalSession?> build() async => null;

  Future<bool> login(String username) async {
    final normalized = username.trim().toUpperCase();
    if (normalized.isEmpty) return false;

    if (normalized == AppConstants.adminUsername) {
      state = const AsyncValue.data(
        PortalSession.admin(username: AppConstants.adminUsername),
      );
      return true;
    }

    final mediator =
        await ref.read(mediatorsServiceProvider).findByLoginKey(normalized);
    if (mediator == null) return false;

    state = AsyncValue.data(
      PortalSession.mediator(username: normalized, mediator: mediator),
    );
    return true;
  }

  void logout() {
    state = const AsyncValue.data(null);
  }
}

final portalSessionProvider =
    AsyncNotifierProvider<PortalSessionController, PortalSession?>(
  PortalSessionController.new,
);
