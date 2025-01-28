import 'package:signals/signals.dart';
import 'package:vibration/vibration.dart';

/// A manager class for handling vibration alerts on the device.
///
/// This class provides methods to check if the device supports vibration,
/// and to trigger different vibration patterns for proximity and imminent risk alerts.
/// It also allows cancelling any active vibrations.
class VibrationManager {
  /// Indicates whether the proximity alert is currently active.
  static bool isProximityAlertActive = false;

  /// Indicates whether the imminent risk alert is currently active.
  static bool isImminentRiskAlertActive = false;

  /// Indicates whether vibration is currently active.
  static final isVibrationActive = signal(true);

  static void toggleVibrationAlert() =>
      isVibrationActive.value = !isVibrationActive.value;

  /// Checks if the device supports vibration.
  ///
  /// Returns a [Future] that completes with `true` if the device has a vibrator,
  /// otherwise `false`.
  static Future<bool> isVibrationAvailable() async {
    return await Vibration.hasVibrator() ?? false;
  }

  /// Triggers a vibration pattern for proximity alert.
  ///
  /// The vibration pattern consists of a 200ms vibration followed by a 300ms pause,
  /// and then another 200ms vibration. This method checks if the device supports
  /// vibration and if the proximity alert is not already active before triggering
  /// the vibration.
  static Future<void> alertProximity() async {
    if (isVibrationActive.value &&
        await isVibrationAvailable() &&
        !isProximityAlertActive) {
      Vibration.vibrate(pattern: [0, 200, 300, 200]);
    }
  }

  /// Triggers a vibration pattern for imminent risk alert.
  ///
  /// The vibration pattern consists of a 500ms vibration followed by a 100ms pause,
  /// then a 200ms vibration, another 100ms pause, and a final 200ms vibration.
  /// This method checks if the device supports vibration and if the imminent risk
  /// alert is not already active before triggering the vibration.
  static Future<void> alertImminentRisk() async {
    if (isVibrationActive.value &&
        await isVibrationAvailable() &&
        !isImminentRiskAlertActive) {
      Vibration.vibrate(pattern: [0, 500, 100, 200, 100, 200]);
    }
  }

  /// Cancels any active vibration.
  ///
  /// This method checks if the device supports vibration and if either the proximity
  /// alert or the imminent risk alert is active before cancelling the vibration.
  /// It also resets the alert active flags to `false`.
  static Future<void> cancelVibration() async {
    if (await isVibrationAvailable() &&
        (isProximityAlertActive || isImminentRiskAlertActive)) {
      Vibration.cancel();
      isProximityAlertActive = false;
      isImminentRiskAlertActive = false;
    }
  }
}
