import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/default_data_service.dart';

final defaultDataServiceProvider = Provider<DefaultDataService>((ref) {
  return DefaultDataService();
});
