import 'package:flutter/material.dart';
import '../../services/api_client.dart';

/// Pembungkus FutureBuilder: loading -> error -> data.
/// Pastikan `future` dibuat sekali (di initState), bukan di build().
class AsyncBody<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;

  const AsyncBody({super.key, required this.future, required this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Center(
            child: Text(error is ApiException ? error.message : 'Gagal memuat data'),
          );
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}
