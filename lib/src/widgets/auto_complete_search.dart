import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:ultra_map_place_picker/src/enums.dart';
import 'package:ultra_map_place_picker/src/widgets/prediction_tile.dart';
import 'package:ultra_map_place_picker/src/widgets/rounded_frame.dart';
import 'package:provider/provider.dart';
import 'package:ultra_map_place_picker/src/providers/search_provider.dart';
import 'package:ultra_map_place_picker/src/controllers/auto_complete_search_controller.dart';
import 'package:ultra_map_place_picker/src/widgets/text_clear_icon.dart';
import 'package:ultra_map_place_picker/src/providers/place_provider.dart';

class AutoCompleteSearch extends StatefulWidget {
  const AutoCompleteSearch(
      {required this.autoCompleteSearchController,
      required this.sessionToken,
      required this.onPicked,
      required this.appBarKey,
      super.key,
      this.hintText = 'Search here',
      this.searchingText = 'Searching...',
      this.hidden = false,
      this.height = 40,
      this.contentPadding = EdgeInsets.zero,
      this.debounceMilliseconds,
      this.onSearchFailed,
      this.autocompleteOffset,
      this.autocompleteRadius,
      this.autocompleteLanguage,
      this.autocompleteComponents,
      this.autocompleteTypes,
      this.strictBounds,
      this.region,
      this.initialSearchString,
      this.searchForInitialValue,
      this.autocompleteOnTrailingWhitespace});

  final String? sessionToken;
  final String? hintText;
  final String? searchingText;
  final bool hidden;
  final double height;
  final EdgeInsetsGeometry contentPadding;
  final int? debounceMilliseconds;
  final ValueChanged<Prediction> onPicked;
  final ValueChanged<String>? onSearchFailed;
  final AutoCompleteSearchController autoCompleteSearchController;
  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictBounds;
  final String? region;
  final GlobalKey appBarKey;
  final String? initialSearchString;
  final bool? searchForInitialValue;
  final bool? autocompleteOnTrailingWhitespace;

  @override
  AutoCompleteSearchState createState() => AutoCompleteSearchState();
}

class AutoCompleteSearchState extends State<AutoCompleteSearch> {
  TextEditingController controller = TextEditingController();
  FocusNode focus = FocusNode();
  OverlayEntry? overlayEntry;
  SearchProvider provider = SearchProvider();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchString != null) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        controller.text = widget.initialSearchString!;
        if (widget.searchForInitialValue!) {
          _onSearchInputChange();
        }
      });
    }
    controller.addListener(_onSearchInputChange);
    focus.addListener(_onFocusChanged);

    widget.autoCompleteSearchController.attach(this);
  }

  @override
  void dispose() {
    controller.removeListener(_onSearchInputChange);
    controller.dispose();

    focus.removeListener(_onFocusChanged);
    focus.dispose();
    clearOverlay();

    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return !widget.hidden
        ? ChangeNotifierProvider.value(
            value: provider,
            child: RoundedFrame(
              height: widget.height,
              padding: const EdgeInsets.only(right: 10),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black54
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 4.0,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 10),
                  const Icon(Icons.search),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                    controller: controller,
                    focusNode: focus,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      border: InputBorder.none,
                      errorBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: widget.contentPadding,
                    ),
                  )),
                  TextClearIcon(
                    onTap: clearText,
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  void _onSearchInputChange() {
    if (!mounted) {
      return;
    }
    this.provider.searchTerm = controller.text;

    final PlaceProvider provider = PlaceProvider.of(context, listen: false);

    if (controller.text.isEmpty) {
      provider.debounceTimer?.cancel();
      _searchPlace(controller.text);
      return;
    }

    if (controller.text.trim() == this.provider.prevSearchTerm.trim()) {
      provider.debounceTimer?.cancel();
      return;
    }

    if (!widget.autocompleteOnTrailingWhitespace! &&
        controller.text.substring(controller.text.length - 1) == ' ') {
      provider.debounceTimer?.cancel();
      return;
    }

    if (provider.debounceTimer?.isActive ?? false) {
      provider.debounceTimer!.cancel();
    }

    provider.debounceTimer =
        Timer(Duration(milliseconds: widget.debounceMilliseconds!), () {
      _searchPlace(controller.text.trim());
    });
  }

  void _onFocusChanged() {
    final PlaceProvider provider = PlaceProvider.of(context, listen: false);
    provider.isSearchBarFocused = focus.hasFocus;
    provider.debounceTimer?.cancel();
    provider.placeSearchingState = SearchingState.idle;
  }

  void _searchPlace(final String searchTerm) {
    provider.prevSearchTerm = searchTerm;

    clearOverlay();

    if (searchTerm.isEmpty) {
      return;
    }

    _displayOverlay(_buildSearchingOverlay());

    _performAutoCompleteSearch(searchTerm);
  }

  void clearOverlay() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
  }

  void _displayOverlay(final Widget overlayChild) {
    clearOverlay();

    final RenderBox? appBarRenderBox =
        widget.appBarKey.currentContext!.findRenderObject() as RenderBox?;
    final translation = appBarRenderBox?.getTransformTo(null).getTranslation();
    final Offset offset = translation != null
        ? Offset(translation.x, translation.y)
        : const Offset(0.0, 0.0);
    final screenWidth = MediaQuery.of(context).size.width;

    overlayEntry = OverlayEntry(
      builder: (final context) => Positioned(
        top: appBarRenderBox!.paintBounds.shift(offset).top +
            appBarRenderBox.size.height,
        left: screenWidth * 0.025,
        right: screenWidth * 0.025,
        child: Material(
          elevation: 4.0,
          child: overlayChild,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  Widget _buildSearchingOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              widget.searchingText ?? 'Searching...',
              style: const TextStyle(fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPredictionOverlay(final List<Prediction> predictions) {
    return ListBody(
      children: predictions
          .map(
            (final p) => PredictionTile(
              prediction: p,
              onTap: (final selectedPrediction) {
                resetSearchBar();
                widget.onPicked(selectedPrediction);
              },
            ),
          )
          .toList(),
    );
  }

  Future<void> _performAutoCompleteSearch(final String searchTerm) async {
    final PlaceProvider provider = PlaceProvider.of(context, listen: false);

    if (searchTerm.isNotEmpty) {
      final PlacesAutocompleteResponse response =
          await provider.places.autocomplete(
        searchTerm,
        sessionToken: widget.sessionToken,
        location: provider.currentPosition == null
            ? null
            : Location(
                lat: provider.currentPosition!.latitude,
                lng: provider.currentPosition!.longitude),
        offset: widget.autocompleteOffset,
        radius: widget.autocompleteRadius,
        language: widget.autocompleteLanguage,
        types: widget.autocompleteTypes ?? const [],
        components: widget.autocompleteComponents ?? const [],
        strictbounds: widget.strictBounds ?? false,
        region: widget.region,
      );

      if (response.errorMessage?.isNotEmpty == true ||
          response.status == 'REQUEST_DENIED') {
        if (widget.onSearchFailed != null) {
          widget.onSearchFailed!(response.status);
        }
        return;
      }

      _displayOverlay(_buildPredictionOverlay(response.predictions));
    }
  }

  void clearText() {
    provider.searchTerm = '';
    controller.clear();
  }

  void resetSearchBar() {
    clearText();
    focus.unfocus();
  }
}
