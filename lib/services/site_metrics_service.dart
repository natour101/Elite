import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

class SiteMetrics {
  const SiteMetrics({
    required this.totalVisits,
    required this.todayVisits,
    required this.sales,
  });

  final int totalVisits;
  final int todayVisits;
  final int sales;
}

class SiteMetricsService {
  SiteMetricsService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection(AppConstants.publicMetricsCollection)
      .doc(AppConstants.storefrontMetricsDocument);

  Future<SiteMetrics> registerVisitAndFetchCount({required int sales}) async {
    final todayKey = _todayKey();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_doc);
      final currentData = snapshot.data() ?? const <String, dynamic>{};
      final currentTotal = (currentData['totalVisits'] as num?)?.toInt() ?? 0;
      final visitsByDate =
          (currentData['visitsByDate'] as Map<String, dynamic>?) ?? {};
      final todayCount = (visitsByDate[todayKey] as num?)?.toInt() ?? 0;

      transaction.set(_doc, {
        'totalVisits': currentTotal + 1,
        'visitsByDate': {
          ...visitsByDate,
          todayKey: todayCount + 1,
        },
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    });

    return fetchMetrics(sales: sales);
  }

  Future<SiteMetrics> fetchMetrics({required int sales}) async {
    final snapshot = await _doc.get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final todayKey = _todayKey();
    final visitsByDate = (data['visitsByDate'] as Map<String, dynamic>?) ?? {};

    return SiteMetrics(
      totalVisits: (data['totalVisits'] as num?)?.toInt() ?? 0,
      todayVisits: (visitsByDate[todayKey] as num?)?.toInt() ?? 0,
      sales: sales,
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
