import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/models/spothole.dart';
import 'package:spotholes_android/package/custom_info_windows.dart';
import 'package:spotholes_android/services/service_locator.dart';
import 'package:spotholes_android/widgets/register_spothole_modal.dart';

import '../utilities/custom_icons.dart';
import '../widgets/triangle_clipper.dart';

mixin RegisterSpothole {
  final markersSignal = getIt<Signal<Map<String, Marker>>>();
  final DatabaseReference databaseReference = GetIt.I<DatabaseReference>();
  final CustomInfoWindowController customInfoWindowController =
      GetIt.I<CustomInfoWindowController>();

  void editSpothole(String key) {}

  void deleteSpothole(String spotholeId) {
    final DatabaseReference databaseReference = GetIt.I<DatabaseReference>();
    DatabaseReference spotholeRef = databaseReference.child('spotholes');
    spotholeRef.child(spotholeId).remove();
    customInfoWindowController.hideInfoWindow!();
    markersSignal.value.remove(spotholeId);
  }

// void _showDeleteSpotholeAlertDialog(BuildContext context, String spotholeId) {
//   showDialog(
//     context: context,
//     builder: (BuildContext dialogContext) {
//       // Armazene o contexto em uma variável local
//       final localContext = dialogContext;
//       return DeleteSpotholeAlertDialog(
//         onConfirm: () {
//           deleteSpothole(spotholeId);
//           Navigator.of(localContext).pop(); // Feche o diálogo usando o contexto local
//         },
//       );
//     },
//   );
// }

  void addSpotholeMarker(String key, Spothole spothole) {
    final marker = Marker(
      markerId: MarkerId(key),
      icon: CustomIcons.potholeSignIcon,
      position: spothole.position,
      onTap: () {
        customInfoWindowController.addInfoWindow!(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spothole.getImageRiskByType(spothole.type),
                      const SizedBox(height: 8.0),
                      Text(
                        spothole.type.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.update, color: Colors.white),
                          const SizedBox(width: 4.0),
                          FittedBox(
                            child: Text(
                              Spothole.getFormattedTimeFromLastUpdate(
                                  spothole.dateOfUpdate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      PopupMenuButton<String>(
                        color: Colors.blue,
                        onSelected: (value) {
                          value == 'edit'
                              ? editSpothole(key)
                              : deleteSpothole(key);
                          // : showDeleteSpotholeAlertDialog(key); //TODO falta pegar contexto!!!!
                        },
                        itemBuilder: (BuildContext context) {
                          return <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              textStyle: TextStyle(
                                color: Colors.white,
                              ),
                              child: Text('Editar',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              textStyle: TextStyle(
                                color: Colors.white,
                              ),
                              child: Text('Excluir',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ];
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.all(3.0), // Espaçamento interno
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 1.0,
                            ),
                          ),
                          child: const Text(
                            'Mais',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // RawMaterialButton(
                      //   onPressed: () {
                      //     // Lógica para quando o botão for pressionado
                      //   },
                      //   shape: const StadiumBorder(
                      //     side: BorderSide(color: Colors.white),
                      //   ),
                      //   child: const Text(
                      //     'Mais',
                      //     style: TextStyle(color: Colors.white),
                      //   ),
                      // )
                    ],
                  ),
                ),
              ),
              ClipPath(
                clipper: TriangleClipper(),
                child: Container(
                  color: Colors.blue,
                  height: 10,
                  width: 20,
                ),
              ),
            ],
          ),
          spothole.position,
        );
      },
    );
    markersSignal.value[key] = marker;
  }

  // void addSpotholeMarker(String key, Spothole spothole) {
  //   final marker = Marker(
  //     markerId: MarkerId(key),
  //     icon: CustomIcons.potholeSignIcon,
  //     position: spothole.position,
  //     onTap: () {
  //       customInfoWindowController.addInfoWindow!(
  //         Column(
  //           children: [
  //             Expanded(
  //               child: Container(
  //                 // width: 300,
  //                 // height: 100,
  //                 // Container(
  //                 decoration: BoxDecoration(
  //                   color: Colors.blue,
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(12.0),
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Spothole.getImageRiskByType(spothole.type),
  //                       const SizedBox(height: 8.0),
  //                       Text(
  //                         spothole.type.text,
  //                         style: const TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           const Icon(Icons.update, color: Colors.white),
  //                           const SizedBox(width: 4.0),
  //                           FittedBox(
  //                               child: Text(
  //                             Spothole.getFormattedTimeFromLastUpdate(
  //                                 spothole.dateOfUpdate),
  //                             style: const TextStyle(
  //                               color: Colors.white,
  //                               // fontSize: 18,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           )),
  //                         ],
  //                       )
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             ClipPath(
  //               clipper: TriangleClipper(),
  //               child: Container(
  //                 color: Colors.blue,
  //                 height: 10,
  //                 width: 20,
  //               ),
  //             ),
  //           ],
  //         ),
  //         spothole.position,
  //       );
  //     },
  //   );
  //   markersSignal.value[key] = marker;
  // }

  void loadSpotholeMarkers() {
    databaseReference.child('spotholes').once().then((DatabaseEvent event) {
      final spotholesMap = event.snapshot.value as Map?;
      if (spotholesMap != null) {
        spotholesMap.forEach((key, value) {
          final spothole =
              Spothole.fromJson(Map<String, dynamic>.from(value as Map));
          addSpotholeMarker(key, spothole);
        });
      }
    });
  }

  void registerSpothole(position, category, type) {
    final DatabaseReference databaseReference = GetIt.I<DatabaseReference>();
    DatabaseReference spotholeRef = databaseReference.child('spotholes');
    Spothole newSpothole = Spothole(DateTime.now().toUtc(),
        DateTime.now().toUtc(), position, category, type);
    final newSpotHoleRef = spotholeRef.push();
    newSpotHoleRef.set(newSpothole.toJson());
    addSpotholeMarker(newSpotHoleRef.key!, newSpothole);
  }

  void registerSpotholeModal(context, position) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return RegisterSpotholeModal(
          latLng: LatLng(position!.latitude!, position!.longitude!),
        );
      },
    );
  }
}
