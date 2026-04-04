import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueBuilder<T> extends StatelessWidget {
  const AsyncValueBuilder({
    super.key,
    required this.value,
    required this.data,
    this.loadingMessage = 'جاري التحميل...',
    this.errorMessage = 'حدث خطأ أثناء تحميل البيانات.',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String loadingMessage;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => Center(child: Text(loadingMessage)),
      error: (error, stackTrace) => Center(child: Text(errorMessage)),
    );
  }
}
