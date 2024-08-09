import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/controllers/route_controller.dart';
import 'package:spotholes_android/utilities/maneuver_icons.dart';

import '../../utilities/custom_icons.dart';
import '../button/custom_button.dart';

class RouteDraggableSheetController {
  Function(String)? updateData;

  void dispose() {
    updateData = null;
  }
}

class RouteDraggableSheet extends StatefulWidget {
  const RouteDraggableSheet({
    super.key,
    required this.controller,
    required this.destinationLocation,
  });

  final RouteDraggableSheetController controller;
  final LatLng destinationLocation;

  @override
  RouteDraggableSheetState createState() => RouteDraggableSheetState();
}

class RouteDraggableSheetState extends State<RouteDraggableSheet> {
  final _routeController = RouteController.instance;
  final scrollController = ScrollController();

  final draggableController = DraggableScrollableController();
  final _draggableExtentNotifier = signal(0.0);
  final _minDraggableChildSize = 0.28;
  final _maxDraggableChildSize = 0.6;
  final _intermediateDraggableChildSize = 0.4;
  int? _selectedIndex;

  late final _canvasColor = Theme.of(context).canvasColor;

  late final _directionResult = _routeController.directionResult;
  late final _route = _directionResult.value.routes![0];
  late final _leg = _route.legs![0];
  late final _steps = _leg.steps!;

  @override
  void initState() {
    super.initState();
    draggableController.addListener(_updateExtent);
  }

  void _updateExtent() {
    _draggableExtentNotifier.value = draggableController.size;
  }

  void changeSizeDraggableScrollableSheet(double size) =>
      draggableController.animateTo(
        size,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );

  @override
  void dispose() {
    _routeController.dispose();
    draggableController.removeListener(_updateExtent);
    draggableController.dispose();
    _draggableExtentNotifier.dispose();
    super.dispose();
  }

  List<Widget> _horizontalListButtons(BuildContext context, position) {
    return [
      CustomButton(
        label: 'Iniciar viagem',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => {},
      ),
      CustomButton(
        label: 'Centralizar',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => {
          _routeController.centerViewRoute(),
          changeSizeDraggableScrollableSheet(_minDraggableChildSize),
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      (context) => Column(
        children: [
          Expanded(
            child: DraggableScrollableSheet(
              controller: draggableController,
              maxChildSize: _maxDraggableChildSize,
              minChildSize: _minDraggableChildSize,
              initialChildSize: _minDraggableChildSize,
              snap: true,
              snapSizes: [_minDraggableChildSize, _maxDraggableChildSize],
              builder: (BuildContext context, scrollController) {
                return Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: _canvasColor,
                    border: Border.all(width: 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).hintColor,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                              ),
                              height: 4,
                              width: 40,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        SliverAppBar(
                          title: const Text('Etapas da Rota'),
                          primary: false,
                          pinned: true,
                          centerTitle: true,
                          backgroundColor: _canvasColor,
                          leading: Watch.builder(
                            builder: (context) => IconButton(
                              icon: Icon(
                                _draggableExtentNotifier.value <
                                        _maxDraggableChildSize
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              onPressed: () {
                                if (_draggableExtentNotifier.value <
                                    _maxDraggableChildSize) {
                                  changeSizeDraggableScrollableSheet(
                                    _maxDraggableChildSize,
                                  );
                                } else {
                                  changeSizeDraggableScrollableSheet(
                                    _minDraggableChildSize,
                                  );
                                }
                              },
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _steps.length + 2,
                                separatorBuilder: (context, index) {
                                  return const Divider();
                                },
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return ListTile(
                                      title: Text(
                                        'Partida: ${_leg.startAddress!}',
                                      ),
                                      leading: SizedBox(
                                        height: 35,
                                        width: 35,
                                        child: CustomIcons.sourceIconAsset,
                                      ),
                                      selected: _selectedIndex == 0,
                                      tileColor: _selectedIndex == 0
                                          ? Colors.amber
                                          : null,
                                      selectedColor: Theme.of(context)
                                          .listTileTheme
                                          .selectedColor,
                                      selectedTileColor: Theme.of(context)
                                          .listTileTheme
                                          .selectedTileColor,
                                      onTap: () => {
                                        setState(() {
                                          _selectedIndex = 0;
                                        }),
                                        changeSizeDraggableScrollableSheet(
                                            _intermediateDraggableChildSize),
                                        _routeController
                                            .updateCamera(_leg.startLocation!),
                                      },
                                    );
                                  } else if (index == _steps.length + 1) {
                                    return ListTile(
                                      selected:
                                          _selectedIndex == _steps.length + 1,
                                      tileColor:
                                          _selectedIndex == _steps.length + 1
                                              ? Colors.amber
                                              : null,
                                      selectedColor: Theme.of(context)
                                          .listTileTheme
                                          .selectedColor,
                                      selectedTileColor: Theme.of(context)
                                          .listTileTheme
                                          .selectedTileColor,
                                      onTap: () => {
                                        setState(() {
                                          _selectedIndex = index;
                                        }),
                                        changeSizeDraggableScrollableSheet(
                                            _intermediateDraggableChildSize),
                                        _routeController
                                            .updateCamera(_leg.endLocation!),
                                      },
                                      title: Text(
                                        'Destino: ${_leg.endAddress!}',
                                      ),
                                      leading: SizedBox(
                                        height: 35,
                                        width: 35,
                                        child: CustomIcons.destinationIconAsset,
                                      ),
                                    );
                                  } else {
                                    final step = _steps[index - 1];
                                    final maneuver =
                                        step.maneuver ?? 'straight';
                                    final icon = maneuverIcons[maneuver] ??
                                        Icons.directions;
                                    return ListTile(
                                      selected: _selectedIndex == index,
                                      tileColor: _selectedIndex == index
                                          ? Colors.amber
                                          : null,
                                      selectedColor: Theme.of(context)
                                          .listTileTheme
                                          .selectedColor,
                                      selectedTileColor: Theme.of(context)
                                          .listTileTheme
                                          .selectedTileColor,
                                      onTap: () => {
                                        setState(() {
                                          _selectedIndex = index;
                                        }),
                                        changeSizeDraggableScrollableSheet(
                                            _intermediateDraggableChildSize),
                                        maneuver == 'straight'
                                            ? _routeController
                                                .newCameraLatLngBoundsFromStep(
                                                step,
                                              )
                                            : _routeController.updateCamera(
                                                step.startLocation!),
                                      },
                                      leading: Icon(
                                        icon,
                                        size: 35,
                                      ),
                                      title: Html(
                                        data: step.instructions!,
                                        style: {
                                          "body": Style(
                                            fontStyle: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .fontStyle,
                                            margin: Margins.zero,
                                          ),
                                        },
                                      ),
                                      subtitle: Html(
                                        data:
                                            'Distância: ${step.distance!.text}',
                                        style: {
                                          "body": Style(margin: Margins.zero),
                                        },
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 60.0,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _horizontalListButtons(
                      context, widget.destinationLocation),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
