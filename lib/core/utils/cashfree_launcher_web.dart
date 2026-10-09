// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void launchCashfreeWebCheckout(String sessionId, {String mode = 'production'}) {
  try {
    js.context.callMethod('launchCashfreeCheckout', [sessionId, mode]);
  } catch (e) {
    // ignore: avoid_print
    print('Failed to launch Cashfree web SDK: $e');
  }
}
