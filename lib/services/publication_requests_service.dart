import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/polling_stream.dart';
import '../models/publication_request.dart';

class PublicationRequestsService {
  PublicationRequestsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.publicationRequestsCollection);

  Stream<List<PublicationRequest>> watchMediatorRequests(String mediatorCode) {
    return pollingListStream(() => _fetchMediatorRequests(mediatorCode));
  }

  Future<List<PublicationRequest>> _fetchMediatorRequests(String mediatorCode) async {
    final snapshot = await _collection
        .where('mediatorCode', isEqualTo: mediatorCode.toUpperCase())
        .get();
    final requests = snapshot.docs
        .map((doc) => PublicationRequest.fromMap(doc.id, doc.data()))
        .toList();
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  Future<void> createRequest(PublicationRequest request) async {
    await _collection.add(request.toMap());
  }
}
