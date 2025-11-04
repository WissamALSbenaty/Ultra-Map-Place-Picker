import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hms_gms_availability/flutter_hms_gms_availability.dart';
import 'package:http/http.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:huawei_map/huawei_map.dart';
import 'package:ultra_map_place_picker/src/widgets/ultra_place_picker.dart';
import 'package:ultra_map_place_picker/ultra_map_place_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:ultra_map_place_picker/src/controllers/auto_complete_search_controller.dart';
import 'package:ultra_map_place_picker/src/providers/place_provider.dart';
import 'package:provider/provider.dart';
import 'package:ultra_map_place_picker/src/widgets/map_search_bar.dart';

class UltraMapPlacePicker extends StatefulWidget {
  const UltraMapPlacePicker({
    required this.initialPosition,
    required this.googleApiKey,
    required this.mapTypes,
    this.onLocationPermissionDenied,
    super.key,
    this.onPlacePicked,
    this.useCurrentLocation,
    this.desiredLocationAccuracy = LocationAccuracy.high,
    this.onMapCreated,
    this.hintText,
    this.searchingText,
    this.selectText,
    this.outsideOfPickAreaText,
    this.onAutoCompleteFailed,
    this.onGeocodingSearchFailed,
    this.proxyBaseUrl,
    this.httpClient,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.introModalWidgetBuilder,
    this.autoCompleteDebounceInMilliseconds = 500,
    this.cameraMoveDebounceInMilliseconds = 100,
    this.initialMapType = UltraMapType.normal,
    this.enableMapTypeButton = true,
    this.enableMyLocationButton = true,
    this.myLocationButtonCooldown = 10,
    this.usePinPointingSearch = true,
    this.usePlaceDetailSearch = false,
    this.enableScrolling = true,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteComponents,
    this.autocompleteTypes,
    this.strictBounds,
    this.region,
    this.pickArea,
    this.selectInitialPosition = true,
    this.resizeToAvoidBottomInset = true,
    this.initialSearchString,
    this.searchForInitialValue = false,
    this.forceSearchOnZoomChanged = false,
    this.autocompleteOnTrailingWhitespace = false,
    this.hidePlaceDetailsWhenDraggingPin = true,
    this.ignoreLocationPermissionErrors = false,
    this.enableSearching = true,
    this.onTapBack,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onMapTypeChanged,
    this.zoomGesturesEnabled = true,
    this.zoomControlsEnabled = false,
    this.showPickedPlace = true,
    this.initialZoomValue = 15,
    this.markers = const {},
    this.polygons = const {},
    this.polylines = const {},
  });

  /// The Google Maps API key for Places API and Geocoding API usage.
  final String googleApiKey;

  /// The initial location to center the map on.
  final UltraLocationModel initialPosition;

  /// Whether to use the user's current location as the initial position.
  final bool? useCurrentLocation;

  /// The desired accuracy for the user's location.
  final LocationAccuracy desiredLocationAccuracy;

  /// Hint text displayed in the search bar.
  final String? hintText;

  /// Text displayed while searching for a place.
  final String? searchingText;

  /// Text displayed on the 'select here' button.
  final String? selectText;

  /// Text displayed when the user tries to pick a location outside the pick area.
  final String? outsideOfPickAreaText;

  final ValueChanged<String>? onAutoCompleteFailed;

  /// Called when a geocoding search fails.
  final ValueChanged<String>? onGeocodingSearchFailed;

  final int autoCompleteDebounceInMilliseconds;
  final int cameraMoveDebounceInMilliseconds;

  final UltraMapType initialMapType;
  final bool enableMapTypeButton;
  final bool enableMyLocationButton;
  final bool enableScrolling;
  final bool showPickedPlace;
  final bool enableSearching;
  final int myLocationButtonCooldown;

  final bool usePinPointingSearch;
  final bool usePlaceDetailSearch;

  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictBounds;
  final String? region;

  final double initialZoomValue;
  final List<UltraMapType> Function(bool isHuaweiDevice) mapTypes;

  final void Function()? onLocationPermissionDenied;

  /// If set the picker can only pick addresses in the given circle area.
  /// The section will be highlighted.
  final UltraCircleModel? pickArea;

  /// If true the [body] and the scaffold's floating widgets should size
  /// themselves to avoid the onscreen keyboard whose height is defined by the
  /// ambient [MediaQuery]'s [MediaQueryData.viewInsets] `bottom` property.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// scaffold, the body can be resized to avoid overlapping the keyboard, which
  /// prevents widgets inside the body from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool resizeToAvoidBottomInset;

  final bool selectInitialPosition;

  /// By using default setting of Place Picker, it will result result when user hits the select here button.
  ///
  /// If you managed to use your own [selectedPlaceWidgetBuilder], then this WILL NOT be invoked, and you need use data which is
  /// being sent with [selectedPlaceWidgetBuilder].
  final ValueChanged<PickResultModel>? onPlacePicked;

  /// optional - builds selected place's UI
  ///
  /// It is provided by default if you leave it as a null.
  /// IMPORTANT: If this is non-null, [onPlacePicked] will not be invoked, as there will be no default 'Select here' button.
  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;

  /// optional - builds customized pin widget which indicates current pointing position.
  ///
  /// It is provided by default if you leave it as a null.
  final PinBuilder? pinBuilder;

  /// optional - builds customized introduction panel.
  ///
  /// None is provided / the map is instantly accessible if you leave it as a null.
  final IntroModalWidgetBuilder? introModalWidgetBuilder;

  /// optional - sets 'proxy' value in google_maps_webservice
  ///
  /// In case of using a proxy the baseUrl can be set.
  /// The googleApiKey is not required in case the proxy sets it.
  /// (Not storing the googleApiKey in the app is good practice)
  final String? proxyBaseUrl;

  /// optional - set 'client' value in google_maps_webservice
  ///
  /// In case of using a proxy url that requires authentication
  /// or custom configuration
  final BaseClient? httpClient;

  /// Initial value of autocomplete search
  final String? initialSearchString;

  /// Whether to search for the initial value or not
  final bool searchForInitialValue;

  /// Allow searching place when zoom has changed. By default searching is disabled when zoom has changed in order to prevent unwilling API usage.
  final bool forceSearchOnZoomChanged;

  /// Will perform an autocomplete search, if set to true. Note that setting
  /// this to true, while providing a smoother UX experience, may cause
  /// additional unnecessary queries to the Places API.
  ///
  /// Defaults to false.
  final bool autocompleteOnTrailingWhitespace;

  /// Whether to hide place details when dragging pin. Defaults to true.
  final bool hidePlaceDetailsWhenDraggingPin;

  /// Whether to ignore location permission errors. Defaults to false.
  /// If this is set to `true` the UI will be blocked.
  final bool ignoreLocationPermissionErrors;

  // Raised when clicking on the back arrow.
  // This will not listen for the system back button on Android devices.
  // If this is not set, but the back button is visible through automaticallyImplyLeading,
  // the Navigator will try to pop instead.
  final VoidCallback? onTapBack;

  /// GoogleMap pass-through events:

  /// Callback method for when the map is ready to be used.
  ///
  /// Used to receive a [GoogleMapController] for this [GoogleMap].
  final void Function(UltraMapController)? onMapCreated;

  /// Called when the camera starts moving.
  ///
  /// This can be initiated by the following:
  /// 1. Non-gesture animation initiated in response to user actions.
  ///    For example: zoom buttons, my location button, or marker clicks.
  /// 2. Programmatically initiated animation.
  /// 3. Camera motion initiated in response to user gestures on the map.
  ///    For example: pan, tilt, pinch to zoom, or rotate.
  final Function(PlaceProvider)? onCameraMoveStarted;

  /// Called repeatedly as the camera continues to move after an
  /// onCameraMoveStarted call.
  ///
  /// This may be called as often as once every frame and should
  /// not perform expensive operations.
  final void Function(UltraLocationModel)? onCameraMove;

  /// Called when camera movement has ended, there are no pending
  /// animations and the user has stopped interacting with the map.
  final Function(PlaceProvider)? onCameraIdle;

  /// Called when the map type has been changed.
  final Function(UltraMapType)? onMapTypeChanged;

  /// Toggle on & off zoom gestures
  final bool zoomGesturesEnabled;

  /// Allow user to make visible the zoom button
  final bool zoomControlsEnabled;

  final Set<UltraMarkerModel> markers;
  final Set<UltraPolygonModel> polygons;
  final Set<UltraPolylineModel> polylines;
  @override
  PlacePickerState createState() => PlacePickerState();
}

class PlacePickerState extends State<UltraMapPlacePicker> {
  GlobalKey appBarKey = GlobalKey();
  late final Future<PlaceProvider> _futureProvider;
  PlaceProvider? provider;
  AutoCompleteSearchController searchBarController =
      AutoCompleteSearchController();
  bool showIntroModal = true;
  bool isHuaweiDevice = false;

  @override
  void initState() {
    super.initState();
    _futureProvider = getPlaceProvider();
  }

  @override
  void dispose() {
    searchBarController.dispose();
    super.dispose();
  }

  Future<PlaceProvider> getPlaceProvider() async {
    try {
      isHuaweiDevice = !(await FlutterHmsGmsAvailability.isGmsAvailable) &&
          (await FlutterHmsGmsAvailability.isHmsAvailable);
      if (isHuaweiDevice) {
        HuaweiMapInitializer.initializeMap();
      }
    } catch (_) {}
    final Map<String, String> headers =
        await const GoogleApiHeaders().getHeaders();
    final PlaceProvider provider = PlaceProvider(
        widget.googleApiKey,
        widget.onLocationPermissionDenied,
        widget.proxyBaseUrl,
        widget.httpClient,
        headers,
        widget.initialZoomValue,
        widget.mapTypes(isHuaweiDevice));
    provider.sessionToken = const Uuid().v4();
    provider.desiredAccuracy = widget.desiredLocationAccuracy;
    provider.setUltraMapType(widget.initialMapType);
    if (widget.useCurrentLocation == true) {
      await provider.updateCurrentLocation(
          gracefully: widget.ignoreLocationPermissionErrors);
    }
    return provider;
  }

  @override
  Widget build(final BuildContext context) {
    return PopScope(
        onPopInvokedWithResult: (_, __) => searchBarController.clearOverlay(),
        child: FutureBuilder<PlaceProvider>(
          future: _futureProvider,
          builder: (final context, final snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
              provider = snapshot.data;
              return MultiProvider(
                providers: [
                  ChangeNotifierProvider<PlaceProvider>.value(value: provider!),
                ],
                child: Stack(children: [
                  Scaffold(
                    key: ValueKey<int>(provider.hashCode),
                    resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
                    extendBodyBehindAppBar: true,
                    appBar: widget.enableSearching
                        ? AppBar(
                            key: appBarKey,
                            automaticallyImplyLeading: false,
                            iconTheme: Theme.of(context).iconTheme,
                            elevation: 0,
                            surfaceTintColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            backgroundColor: Colors.transparent,
                            titleSpacing: 0.0,
                            title: MapSearchBar(
                                showIntroModal: showIntroModal,
                                introModalWidgetBuilder:
                                    widget.introModalWidgetBuilder,
                                onTapBack: widget.onTapBack,
                                appBarKey: appBarKey,
                                provider: provider,
                                searchBarController: searchBarController,
                                autocompleteOffset: widget.autocompleteOffset,
                                hintText: widget.hintText,
                                searchingText: widget.searchingText,
                                region: widget.region,
                                strictBounds: widget.strictBounds,
                                autocompleteTypes: widget.autocompleteTypes,
                                onAutoCompleteFailed:
                                    widget.onAutoCompleteFailed,
                                autoCompleteDebounceInMilliseconds:
                                    widget.autoCompleteDebounceInMilliseconds,
                                autocompleteRadius: widget.autocompleteRadius,
                                autocompleteLanguage:
                                    widget.autocompleteLanguage,
                                initialSearchString: widget.initialSearchString,
                                autocompleteOnTrailingWhitespace:
                                    widget.autocompleteOnTrailingWhitespace,
                                searchForInitialValue:
                                    widget.searchForInitialValue,
                                autocompleteComponents:
                                    widget.autocompleteComponents,
                                onPicked: _pickPrediction),
                          )
                        : null,
                    body: _buildMap(provider!.currentPosition == null
                        ? widget.initialPosition
                        : UltraLocationModel.fromPosition(
                            provider!.currentPosition!)),
                  ),
                  if (showIntroModal && widget.introModalWidgetBuilder != null)
                    widget.introModalWidgetBuilder!(context, () {
                      if (mounted) {
                        setState(() {
                          showIntroModal = false;
                        });
                      }
                    }),
                ]),
              );
            }

            final children = <Widget>[];
            if (snapshot.hasError) {
              children.addAll([
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                )
              ]);
            } else {
              children.add(const CircularProgressIndicator());
            }

            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              ),
            );
          },
        ));
  }

  Future<void> _pickPrediction(final Prediction prediction) async {
    provider!.placeSearchingState = SearchingState.searching;

    final PlacesDetailsResponse response =
        await provider!.places.getDetailsByPlaceId(
      prediction.placeId!,
      sessionToken: provider!.sessionToken,
      language: widget.autocompleteLanguage,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == 'REQUEST_DENIED') {
      if (widget.onAutoCompleteFailed != null) {
        widget.onAutoCompleteFailed!(response.status);
      }
      return;
    }

    provider!.selectedPlace =
        PickResultModel.fromPlaceDetailResult(response.result);

    // Prevents searching again by camera movement.
    provider!.isAutoCompleteSearching = true;

    await provider!.animateCamera(
        provider!.selectedPlace!.geometry!.location.lat,
        provider!.selectedPlace!.geometry!.location.lng,
        provider!.zoomLevel);

    if (provider == null) {
      return;
    }
    provider!.placeSearchingState = SearchingState.idle;
  }

  Widget _buildMap(final UltraLocationModel initialTarget) {
    return UltraPlacePicker(
      showPickedPlace: widget.showPickedPlace,
      enableScrolling: widget.enableScrolling,
      isHuaweiDevice: isHuaweiDevice,
      polygons: widget.polygons,
      polylines: widget.polylines,
      markers: widget.markers,
      initialZoomValue: widget.initialZoomValue,
      fullMotion: !widget.resizeToAvoidBottomInset,
      initialTarget: initialTarget,
      appBarKey: appBarKey,
      selectedPlaceWidgetBuilder: widget.selectedPlaceWidgetBuilder,
      pinBuilder: widget.pinBuilder,
      onSearchFailed: widget.onGeocodingSearchFailed,
      debounceMilliseconds: widget.cameraMoveDebounceInMilliseconds,
      enableMapTypeButton: widget.enableMapTypeButton,
      enableMyLocationButton: widget.enableMyLocationButton,
      usePinPointingSearch: widget.usePinPointingSearch,
      usePlaceDetailSearch: widget.usePlaceDetailSearch,
      onMapCreated: widget.onMapCreated,
      selectInitialPosition: widget.selectInitialPosition,
      language: widget.autocompleteLanguage,
      pickArea: widget.pickArea,
      forceSearchOnZoomChanged: widget.forceSearchOnZoomChanged,
      hidePlaceDetailsWhenDraggingPin: widget.hidePlaceDetailsWhenDraggingPin,
      selectText: widget.selectText,
      outsideOfPickAreaText: widget.outsideOfPickAreaText,
      onToggleMapType: () {
        if (provider == null) {
          return;
        }
        provider!.switchUltraMapType();
        if (widget.onMapTypeChanged != null) {
          widget.onMapTypeChanged!(provider!.mapType);
        }
      },
      onMyLocation: () async {
        // Prevent to click many times in short period.
        if (provider == null) {
          return;
        }
        if (provider!.isOnUpdateLocationCoolDown == false) {
          provider!.isOnUpdateLocationCoolDown = true;
          Timer(Duration(seconds: widget.myLocationButtonCooldown), () {
            provider!.isOnUpdateLocationCoolDown = false;
          });
          await provider!.updateCurrentLocation(
              gracefully: widget.ignoreLocationPermissionErrors);
          await provider!.moveToCurrentPosition();
        }
      },
      onMoveStart: () {
        if (provider == null) {
          return;
        }

        searchBarController.reset();
      },
      onPlacePicked: widget.onPlacePicked,
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
    );
  }
}
