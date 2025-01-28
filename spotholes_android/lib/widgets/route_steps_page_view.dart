import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_html/flutter_html.dart' hide Marker;
import 'package:signals/signals_flutter.dart';

import '../controllers/route_controller.dart';
import '../utilities/custom_icons.dart';
import '../utilities/maneuver_icons.dart';

class RouteStepsPageView extends StatefulWidget {
  final RouteController routeController;

  const RouteStepsPageView({
    super.key,
    required this.routeController,
  });

  @override
  RouteStepsStatePageView createState() => RouteStepsStatePageView();
}

class RouteStepsStatePageView extends State<RouteStepsPageView> {
  late final _routeController = widget.routeController;
  late final _leg = _routeController.leg;
  late final _startLocation = _routeController.startLocation;
  late final _endLocation = _routeController.endLocation;
  late final _steps = _routeController.routeStepsLatLng;
  late final _polylinesSignal = _routeController.polylinesSignal;

  late final _pageController = _routeController.pageControllerSignal.value;
  int _currentPage = 0;

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
          _cleanPolylines();
          if (_currentPage == 0) {
            _routeController.updateCameraGeoCoord(_startLocation.value!);
          } else if (_currentPage == _steps.value.length + 1) {
            _routeController.updateCameraGeoCoord(_endLocation.value!);
          } else {
            final stepIndex = _currentPage - 1;
            _routeController.plotManeuverPolyline(stepIndex);
          }
        }
      },
    );
  }

  void _cleanPolylines() {
    _polylinesSignal.value.remove('maneuverArrow');
    _polylinesSignal.value.remove('straightPath');
    _polylinesSignal.value = {..._polylinesSignal.value};
  }

  void _initialStepCamera() {
    final initialPage = _pageController.initialPage;
    if (initialPage == 0) {
      _routeController.updateCameraGeoCoord(_startLocation.value!);
    } else if (initialPage == _steps.value.length + 1) {
      _routeController.updateCameraGeoCoord(_endLocation.value!);
    } else {
      final step = _steps.value[initialPage - 1];
      final maneuver = step.maneuver ?? 'straight';
      maneuver == 'straight'
          ? _routeController.newCameraLatLngBoundsFromStep(step)
          : _routeController.updateCameraGeoCoord(step.startLocation!);
    }
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
    _cleanPolylines();
    _initialStepCamera();
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
                        _routeController
                            .updateCameraGeoCoord(_startLocation.value!),
                      },
                    ),
                  ),
                );
              } else if (index == _steps.value.length + 1) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      onTap: () => {
                        _routeController
                            .updateCameraGeoCoord(_endLocation.value!),
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
                );
              } else {
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
                        maneuver == 'straight'
                            ? _routeController
                                .newCameraLatLngBoundsFromStep(step)
                            : _routeController
                                .updateCameraGeoCoord(step.startLocation!),
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
              }
            },
          ),
        ),
      ),
    );
  }
}
