import 'dart:async';

Stream<List<T>> pollingListStream<T>(
  Future<List<T>> Function() loader, {
  Duration interval = const Duration(seconds: 4),
}) async* {
  yield await loader();
  while (true) {
    await Future<void>.delayed(interval);
    yield await loader();
  }
}
