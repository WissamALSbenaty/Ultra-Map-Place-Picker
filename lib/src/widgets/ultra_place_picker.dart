import 'package:flutter/material.dart';

import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:provider/provider.dart';
import 'package:ultra_map_place_picker/src/models/ultra_location_model.dart';
import 'package:ultra_map_place_picker/src/controllers/ultra_map_controller.dart';
import 'package:ultra_map_place_picker/src/enums.dart';
import 'package:ultra_map_place_picker/src/models/ultra_marker_model.dart';
import 'package:ultra_map_place_picker/src/models/ultra_polygon_model.dart';
import 'package:ultra_map_place_picker/src/models/ultra_polyline_model.dart';
import 'package:ultra_map_place_picker/src/providers/place_provider.dart';
import 'package:ultra_map_place_picker/src/models/ultra_circle_model.dart';
import 'package:ultra_map_place_picker/src/models/pick_result_model.dart';
import 'package:ultra_map_place_picker/src/typedefs.dart';
import 'package:ultra_map_place_picker/src/widgets/map_icons.dart';
import 'package:ultra_map_place_picker/src/widgets/pin_widget_selector.dart';
import 'package:ultra_map_place_picker/src/widgets/place_builder_selector.dart';
import 'package:ultra_map_place_picker/src/widgets/ultra_map.dart';
import 'package:ultra_map_place_picker/src/widgets/zoom_buttons.dart';

class UltraPlacePicker extends StatelessWidget {
  const UltraPlacePicker({
    required this.appBarKey,
    required this.isHuaweiDevice,
    required this.initialTarget,
    super.key,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.onSearchFailed,
    this.onMoveStart,
    this.onMapCreated,
    this.debounceMilliseconds,
    this.enableMapTypeButton,
    this.enableMyLocationButton,
    this.onToggleMapType,
    this.onMyLocation,
    this.onPlacePicked,
    this.usePinPointingSearch,
    this.usePlaceDetailSearch,
    this.selectInitialPosition,
    this.language,
    this.pickArea,
    this.forceSearchOnZoomChanged,
    this.hidePlaceDetailsWhenDraggingPin,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.selectText,
    this.outsideOfPickAreaText,
    this.zoomGesturesEnabled = true,
    this.zoomControlsEnabled = false,
    this.showPickedPlace = true,
    this.fullMotion = false,
    this.initialZoomValue = 15,
    this.polygons = const {},
    this.polylines = const {},
    this.markers = const {},
    this.enableScrolling = true,
  });

  final UltraLocationModel initialTarget;
  final GlobalKey appBarKey;

  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;
  final PinBuilder? pinBuilder;

  final ValueChanged<String>? onSearchFailed;
  final VoidCallback? onMoveStart;
  final void Function(UltraMapController)? onMapCreated;
  final VoidCallback? onToggleMapType;
  final VoidCallback? onMyLocation;
  final ValueChanged<PickResultModel>? onPlacePicked;

  final int? debounceMilliseconds;
  final bool? enableMapTypeButton;
  final bool? enableMyLocationButton;

  final bool? usePinPointingSearch;
  final bool? usePlaceDetailSearch;
  final bool isHuaweiDevice;
  final bool enableScrolling;
  final bool showPickedPlace;
  final bool? selectInitialPosition;

  final String? language;
  final UltraCircleModel? pickArea;

  final bool? forceSearchOnZoomChanged;
  final bool? hidePlaceDetailsWhenDraggingPin;

  /// GoogleMap pass-through events:
  final Function(PlaceProvider)? onCameraMoveStarted;
  final void Function(UltraLocationModel)? onCameraMove;
  final Function(PlaceProvider)? onCameraIdle;

  // strings
  final String? selectText;
  final String? outsideOfPickAreaText;

  /// Zoom feature toggle
  final bool zoomGesturesEnabled;
  final bool zoomControlsEnabled;
  final double initialZoomValue;

  /// Use never scrollable scroll-view with maximum dimensions to prevent unnecessary re-rendering.
  final bool fullMotion;

  final Set<UltraPolygonModel> polygons;
  final Set<UltraPolylineModel> polylines;
  final Set<UltraMarkerModel> markers;

  Future<void> _searchByCameraLocation(final PlaceProvider provider) async {
    // We don't want to search location again if camera location is changed by zooming in/out.
    if (forceSearchOnZoomChanged == false &&
        provider.prevCameraPosition != null &&
        provider.prevCameraPosition!.latitude ==
            provider.cameraPosition!.latitude &&
        provider.prevCameraPosition!.longitude ==
            provider.cameraPosition!.longitude) {
      provider.placeSearchingState = SearchingState.idle;
      return;
    }

    if (provider.cameraPosition == null) {
      // Camera position cannot be determined for some reason ...
      provider.placeSearchingState = SearchingState.idle;
      return;
    }

    provider.placeSearchingState = SearchingState.searching;

    final GeocodingResponse response =
        await provider.geocoding.searchByLocation(
      Location(
          lat: provider.cameraPosition!.latitude,
          lng: provider.cameraPosition!.longitude),
      language: language,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == 'REQUEST_DENIED') {
      if (onSearchFailed != null) {
        onSearchFailed!(response.status);
      }
      provider.placeSearchingState = SearchingState.idle;
      return;
    }

    if (usePlaceDetailSearch!) {
      final PlacesDetailsResponse detailResponse =
          await provider.places.getDetailsByPlaceId(
        response.results[0].placeId,
        language: language,
      );

      if (detailResponse.errorMessage?.isNotEmpty == true ||
          detailResponse.status == 'REQUEST_DENIED') {
        if (onSearchFailed != null) {
          onSearchFailed!(detailResponse.status);
        }
        provider.placeSearchingState = SearchingState.idle;
        return;
      }

      provider.selectedPlace =
          PickResultModel.fromPlaceDetailResult(detailResponse.result);
    } else {
      provider.selectedPlace =
          PickResultModel.fromGeocodingResult(response.results[0]);
    }

    provider.placeSearchingState = SearchingState.idle;
  }

  @override
  Widget build(final BuildContext context) {
    return Stack(
      children: <Widget>[
        if (fullMotion)
          SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      buildMapWidgetSelector(context),
                      PinWidgetSelector(
                        pinBuilder: pinBuilder,
                      ),
                    ],
                  ))),
        if (!fullMotion) ...[
          buildMapWidgetSelector(context),
          PinWidgetSelector(
            pinBuilder: pinBuilder,
          ),
        ],
        if (showPickedPlace)
          PlaceBuilderSelector(
            hidePlaceDetailsWhenDraggingPin: hidePlaceDetailsWhenDraggingPin,
            outsideOfPickAreaText: outsideOfPickAreaText,
            selectedPlaceWidgetBuilder: selectedPlaceWidgetBuilder,
            pickArea: pickArea,
            onPlacePicked: onPlacePicked,
            selectedText: selectText,
          ),
        MapIcons(
          appBarKey: appBarKey,
          enableMapTypeButton: enableMapTypeButton,
          onMyLocation: onMyLocation,
          onToggleMapType: onToggleMapType,
          enableMyLocationButton: enableMyLocationButton,
        ),
        if (zoomControlsEnabled) ZoomButtons()
      ],
    );
  }

  Widget buildMapWidgetSelector(BuildContext context) =>
      Selector<PlaceProvider, UltraMapType>(
          selector: (final _, final provider) => provider.mapType,
          builder: (final _, final mapType, final __) => UltraMap(
                enableScrolling: enableScrolling,
                provider: PlaceProvider.of(context, listen: false),
                isHuaweiDevice: isHuaweiDevice,
                initialTarget: initialTarget,
                mapType: mapType,
                searchByCameraLocation: _searchByCameraLocation,
                onMoveStart: onMoveStart,
                onMapCreated: onMapCreated,
                onPlacePicked: onPlacePicked,
                debounceMilliseconds: debounceMilliseconds,
                usePinPointingSearch: usePinPointingSearch,
                selectInitialPosition: selectInitialPosition,
                language: language,
                pickArea: pickArea,
                hidePlaceDetailsWhenDraggingPin:
                    hidePlaceDetailsWhenDraggingPin,
                onCameraMoveStarted: onCameraMoveStarted,
                onCameraMove: onCameraMove,
                onCameraIdle: onCameraIdle,
                selectText: selectText,
                zoomGesturesEnabled: zoomGesturesEnabled,
                zoomControlsEnabled: zoomControlsEnabled,
                initialZoomValue: initialZoomValue,
                polygons: polygons,
                polylines: polylines,
                markers: markers,
              ));
}
