import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_html/flutter_html.dart' hide Marker;
import 'package:signals/signals_flutter.dart';

import '../controllers/route_controller.dart';
import '../utilities/custom_icons.dart';
import '../utilities/maneuver_icons.dart';

class NavRouteStepsPageView extends StatefulWidget {
  final RouteController routeController;
  final PageController pageController;
  final Signal<bool> isPageViewUpdateCamera;

  const NavRouteStepsPageView({
    super.key,
    required this.routeController,
    required this.pageController,
    required this.isPageViewUpdateCamera,
  });

  @override
  NavRouteStepsStatePageView createState() => NavRouteStepsStatePageView();
}

class NavRouteStepsStatePageView extends State<NavRouteStepsPageView> {
  late final _routeController = widget.routeController;
  late final _pageController = widget.pageController;
  late final _isPageViewUpdateCamera = widget.isPageViewUpdateCamera;
  int _currentPage = 0;
  bool _ignoreInitialPageChange = true;

  late final _leg = _routeController.leg;
  late final _steps = _routeController.routeStepsLatLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateOnce();
    });
  }

  void pageControllerAddListener() {
    _pageController.addListener(
      () {
        if (_ignoreInitialPageChange) {
          _ignoreInitialPageChange = false;
        } else {
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
              if (_isPageViewUpdateCamera.value) {
                _routeController.plotManeuverPolyline(
                  stepIndex,
                  updateCamera: true,
                );
              } else {
                /// If it is an execution that does not need to update the camera, return to the default state
                _isPageViewUpdateCamera.value = true;
                _routeController.plotManeuverPolyline(
                  stepIndex,
                  updateCamera: false,
                );
              }
            }
          }
        }
      },
    );
  }

  void _animateOnce() async {
    if (_pageController.hasClients) {
      await _pageController.animateTo(
        _pageController.position.pixels +
            MediaQuery.of(context).size.width / 3.5,
        duration: const Duration(milliseconds: 500),
        curve: Curves.linear,
      );
      await Future.delayed(
        const Duration(milliseconds: 600),
        () async {
          if (_pageController.hasClients) {
            await _pageController.animateTo(
              _pageController.position.pixels -
                  MediaQuery.of(context).size.width / 3.5,
              duration: const Duration(milliseconds: 500),
              curve: Curves.linear,
            );
          }
        },
      );
    }
    await Future.delayed(const Duration(milliseconds: 1100));
    // TODO Find the correct strategy so that the listener only starts being triggered after the end of the animation actions, without the need to introduce the delay!
    pageControllerAddListener();
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
              /// If initial step, starting point
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
                            .updateCameraGeoCoord(_leg.value.startLocation!),
                      },
                    ),
                  ),
                );

                /// If it is the destination step
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
                          _routeController
                              .updateCameraGeoCoord(_leg.value.endLocation!),
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

                /// Other steps that contain maneuvers, excluding origin and destination
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
                // TODO Test: if out of range returns empty, instead of exception.
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
