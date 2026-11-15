import 'dart:io';
import 'dart:ui' as ui;
import 'package:adm_rider/core/config/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Helper to produce a two-wheeler icon marker for Google Maps in Fluup Rider.
///
/// Features:
/// 1. Default: Generates a vector circular vehicle badge featuring [Icons.two_wheeler_rounded]
///    with drop shadow, white border, and Brand red accent.
/// 2. Asset Image Support: Allows providing a custom asset image path (e.g. 'assets/png/two_wheeler.png')
///    either statically via [customAssetPath] or per call via [assetPath].
///    If the asset image exists in bundle, it will be loaded automatically.
/// 3. Headless / test safety: Falls back gracefully in tests or platforms without canvas support.
class TwoWheelerMarkerHelper {
  TwoWheelerMarkerHelper._();
  static final TwoWheelerMarkerHelper instance = TwoWheelerMarkerHelper._();

  /// Default asset path for the delivery vehicle marker icon.
  static String defaultAssetPath = 'assets/png/delivery_car.png';

  /// Default marker size (compact / small map icon).
  static double defaultMarkerSize = 48.0;

  /// User-configurable asset path override.
  /// Set this to your asset path (e.g. 'assets/png/delivery_car.png')
  /// if you wish to override the default asset.
  static String? customAssetPath;

  BitmapDescriptor? _cachedMarker;
  String? _cachedKey;

  /// Loads or creates the delivery vehicle marker icon.
  ///
  /// Priority:
  /// 1. [assetPath] if provided and valid
  /// 2. [customAssetPath] if set and valid
  /// 3. Default asset [defaultAssetPath] ('assets/png/delivery_car.png')
  /// 4. Fallback asset 'assets/png/two_wheeler.png' (if present in assets)
  /// 5. Programmatic vector canvas badge with [Icons.two_wheeler_rounded]
  /// 6. Standard fallback hue
  Future<BitmapDescriptor> getTwoWheelerMarker({
    String? assetPath,
    double? size,
    Color badgeColor = Brand.red,
    Color iconColor = Colors.white,
  }) async {
    final effectiveSize = size ?? defaultMarkerSize;
    final effectiveAsset = assetPath ?? customAssetPath ?? defaultAssetPath;
    final cacheKey = '$effectiveAsset-$effectiveSize-$badgeColor-$iconColor';

    if (_cachedMarker != null && _cachedKey == cacheKey) {
      return _cachedMarker!;
    }

    // Guard for headless tests
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }

    // 1. Try effective asset (delivery_car.png or custom asset)
    if (effectiveAsset.isNotEmpty) {
      try {
        final descriptor = await _loadFromAsset(effectiveAsset, effectiveSize);
        if (descriptor != null) {
          _cachedMarker = descriptor;
          _cachedKey = cacheKey;
          return descriptor;
        }
      } catch (e) {
        debugPrint('⚠️ Could not load asset "$effectiveAsset": $e. Falling back to alternative/vector icon.');
      }
    }

    // 2. Try secondary fallback asset 'assets/png/two_wheeler.png' if it exists in bundle
    try {
      final exists = await _assetExists('assets/png/two_wheeler.png');
      if (exists) {
        final descriptor = await _loadFromAsset('assets/png/two_wheeler.png', effectiveSize);
        if (descriptor != null) {
          _cachedMarker = descriptor;
          _cachedKey = cacheKey;
          return descriptor;
        }
      }
    } catch (_) {}

    // 3. Render high-resolution vector canvas badge with two-wheeler icon
    try {
      final descriptor = await _renderCanvasBadge(
        size: effectiveSize,
        badgeColor: badgeColor,
        iconColor: iconColor,
      );
      if (descriptor != null) {
        _cachedMarker = descriptor;
        _cachedKey = cacheKey;
        return descriptor;
      }
    } catch (e) {
      debugPrint('⚠️ Error generating canvas marker: $e');
    }

    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<BitmapDescriptor?> _loadFromAsset(String path, double size) async {
    try {
      final ByteData data = await rootBundle.load(path);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size.toInt(),
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error decoding asset $path: $e');
    }
    return null;
  }

  Future<BitmapDescriptor?> _renderCanvasBadge({
    required double size,
    required Color badgeColor,
    required Color iconColor,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final center = Offset(size / 2, size / 2);
    final radius = (size / 2) - 8;

    // 1. Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(0, 3), radius, shadowPaint);

    // 2. Outer white ring border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, borderPaint);

    // 3. Inner badge background
    final fillPaint = Paint()
      ..color = badgeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, fillPaint);

    // 4. Two-wheeler vehicle icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final icon = Icons.two_wheeler_rounded;
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.52,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: iconColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    }
    return null;
  }
}

