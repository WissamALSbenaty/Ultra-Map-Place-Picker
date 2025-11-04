import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:huawei_map/huawei_map.dart';
import 'package:provider/provider.dart';
import 'package:ultra_map_place_picker/src/models/ultra_location_model.dart';
import 'package:ultra_map_place_picker/src/controllers/ultra_map_controller.dart';
import 'package:ultra_map_place_picker/src/enums.dart';
import 'package:ultra_map_place_picker/src/models/pick_result_model.dart';
import 'package:ultra_map_place_picker/src/third_parities_modules/abstract/i_live_location_module.dart';
import 'package:ultra_map_place_picker/src/third_parities_modules/abstract/i_permissions_handler_module.dart';
import 'package:ultra_map_place_picker/src/third_parities_modules/concrete/live_location_module.dart';
import 'package:ultra_map_place_picker/src/third_parities_modules/concrete/permissions_handler_module.dart';

class PlaceProvider extends ChangeNotifier {
  late GoogleMapsPlaces places;
  late GoogleMapsGeocoding geocoding;
  final void Function()? onLocationPermissionDenied;
  final ILiveLocationModule liveLocation = LiveLocationModule();
  final IPermissionsHandlerModule permissionsHandler =
      PermissionsHandlerModule();

  String? sessionToken;
  bool isOnUpdateLocationCoolDown = false;
  LocationAccuracy? desiredAccuracy;
  bool isAutoCompleteSearching = false;

  final List<UltraMapType> mapTypes;

  PlaceProvider(
      final String apiKey,
      this.onLocationPermissionDenied,
      final String? proxyBaseUrl,
      final Client? httpClient,
      final Map<String, dynamic> apiHeaders,
      this._zoomLevel,
      [this.mapTypes = UltraMapType.values]) {
    _mapType = mapTypes.first;
    _previousZoomLevel = _zoomLevel;
    places = GoogleMapsPlaces(
      apiKey: apiKey,
      baseUrl: proxyBaseUrl,
      httpClient: httpClient,
      apiHeaders: apiHeaders as Map<String, String>?,
    );
    geocoding = GoogleMapsGeocoding(
      apiKey: apiKey,
      baseUrl: proxyBaseUrl,
      httpClient: httpClient,
      apiHeaders: apiHeaders as Map<String, String>?,
    );
  }

  static PlaceProvider of(final BuildContext context,
          {final bool listen = true}) =>
      Provider.of<PlaceProvider>(context, listen: listen);

  Future<void> updateCurrentLocation({final bool gracefully = false}) async {
    _currentPosition = await liveLocation.getCurrentLocation(
        gracefully: gracefully, desiredAccuracy: desiredAccuracy);
    if (_currentPosition == null && !gracefully) {
      if (onLocationPermissionDenied == null) {
        await permissionsHandler.openAppSettings();
      } else {
        onLocationPermissionDenied!.call();
      }
    }
  }

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;
  set currentPosition(final Position? newPosition) {
    _currentPosition = newPosition;
    notifyListeners();
  }

  Timer? _debounceTimer;
  Timer? get debounceTimer => _debounceTimer;
  set debounceTimer(final Timer? timer) {
    _debounceTimer = timer;
    notifyListeners();
  }

  double _zoomLevel;
  late double _previousZoomLevel;
  double get zoomLevel => _zoomLevel;
  set zoomLevel(final double zoomLevel) {
    if (zoomLevel == _previousZoomLevel) return;
    _previousZoomLevel = _zoomLevel;
    _zoomLevel = zoomLevel;
    notifyListeners();
  }

  UltraLocationModel? _previousCameraPosition;
  UltraLocationModel? get prevCameraPosition => _previousCameraPosition;
  void setPrevCameraPosition(final UltraLocationModel? prePosition) {
    _previousCameraPosition = prePosition;
  }

  UltraLocationModel? _currentCameraPosition;
  UltraLocationModel? get cameraPosition => _currentCameraPosition;
  void setCameraPosition(final UltraLocationModel? newPosition) {
    _currentCameraPosition = newPosition;
  }

  PickResultModel? _selectedPlace;
  PickResultModel? get selectedPlace => _selectedPlace;
  set selectedPlace(final PickResultModel? result) {
    _selectedPlace = result;
    notifyListeners();
  }

  SearchingState _placeSearchingState = SearchingState.idle;
  SearchingState get placeSearchingState => _placeSearchingState;
  set placeSearchingState(final SearchingState newState) {
    _placeSearchingState = newState;
    notifyListeners();
  }

  final UltraMapController _mapController = UltraMapController();
  UltraMapController get mapController => _mapController;
  set googleController(final GoogleMapController? controller) {
    _mapController.completeGoogleController(controller);
    notifyListeners();
  }

  set huaweiController(final HuaweiMapController? controller) {
    _mapController.completeHuaweiController(controller);
    notifyListeners();
  }

  PinState _pinState = PinState.preparing;
  PinState get pinState => _pinState;
  set pinState(final PinState newState) {
    _pinState = newState;
    notifyListeners();
  }

  bool _isSearchBarFocused = false;
  bool get isSearchBarFocused => _isSearchBarFocused;
  set isSearchBarFocused(final bool focused) {
    _isSearchBarFocused = focused;
    notifyListeners();
  }

  late UltraMapType _mapType;
  UltraMapType get mapType => _mapType;
  void setUltraMapType(final UltraMapType mapType,
      {final bool notify = false}) {
    _mapType = mapType;
    if (notify) {
      notifyListeners();
    }
  }

  void switchUltraMapType() {
    _mapType = mapTypes[(mapTypes.indexOf(_mapType) + 1) % mapTypes.length];
    notifyListeners();
  }

  Future<void> animateCamera(final double latitude, final double longitude,
      final double zoomLevel) async {
    await mapController.animateCamera(
        target: UltraLocationModel(latitude, longitude), zoomLevel: zoomLevel);
  }

  Future<void> moveToCurrentPosition() async {
    if (currentPosition == null) {
      return;
    }
    await animateCamera(
        currentPosition!.latitude, currentPosition!.longitude, zoomLevel);
  }
}
