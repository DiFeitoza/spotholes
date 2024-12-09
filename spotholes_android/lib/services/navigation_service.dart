import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mtk;
import 'package:signals/signals_flutter.dart';

import '../controllers/route_controller.dart';
import '../utilities/constants.dart';

class NavigationService {
  final RouteController _routeController;
  final PageController _pageController;

  NavigationService(this._routeController, this._pageController);

  late final Signal<List<LatLng>> _routePolylineCoordinatesSignal =
      _routeController.routePolylineCoordinatesSignal;
  late final List<int> _stepsIndexes = _routeController.stepsIndexes;
  late final totalPointsOnRoute = _routePolylineCoordinatesSignal.value.length;
  // late final Signal<PageController> _pageController =
  //     _routeController.pageControllerSignal;

  int _discardedPointsCounter = 0;
  List<mtk.LatLng> routePointsMtk = [];

  Timer? _exitRouteTimer;

  // final _location = Location.instance;
  // Function? _dispose;

  // void _listenCurrentLocation() async {
  //   _location.onLocationChanged.listen(
  //     (newLoc) {
  //       _locationService.loadCurrentLocationMark(
  //         _routeController.markersSignal,
  //         _routeController.customInfoWindowControllerSignal,
  //       );
  //       if (newLoc.accuracy != null && newLoc.accuracy! < 30.0) {
  //         _updateNavigationCamera(locationToLatLng(newLoc), newLoc.heading!);
  //         _updateRouteStatus(locationToMtkLatLng(newLoc));
  //       } else {
  //         //TODO snackbar alertando que o GPS está fora. Pode ser um signal que exibe o snackbar na tela com o ícone de GPS fora
  //       }
  //     },
  //   );
  // }

  void startNavigation() {
    routePointsMtk =
        convertGmapsToMtkList(_routePolylineCoordinatesSignal.value);
    // _listenCurrentLocation();
  }

  void stopNavigation() {
    _discardedPointsCounter = 0;
    if (_exitRouteTimer != null) {
      _exitRouteTimer!.cancel();
    }
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

  void updateRouteStatus(LatLng currentLocation) {
    // TODO Criar verificação de destino alcançado, p.ex. se está a x metros do ponto final para limpar a rota
    // TODO Verificar se há outras situações de fim da rota
    // Verifica se a rota está vazia, p.ex trajeto concluído.
    if (_routeController.routeStepsLatLng.value.isEmpty) {
      return;
    }
    routePointsMtk =
        convertGmapsToMtkList(_routePolylineCoordinatesSignal.value);
    mtk.LatLng currentLocationMtk = locationToMtkLatLng(currentLocation);
    int index = locationIndexOnPath(currentLocationMtk, routePointsMtk);
    debugPrint('----index on polyline: $index');
    // Se a localização atual está na rota
    if (index > 0) {
      // Define a posição inicial para a localização atual
      routePointsMtk[index] = currentLocationMtk;
      // Remove os pontos iniciais até a posição atual
      routePointsMtk.removeRange(0, index + 1);
      _routePolylineCoordinatesSignal.value.removeRange(0, index + 1);
      // Modifica a polyline da rota
      _routeController.polylinesSignal.value['route'] = Polyline(
        polylineId: const PolylineId("route"),
        points: _routePolylineCoordinatesSignal.value,
        width: 6,
        color: primaryColor,
        geodesic: true,
        jointType: JointType.round,
      );
      // Força o update da polyline da rota
      _routeController.polylinesSignal.value = {
        ..._routeController.polylinesSignal.value
      };
      // Atualiza o contador de pontos descartados
      _discardedPointsCounter += index + 1;
      debugPrint('Pontos a descartar $_discardedPointsCounter');
      // Verifica o step atual na rota
      int currentStepIndex = verifyStep();
      // Se o step avançou, o pageview é atualizado
      if (currentStepIndex > 0 && _pageController.hasClients) {
        // Remove steps que já passaram e faz update do signal
        _stepsIndexes.removeRange(0, currentStepIndex);
        _routeController.routeStepsLatLng.value
            .removeRange(0, currentStepIndex);
        _routeController.routeStepsLatLng.value = [
          ..._routeController.routeStepsLatLng.value
        ];
        // Atualiza a polyline que representa a seta de manobra no mapa
        _routeController.plotManeuverPolyline(0, updateCamera: false);
        debugPrint('---pages: ${_pageController.page} $currentStepIndex');
        // Verifica se está na pageView correspondente ao step atual, senão atualiza
        if (_pageController.page != currentStepIndex) {
          // TODO Criar uma segunda condição, talvez um boolean para chavear entre monitorar automaticamente ou com base na ação do usuário, incluindo movimento de câmera, pageview, etc.
          _pageController.jumpToPage(currentStepIndex);
        }
      }
      // Caso esteja entre a posição 0 e 1 da polyline, então a polyline é atualizada
    } else if (index == 0) {
      _routePolylineCoordinatesSignal.value[0] = currentLocation;
      // Força o update da polyline da rota
      _routeController.polylinesSignal.value = {
        ..._routeController.polylinesSignal.value
      };
      // Caso seja o último step e tenha menos que 3 pontos, então descarta o último step, pontos e conclui a rota
    } else if (_routeController.routeStepsLatLng.value.length == 1 &&
        _routePolylineCoordinatesSignal.value.length < 3) {
      debugPrint('---Cheguei no final');
      _stepsIndexes.clear();
      _routeController.routeStepsLatLng.value.clear();
      _routePolylineCoordinatesSignal.value.clear();
      _routeController.clearManeuverPolyline();
      // Força update dos steps
      _routeController.routeStepsLatLng.value = [
        ..._routeController.routeStepsLatLng.value
      ];
    } else {
      //TODO Criar ação para quando index = -1, ou seja, fora da rota. Inclusive com a possibildade de recálculo da rota;
    }
    debugPrint(
        '----[Após descarte] points ${_routePolylineCoordinatesSignal.value.length} steps:${_routeController.routeStepsLatLng.value.length}');
  }

  void recalculateRoute(LatLng currentPosition) {
    // Função mock, substitua com a lógica real para recalcular a rota usando a API de Directions do Google Maps
    // vou precisar do contexto atualizado para fazer isso!
  }

  // dispose() {
  //   _dispose!();
  // }
}
