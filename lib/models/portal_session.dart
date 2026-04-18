import 'mediator.dart';

enum PortalRole { admin, mediator }

class PortalSession {
  const PortalSession.admin({required this.username})
      : role = PortalRole.admin,
        mediator = null;

  const PortalSession.mediator({
    required this.username,
    required this.mediator,
  }) : role = PortalRole.mediator;

  final PortalRole role;
  final String username;
  final Mediator? mediator;

  bool get isAdmin => role == PortalRole.admin;
  bool get isMediator => role == PortalRole.mediator;
  String get displayName => isAdmin ? 'الإدارة العامة' : (mediator?.name ?? username);
}
