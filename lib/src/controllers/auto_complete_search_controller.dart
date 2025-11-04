import 'package:flutter/cupertino.dart';
import 'package:ultra_map_place_picker/src/widgets/auto_complete_search.dart';

class AutoCompleteSearchController extends ChangeNotifier {
  AutoCompleteSearchState? _autoCompleteSearch;

  void attach(final AutoCompleteSearchState searchWidget) {
    _autoCompleteSearch = searchWidget;
  }

  /// Just clears text.
  void clear() {
    _autoCompleteSearch?.clearText();
  }

  /// Clear and remove focus (Dismiss keyboard)
  void reset() {
    _autoCompleteSearch?.resetSearchBar();
  }

  void clearOverlay() {
    _autoCompleteSearch?.clearOverlay();
  }
}
