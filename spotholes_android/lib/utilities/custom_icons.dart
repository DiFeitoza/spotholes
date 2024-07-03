import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/utilities/image_size_adjust.dart';

class CustomIcons {
  static BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  static BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  static BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  static BitmapDescriptor potholeIcon = BitmapDescriptor.defaultMarker;

  // TODO automatizar ajuste de tamanho de ícones com base no tamanho de tela ou componentes do google maps, em vez de fazer ajuste em hardcode gerar assets com tamanhos corretos para teste.
  static setupCustomIcons() {
    ImageSizeAdjust.getCustomIcon('assets/images/source_route.png', 110)
        .then((icon) {
      sourceIcon = icon;
    });
    ImageSizeAdjust.getCustomIcon('assets/images/end_route.png', 110)
        .then((icon) {
      destinationIcon = icon;
    });
    ImageSizeAdjust.getCustomIcon("assets/images/badge_red.png", 150)
        .then((icon) {
      currentLocationIcon = icon;
    });
    ImageSizeAdjust.getCustomIcon('assets/images/pothole_sign.png', 100)
        .then((icon) {
      potholeIcon = icon;
    });
  }
}
