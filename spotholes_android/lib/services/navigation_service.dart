import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mtk;
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/utilities/point_on_route_haversine.dart';

import '../controllers/route_controller.dart';
import '../utilities/constants.dart';

class NavigationService {
  final RouteController _routeController;
  final PageController _pageController;
  final Signal<bool> _isTrackingLocation;
  final Signal<bool> _isPageViewUpdateCamera;

  NavigationService(
    this._routeController,
    this._pageController,
    this._isTrackingLocation,
    this._isPageViewUpdateCamera,
  );

  late final _routePolylineCoordinatesSignal =
      _routeController.routePolylineCoordinatesSignal;
  late final _stepsIndexes = _routeController.stepsIndexes;
  late final _routeStepsLatLng = _routeController.routeStepsLatLng;

  int _discardedPointsCounter = 0;
  int _countOutOfRoute = 0;
  int _countRecalculatedRoute = 0;
  List<mtk.LatLng> routePointsMtk = [];

  Timer? _exitRouteTimer;

  void startNavigation() {
    routePointsMtk =
        convertGmapsToMtkList(_routePolylineCoordinatesSignal.value);
  }

  void stopNavigation() {
    _discardedPointsCounter = 0;
    if (_exitRouteTimer != null) {
      _exitRouteTimer!.cancel();
    }
  }

  void updateCurrentLocationOnRouteProgress(LatLng currentLocation) {
    final projectionPoint = projectionPointOnSegment(
      currentLocation,
      _routePolylineCoordinatesSignal.value[0],
      _routePolylineCoordinatesSignal.value[1],
    );
    _routePolylineCoordinatesSignal.value[0] = projectionPoint;
    _routeController.updateRoutePolyline();
  }

  List<mtk.LatLng> convertGmapsToMtkList(List<LatLng> originalList) {
    return originalList.map((LatLng point) {
      return mtk.LatLng(point.latitude, point.longitude);
    }).toList();
  }

  LatLng locationToLatLng(location) =>
      LatLng(location.latitude!, location.longitude!);

  mtk.LatLng locationToMtkLatLng(location) =>
      mtk.LatLng(location.latitude!, location.longitude!);

  int locationIndexOnPath(
      mtk.LatLng currentPosition, List<mtk.LatLng> routePoints) {
    return mtk.PolygonUtil.locationIndexOnPath(
      currentPosition,
      routePoints,
      true,
      tolerance: routeDeviationTolerance,
    );
  }

  int verifyStep() {
    for (int i = 0; i < _stepsIndexes.length; i++) {
      if (_discardedPointsCounter <= _stepsIndexes[i]) {
        return i;
      }
    }
    return -1;
  }

  void updateRouteStatus(LatLng currentLocation) async {
    // TODO Check if there are other end-of-route situations
    /// Checks if the route is empty, for example: route completed.
    if (_routeStepsLatLng.value.isEmpty) {
      return;
    }
    routePointsMtk =
        convertGmapsToMtkList(_routePolylineCoordinatesSignal.value);
    mtk.LatLng currentLocationMtk = locationToMtkLatLng(currentLocation);
    int index = locationIndexOnPath(currentLocationMtk, routePointsMtk);
    debugPrint('----index on polyline: $index');

    /// If the current location is on the route
    if (index > 0) {
      _countOutOfRoute = 0;

      /// Set the initial position to the current location
      routePointsMtk[index] = currentLocationMtk;

      /// Remove the initial points up to the current position
      routePointsMtk.removeRange(0, index);
      _routePolylineCoordinatesSignal.value.removeRange(0, index);
      updateCurrentLocationOnRouteProgress(currentLocation);

      /// Update the discarded points counter
      _discardedPointsCounter += index;
      debugPrint('Points to discard $_discardedPointsCounter');

      /// Check the current step on the route
      int currentStepIndex = verifyStep();

      /// If the step has advanced, the pageview is updated
      if (currentStepIndex > 0 && _pageController.hasClients) {
        /// Update the polyline that represents the maneuver arrow on the map. Needs to be done before removing the steps
        if (_isTrackingLocation.value || _pageController.page == 1) {
          _routeController.plotManeuverPolyline(currentStepIndex,
              updateCamera: false);
        }

        /// Remove the steps that have passed
        _stepsIndexes.removeRange(0, currentStepIndex);
        _routeStepsLatLng.value.removeRange(0, currentStepIndex);

        final stepsLength = _routeStepsLatLng.value.length;
        final totalRemovedSteps = currentStepIndex;
        final page = _pageController.page!.toInt();

        /// Check if the pageView return movement ends at most on page 01 (step 0)
        /// if the current page is between page 01 and the penultimate page (within the steps list)
        if (totalRemovedSteps < page && page > 1 && page < stepsLength + 2) {
          _isPageViewUpdateCamera.value = false;
          _pageController.jumpToPage(page - totalRemovedSteps);
        } else {
          /// It is necessary to update to force the widget to render, however, this avoids duplication of the update because the jumpToPage invokes a method that updates the list
          _routeStepsLatLng.value = [..._routeStepsLatLng.value];
        }
        debugPrint('---pages: ${_pageController.page} $currentStepIndex');
      }

      /// If it is between position 0 and 1 of the polyline (index == 0), then the polyline is updated
    } else if (index == 0) {
      _countOutOfRoute = 0;
      updateCurrentLocationOnRouteProgress(currentLocation);

      /// If it is the last step and has less than 3 points, then discard the last step, points and complete the route
    } else if (_routeStepsLatLng.value.length == 1 &&
        _routePolylineCoordinatesSignal.value.length < 3) {
      _countOutOfRoute = 0;
      debugPrint('---Reached the end');
      _routeController.finishNavigationRoute();
    } else {
      _countOutOfRoute += 1;

      /// Recalculate the route after 5 consecutive movements off the route (considering the tolerance margin in meters)
      /// Only recalculate the route 3 times automatically, avoiding failures that generate many recalculations
      // TODO Create Snackbar to warn that the limit of 3 times has been exceeded, asking if you want to recalculate manually, if yes, 3 more automatic recalculations
      if (_countOutOfRoute > 5 && _countRecalculatedRoute <= 3) {
        _countOutOfRoute = 0;
        _routeController.recalculateRoute(currentLocation);
        _countRecalculatedRoute += 1;
      }
    }
    debugPrint(
        '----[After discard] points ${_routePolylineCoordinatesSignal.value.length} steps:${_routeStepsLatLng.value.length}');
  }
}
