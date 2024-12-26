import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/controllers/route_controller.dart';
import 'package:spotholes_android/widgets/bullet_list.dart';

import '../../main.dart';
import '../../models/spothole.dart';
import '../../utilities/app_routes.dart';
import '../../utilities/custom_icons.dart';
import '../../utilities/maneuver_icons.dart';
import '../button/custom_button.dart';

class RouteDraggableSheetController {
  Function(String)? updateData;

  void dispose() {
    updateData = null;
  }
}

class RouteDraggableSheet extends StatefulWidget {
  final RouteController routeController;

  const RouteDraggableSheet({
    super.key,
    required this.routeController,
  });

  @override
  RouteDraggableSheetState createState() => RouteDraggableSheetState();
}

class RouteDraggableSheetState extends State<RouteDraggableSheet> {
  late final _routeController = widget.routeController;
  final scrollController = ScrollController();

  final _draggableController = DraggableScrollableController();
  final _draggableExtentNotifier = signal(0.0);
  final _minDraggableChildSize = 0.28;
  final _intermediateDraggableChildSize = 0.4;
  final _maxDraggableChildSize = 1.0;
  int? _selectedIndex;

  late final _canvasColor = Theme.of(context).canvasColor;

  late final _route = _routeController.route;
  late final _leg = _routeController.leg;
  late final _steps = _routeController.routeStepsLatLng;

  late final _spotholesInRouteListSignal =
      _routeController.spotholesInRouteList;

  @override
  void initState() {
    super.initState();
    _draggableController.addListener(_updateExtent);
    if (_haveWarnings()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWarningsDialog();
      });
    }
  }

  bool _haveWarnings() =>
      _route.value.warnings?.isNotEmpty == true ? true : false;

  void _showWarningsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning),
              SizedBox(
                width: 12,
              ),
              Text(
                'Alertas na Rota',
              ),
            ],
          ),
          content: BulletList(
            items: _route.value.warnings!,
          ),
          actions: [
            TextButton(
              child: const Text(
                'OK',
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateExtent() {
    _draggableExtentNotifier.value = _draggableController.size;
  }

  void changeSizeDraggableScrollableSheet(double size) =>
      _draggableController.animateTo(
        size,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );

  @override
  void dispose() {
    _draggableController.removeListener(_updateExtent);
    _draggableController.dispose();
    _draggableExtentNotifier.dispose();
    super.dispose();
  }

  List<Widget> _horizontalListButtons() {
    return [
      CustomButton(
        label: 'Iniciar viagem',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => MyApp.navigatorKey.currentState?.pushNamed(
          AppRoutes.navigation,
          arguments: [_routeController.getCopy()],
        ),
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

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dy > 0) {
      changeSizeDraggableScrollableSheet(_minDraggableChildSize);
    } else if (details.velocity.pixelsPerSecond.dy < 0) {
      changeSizeDraggableScrollableSheet(_maxDraggableChildSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      (context) => Column(
        children: [
          Expanded(
            child: DraggableScrollableSheet(
              controller: _draggableController,
              maxChildSize: _maxDraggableChildSize,
              minChildSize: _minDraggableChildSize,
              initialChildSize: _minDraggableChildSize,
              snap: true,
              snapSizes: [_minDraggableChildSize, _maxDraggableChildSize],
              builder: (context, scrollController) => DefaultTabController(
                length: 2,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: _canvasColor,
                    border: Border.all(width: 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: GestureDetector(
                    onVerticalDragEnd: (details) => _onVerticalDragEnd(details),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CustomScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).hintColor,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                height: 4,
                                width: 40,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          SliverAppBar(
                            flexibleSpace: FlexibleSpaceBar(
                              background: GestureDetector(
                                onVerticalDragEnd: (details) =>
                                    _onVerticalDragEnd(details),
                                child: Container(
                                  color: Colors.transparent,
                                  child: const Center(),
                                ),
                              ),
                            ),
                            title: GestureDetector(
                              onVerticalDragEnd: (details) =>
                                  _onVerticalDragEnd(details),
                              child: const Text('Detalhes da Rota'),
                            ),
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
                                        _maxDraggableChildSize);
                                  } else {
                                    changeSizeDraggableScrollableSheet(
                                        _minDraggableChildSize);
                                  }
                                },
                              ),
                            ),
                            actions: [
                              if (_haveWarnings())
                                IconButton(
                                  icon: const Icon(Icons.warning),
                                  onPressed: _showWarningsDialog,
                                ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    MyApp.navigatorKey.currentState?.pop(),
                              ),
                            ],
                            bottom: TabBar(
                              tabs: [
                                Watch(
                                  (context) => Tab(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('Passos'),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(
                                            _steps.value.length < 100
                                                ? '${_steps.value.length}'
                                                : '+99',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Watch(
                                    (context) => Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('Alertas'),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(
                                            _spotholesInRouteListSignal
                                                        .value.length <
                                                    100
                                                ? '${_spotholesInRouteListSignal.value.length}'
                                                : '+99',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SliverFillRemaining(
                            child: TabBarView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                Watch(
                                  (context) => ListView.separated(
                                    controller: scrollController,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: _steps.value.length + 2,
                                    separatorBuilder: (context, index) =>
                                        const Divider(),
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return ListTile(
                                          title: Text(
                                              'Partida: ${_leg.value.startAddress!}'),
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
                                              ..updateCameraGeoCoord(
                                                  _leg.value.startLocation!)
                                              ..setupStepsPageView(0, 'route'),
                                          },
                                        );
                                      } else if (index ==
                                          _steps.value.length + 1) {
                                        return ListTile(
                                          selected: _selectedIndex ==
                                              _steps.value.length + 1,
                                          tileColor: _selectedIndex ==
                                                  _steps.value.length + 1
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
                                              ..updateCameraGeoCoord(
                                                  _leg.value.endLocation!)
                                              ..setupStepsPageView(
                                                  index, 'route'),
                                          },
                                          title: Text(
                                              'Destino: ${_leg.value.endAddress!}'),
                                          leading: SizedBox(
                                            height: 35,
                                            width: 35,
                                            child: CustomIcons
                                                .destinationIconAsset,
                                          ),
                                        );
                                      } else {
                                        final step = _steps.value[index - 1];
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
                                                        step)
                                                : _routeController
                                                    .updateCameraGeoCoord(
                                                        step.startLocation!),
                                            _routeController
                                              ..setupStepsPageView(
                                                  index, 'route'),
                                          },
                                          leading: Icon(icon, size: 35),
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
                                              "body":
                                                  Style(margin: Margins.zero),
                                            },
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Watch(
                                  (context) => _spotholesInRouteListSignal
                                          .value.isEmpty
                                      ? Center(
                                          child: SingleChildScrollView(
                                            controller: scrollController,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            child: Column(
                                              children: [
                                                Image.asset(
                                                    'assets/images/markholes_thumbs_up.png'),
                                                const SizedBox(
                                                  height: 8,
                                                ),
                                                const Text(
                                                  'Não há riscos cadastrados nesta rota!\n'
                                                  'Para uma viagem segura, mantenha atenção na pista!',
                                                  textAlign: TextAlign.center,
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          controller: scrollController,
                                          physics:
                                              const ClampingScrollPhysics(),
                                          itemCount: _spotholesInRouteListSignal
                                              .value.length,
                                          separatorBuilder: (context, index) =>
                                              const Divider(),
                                          itemBuilder: (context, index) {
                                            final spothole =
                                                _spotholesInRouteListSignal
                                                    .value[index];
                                            final deepHole =
                                                spothole.type == Type.deepHole;
                                            return ListTile(
                                              title: Text(
                                                '${spothole.type.text}\n'
                                                '${(spothole.distance! / 1000).toStringAsFixed(1)} km de distância\n'
                                                '${Spothole.getFormattedTimeFromLastUpdate(spothole.dateOfUpdate)}',
                                              ),
                                              leading: Container(
                                                width: 55,
                                                height: 55,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: deepHole
                                                          ? Colors.red
                                                          : Colors.yellow,
                                                      width: 3),
                                                ),
                                                child:
                                                    Spothole.getImageRiskByType(
                                                        spothole.type),
                                              ),
                                              selected: _selectedIndex == index,
                                              tileColor: _selectedIndex == index
                                                  ? Colors.amber
                                                  : null,
                                              selectedColor: Theme.of(context)
                                                  .listTileTheme
                                                  .selectedColor,
                                              selectedTileColor:
                                                  Theme.of(context)
                                                      .listTileTheme
                                                      .selectedTileColor,
                                              onTap: () => {
                                                setState(() {
                                                  _selectedIndex = index;
                                                }),
                                                changeSizeDraggableScrollableSheet(
                                                    _intermediateDraggableChildSize),
                                                _routeController
                                                  ..updateCameraLatLng(
                                                      spothole.position)
                                                  ..setupStepsPageView(
                                                      index, 'spothole'),
                                              },
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: SizedBox(
              height: 60.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _horizontalListButtons(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
