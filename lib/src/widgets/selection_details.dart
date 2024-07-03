import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ultra_map_place_picker/src/models/ultra_circle_model.dart';
import 'package:ultra_map_place_picker/src/models/pick_result_model.dart';

class SelectionDetails extends StatelessWidget {
  final PickResultModel result;
  final UltraCircleModel? pickArea;
  final ValueChanged<PickResultModel>? onPlacePicked;
  final String? selectText;
  final String? outsideOfPickAreaText;
  const SelectionDetails(
      {super.key,
      required this.result,
      required this.pickArea,
      required this.selectText,
      required this.outsideOfPickAreaText,
      required this.onPlacePicked});

  @override
  Widget build(BuildContext context) {
    final bool canBePicked = pickArea == null ||
        pickArea!.toGoogleCircle.radius <= 0 ||
        Geolocator.distanceBetween(
                pickArea!.center.latitude,
                pickArea!.center.longitude,
                result.geometry!.location.lat,
                result.geometry!.location.lng) <=
            pickArea!.toGoogleCircle.radius;
    final WidgetStateColor buttonColor = WidgetStateColor.resolveWith(
        (final states) => canBePicked ? Colors.lightGreen : Colors.red);
    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Text(
            result.formattedAddress!,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          (canBePicked && (selectText?.isEmpty ?? true)) ||
                  (!canBePicked && (outsideOfPickAreaText?.isEmpty ?? true))
              ? SizedBox.fromSize(
                  size: const Size(56, 56), // button width and height
                  child: ClipOval(
                    child: Material(
                      child: InkWell(
                          overlayColor: buttonColor,
                          onTap: () {
                            if (canBePicked) {
                              onPlacePicked!(result);
                            }
                          },
                          child: Icon(
                              canBePicked
                                  ? Icons.check_sharp
                                  : Icons.app_blocking_sharp,
                              color: buttonColor)),
                    ),
                  ),
                )
              : SizedBox.fromSize(
                  size: Size(MediaQuery.of(context).size.width * 0.8,
                      56), // button width and height
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Material(
                      child: InkWell(
                          overlayColor: buttonColor,
                          onTap: () {
                            if (canBePicked) {
                              onPlacePicked!(result);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  canBePicked
                                      ? Icons.check_sharp
                                      : Icons.app_blocking_sharp,
                                  color: buttonColor),
                              SizedBox.fromSize(size: const Size(10, 0)),
                              Text(
                                  canBePicked
                                      ? selectText!
                                      : outsideOfPickAreaText!,
                                  style: TextStyle(color: buttonColor))
                            ],
                          )),
                    ),
                  ),
                )
        ],
      ),
    );
  }
}
