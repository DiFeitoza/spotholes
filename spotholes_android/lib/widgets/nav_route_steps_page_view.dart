import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_html/flutter_html.dart' hide Marker;
import 'package:google_directions_api/google_directions_api.dart';
import 'package:signals/signals_flutter.dart';

import '../controllers/route_controller.dart';
import '../utilities/custom_icons.dart';
import '../utilities/maneuver_icons.dart';

class NavRouteStepsPageView extends StatefulWidget {
  final RouteController routeController;
  final PageController pageController;
  final Signal<DirectionsRoute> route;

  const NavRouteStepsPageView({
    super.key,
    required this.routeController,
    required this.pageController,
    required this.route,
  });

  @override
  RouteStepsStatePageView createState() => RouteStepsStatePageView();
}

class RouteStepsStatePageView extends State<NavRouteStepsPageView> {
  late final _routeController = widget.routeController;
  late final _pageController = widget.pageController;
  int _currentPage = 0;

  late final _route = widget.route;
  late final _leg = computed(() => _route.value.legs![0]);
  late final _steps = _routeController.routeStepsLatLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateOnce();
    });
    _pageController.addListener(
      () {
        int newPage = _pageController.page!.round();
        if (newPage != _currentPage) {
          _currentPage = newPage;
          _routeController.clearManeuverPolyline();
          if (_currentPage == 0) {
            _routeController.updateCameraGeoCoord(_leg.value.startLocation!);
          } else if (_currentPage == _steps.value.length + 1) {
            _routeController.updateCameraGeoCoord(_leg.value.endLocation!);
          } else {
            final stepIndex = _currentPage - 1;
            _routeController.plotManeuverPolyline(stepIndex);
          }
        }
      },
    );
  }

  void _animateOnce() {
    if (_pageController.hasClients) {
      _pageController.animateTo(
        _pageController.position.pixels +
            MediaQuery.of(context).size.width / 3.5,
        duration: const Duration(milliseconds: 500),
        curve: Curves.linear,
      );
      Future.delayed(
        const Duration(milliseconds: 600),
        () {
          if (_pageController.hasClients) {
            _pageController.animateTo(
              _pageController.position.pixels -
                  MediaQuery.of(context).size.width / 3.5,
              duration: const Duration(milliseconds: 500),
              curve: Curves.linear,
            );
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _routeController.clearManeuverPolyline();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      (context) => Material(
        child: InkWell(
          child: ExpandablePageView.builder(
            controller: _pageController,
            itemCount: _steps.value.length + 2,
            itemBuilder: (context, index) {
              // Se step inicial, ponto de partida
              if (index == 0) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        'Partida: ${_leg.value.startAddress!}',
                      ),
                      leading: SizedBox(
                        height: 35,
                        width: 35,
                        child: CustomIcons.sourceIconAsset,
                      ),
                      onTap: () => {
                        // _routeController.updateCameraGeoCoord(_leg.startLocation!),
                      },
                    ),
                  ),
                );
                // Caso seja o step do destino
              } else if (index == _steps.value.length + 1) {
                return Watch(
                  (context) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(width: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        onTap: () => {
                          // _routeController.updateCameraGeoCoord(_leg.endLocation!),
                        },
                        title: Text(
                          'Destino: ${_leg.value.endAddress!}',
                        ),
                        leading: SizedBox(
                          height: 35,
                          width: 35,
                          child: CustomIcons.destinationIconAsset,
                        ),
                      ),
                    ),
                  ),
                );
                // Demais steps que contém manobras, excluindo a origem e o destino
              } else if (index >= 1 && index <= _steps.value.length) {
                final step = _steps.value[index - 1];
                final maneuver = step.maneuver ?? 'straight';
                final icon = maneuverIcons[maneuver] ?? Icons.directions;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      onTap: () => {
                        // maneuver == 'straight'
                        //     ? _routeController.newCameraLatLngBoundsFromStep(step)
                        //     : _routeController
                        //         .updateCameraGeoCoord(step.startLocation!),
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
                                .bodyLarge!
                                .fontStyle,
                            margin: Margins.zero,
                          ),
                        },
                      ),
                      subtitle: Html(
                        data: 'Distância: ${step.distance!.text}',
                        style: {
                          "body": Style(
                            fontStyle: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .fontStyle,
                            margin: Margins.zero,
                          ),
                        },
                      ),
                    ),
                  ),
                );
                // TODO Testar: se fora do range retorna vazio, em vez de exceção.
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ),
    );
  }
}
