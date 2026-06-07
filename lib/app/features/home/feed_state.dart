import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';

class FeedQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query.trim().toLowerCase();
  
  void clear() => state = '';
}

final feedQueryProvider = NotifierProvider<FeedQueryNotifier, String>(FeedQueryNotifier.new);

class FeedFilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void setFilters(FilterState filters) => state = filters;

  void reset() => state = const FilterState();
}

final feedFilterProvider = NotifierProvider<FeedFilterNotifier, FilterState>(FeedFilterNotifier.new);
