import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:platform/platform.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'in_app_review_platform_interface.dart';

/// An implementation of [InAppReviewPlatform] that uses method channels.
class MethodChannelInAppReview extends InAppReviewPlatform {
  MethodChannel _channel = MethodChannel('dev.britannio.in_app_review');
  NativePlatform? _platform = NativePlatform.current;

  @visibleForTesting
  set channel(MethodChannel channel) => _channel = channel;

  @visibleForTesting
  set platform(NativePlatform platform) => _platform = platform;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    return _channel
        .invokeMethod<bool>('isAvailable')
        .then((available) => available ?? false, onError: (_) => false);
  }

  @override
  Future<void> requestReview() => _channel.invokeMethod('requestReview');

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {
    final NativePlatform? platform = _platform;
    final bool isiOS = platform?.isIOS ?? false;
    final bool isMacOS = platform?.isMacOS ?? false;
    final bool isAndroid = platform?.isAndroid ?? false;
    final bool isWindows = platform?.isWindows ?? false;

    if (isiOS || isMacOS) {
      await _channel.invokeMethod(
        'openStoreListing',
        ArgumentError.checkNotNull(appStoreId, 'appStoreId'),
      );
    } else if (isAndroid) {
      await _channel.invokeMethod('openStoreListing');
    } else if (isWindows) {
      ArgumentError.checkNotNull(microsoftStoreId, 'microsoftStoreId');
      await _launchUrl(
        'ms-windows-store://review/?ProductId=$microsoftStoreId',
      );
    } else {
      throw UnsupportedError(
        'Platform(${platform?.operatingSystem}) not supported',
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await canLaunchUrlString(url)) return;
    await launchUrlString(url, mode: LaunchMode.externalNonBrowserApplication);
  }
}
