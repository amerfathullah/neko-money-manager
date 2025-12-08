import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/default_data_service.dart';

final defaultDataServiceProvider = Provider<DefaultDataService>((ref) {
  return DefaultDataService(FirebaseFirestore.instance);
});
