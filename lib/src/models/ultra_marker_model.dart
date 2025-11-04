import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:huawei_map/huawei_map.dart' as hm;
import 'package:ultra_map_place_picker/src/models/ultra_location_model.dart';

import 'ultra_bitmap_descriptor_model.dart';
import 'ultra_info_window_model.dart';

/// Defines an icon placed at a specified position on a map.

class UltraMarkerModel {
  /// Unique marker ID.
  final String markerId;

  /// Position of a
  final UltraLocationModel position;

  /// Information window of a
  final UltraInfoWindowModel infoWindow;

  /// Anchor point of a
  final Offset anchor;

  /// Indicates whether a marker can be dragged.
  ///
  /// The options are `true` (yes) and `false` (no).
  final bool draggable;

  /// Indicates whether to flatly attach a marker to the map.
  ///
  /// If the marker is flatly attached to the map, it will stay on the map when the camera rotates or tilts.
  /// The marker will remain the same size when the camera zooms in or out.
  /// If the marker faces the camera, it will always be drawn facing the camera and rotates or tilts with the camera.
  final bool flat;

  /// UltraMarkerModel icon to render.
  final UltraBitmapDescriptorModel icon;

  /// Rotation angle of a marker, in degrees.
  final double rotation;

  /// Opacity.
  ///
  /// The value ranges from `0` (completely transparent) to `1` (completely opaque).
  final double alpha;

  /// Indicates whether a marker is visible.
  ///
  /// The options are `true` (yes) and `false` (no).
  final bool visible;

  /// Z-index of a
  ///
  /// The z-index indicates the overlapping order of a
  /// A marker with a larger z-index overlaps that with a smaller z-index.
  /// UltraMarkerModels with the same z-index overlap each other in a random order.
  /// By default, the z-index is `0`.
  final double zIndex;

  /// Indicates whether a marker can be tapped.
  ///
  /// The options are `true` (yes) and `false` (no).
  final bool clickable;

  /// Indicates whether a marker is clusterable or not.
  final bool clusterable;

  /// Callback method executed when a marker is tapped.
  final VoidCallback? onClick;

  /// Callback method executed when marker dragging is finished.
  final ValueChanged<UltraLocationModel>? onDragEnd;

  /// Callback method executed when marker dragging is started.
  final ValueChanged<UltraLocationModel>? onDragStart;

  /// Callback method executed while marker is dragging.
  final ValueChanged<UltraLocationModel>? onDrag;

  /// Creates a [UltraMarkerModel] object.
  const UltraMarkerModel({
    required this.markerId,
    required this.position,
    this.infoWindow = UltraInfoWindowModel.noText,
    this.anchor = const Offset(0.5, 1.0),
    this.draggable = false,
    this.flat = false,
    this.icon = UltraBitmapDescriptorModel.defaultMarker,
    this.rotation = 0.0,
    this.alpha = 1.0,
    this.visible = true,
    this.zIndex = 0,
    this.clickable = false,
    this.clusterable = false,
    this.onClick,
    this.onDragEnd,
    this.onDragStart,
    this.onDrag,
  });

  /// Copies a [UltraMarkerModel] object and updates the specified attributes.
  UltraMarkerModel updateCopy({
    UltraLocationModel? position,
    UltraInfoWindowModel? infoWindow,
    Offset? anchor,
    bool? draggable,
    bool? flat,
    UltraBitmapDescriptorModel? icon,
    double? rotation,
    double? alpha,
    bool? visible,
    int? zIndex,
    bool? clickable,
    bool? clusterable,
    VoidCallback? onClick,
    ValueChanged<UltraLocationModel>? onDragEnd,
    ValueChanged<UltraLocationModel>? onDragStart,
    ValueChanged<UltraLocationModel>? onDrag,
    List<dynamic>? animations,
  }) {
    return UltraMarkerModel(
      markerId: markerId,
      position: position ?? this.position,
      infoWindow: infoWindow ?? this.infoWindow,
      anchor: anchor ?? this.anchor,
      draggable: draggable ?? this.draggable,
      flat: flat ?? this.flat,
      icon: icon ?? this.icon,
      rotation: rotation ?? this.rotation,
      alpha: alpha ?? this.alpha,
      visible: visible ?? this.visible,
      zIndex: zIndex?.toDouble() ?? this.zIndex,
      clickable: clickable ?? this.clickable,
      clusterable: clusterable ?? this.clusterable,
      onClick: onClick ?? this.onClick,
      onDragEnd: onDragEnd ?? this.onDragEnd,
      onDragStart: onDragStart ?? this.onDragStart,
      onDrag: onDrag ?? this.onDrag,
    );
  }

  hm.Marker get huaweiMarker => hm.Marker(
      markerId: hm.MarkerId(markerId),
      position: position.huaweiLatLng,
      infoWindow: infoWindow.huaweiWindow,
      anchor: anchor,
      draggable: draggable,
      flat: flat,
      icon: icon.huaweiBitmap,
      rotation: rotation,
      alpha: alpha,
      visible: visible,
      zIndex: zIndex,
      clickable: clickable,
      clusterable: clusterable,
      onClick: onClick,
      onDragEnd: (latLng) =>
          onDragEnd?.call(UltraLocationModel.fromHuaweiLatLng(latLng)),
      onDragStart: (latLng) =>
          onDragStart?.call(UltraLocationModel.fromHuaweiLatLng(latLng)),
      onDrag: (latLng) =>
          onDrag?.call(UltraLocationModel.fromHuaweiLatLng(latLng)));

  gm.Marker get googleMarker => gm.Marker(
        markerId: gm.MarkerId(markerId),
        position: position.googleLatLng,
        infoWindow: infoWindow.googleWindow,
        anchor: anchor,
        draggable: draggable,
        flat: flat,
        icon: icon.googleBitmap,
        rotation: rotation,
        alpha: alpha,
        visible: visible,
        zIndexInt: zIndex.round(),
        onTap: onClick,
        onDragEnd: (latLng) =>
            onDragEnd?.call(UltraLocationModel.fromGoogleLatLng(latLng)),
        onDragStart: (latLng) =>
            onDragStart?.call(UltraLocationModel.fromGoogleLatLng(latLng)),
        onDrag: (latLng) =>
            onDrag?.call(UltraLocationModel.fromGoogleLatLng(latLng)),
      );

  /// Clones a [UltraMarkerModel] object.
  UltraMarkerModel clone() => updateCopy();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is UltraMarkerModel &&
        markerId == other.markerId &&
        position == other.position &&
        infoWindow == other.infoWindow &&
        anchor == other.anchor &&
        draggable == other.draggable &&
        flat == other.flat &&
        icon == other.icon &&
        rotation == other.rotation &&
        alpha == other.alpha &&
        visible == other.visible &&
        clickable == other.clickable &&
        clusterable == other.clusterable &&
        zIndex == other.zIndex;
  }

  @override
  int get hashCode => markerId.hashCode;
}
