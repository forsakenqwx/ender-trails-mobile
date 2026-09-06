import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ender_trails/app.dart';
import 'package:ender_trails/features/announcements/domain/entities/remote_banner.dart';
import 'package:ender_trails/features/announcements/presentation/providers/banner_providers.dart';

class _MockBannerNotifier extends RemoteBannerNotifier {
  @override
  Future<RemoteBanner?> build() async {
    return const RemoteBanner(
      id: 'promo_nodes_2026',
      enabled: true,
      title: 'НОВЫЕ СЕРВЕРЫ',
      text: 'Добавили локации в Стокгольме и Хельсинки! ⚡',
      actionUrl: 'https://t.me/EnderTrailsVPN_bot',
      type: 'promo',
    );
  }
}

Future<void> loadFonts() async {
  final pixFile = File('assets/fonts/PixCyrillic.ttf');
  if (pixFile.existsSync()) {
    final bytes = pixFile.readAsBytesSync();
    final fontLoader = FontLoader('PixCyrillic');
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
  }

  final iconFile = File(
      r'C:\src\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf');
  if (iconFile.existsSync()) {
    final bytes = iconFile.readAsBytesSync();
    final fontLoader = FontLoader('MaterialIcons');
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
  }

  final segoeFile = File(r'C:\Windows\Fonts\segoeui.ttf');
  if (segoeFile.existsSync()) {
    final bytes = segoeFile.readAsBytesSync();
    final fontLoader = FontLoader('Roboto');
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadFonts();
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
        .setMockMethodCallHandler((call) async => null);
    const MethodChannel('com.llfbandit.app_links/events')
        .setMockMethodCallHandler((call) async => null);
    const MethodChannel('com.llfbandit.app_links/messages')
        .setMockMethodCallHandler((call) async => null);
    const MethodChannel('dev.fluttercommunity.plus/package_info')
        .setMockMethodCallHandler((call) async => {
              'appName': 'Ender Trails',
              'packageName': 'online.endertrails.vpn',
              'version': '1.0.23',
              'buildNumber': '3010',
            });
  });

  testWidgets('Capture main screen screenshot', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            remoteBannerNotifierProvider.overrideWith(() => _MockBannerNotifier()),
          ],
          child: const EnderTrailsApp(),
        ),
      ),
    );

    // Pump frames to render atlas & 3D cube
    await tester.pump(const Duration(milliseconds: 600));

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = File(
        r'C:\Users\forsaken\.gemini\antigravity\brain\febebdc9-8816-4195-9738-2cc97b5b92cf\screen_v24_live.png',
      );
      await file.writeAsBytes(bytes);
      print('Screenshot saved: ${bytes.length} bytes');
    });

    // Open ticket dialog by tapping Профиль or ОПЫТ / ТРАФИК
    await tester.tap(find.text('ОПЫТ / ТРАФИК'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final boundaryTicket =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final imageTicket = await boundaryTicket.toImage(pixelRatio: 1.0);
      final byteDataTicket = await imageTicket.toByteData(format: ui.ImageByteFormat.png);
      final bytesTicket = byteDataTicket!.buffer.asUint8List();

      final fileTicket = File(
        r'C:\Users\forsaken\.gemini\antigravity\brain\febebdc9-8816-4195-9738-2cc97b5b92cf\screen_v24_ticket.png',
      );
      await fileTicket.writeAsBytes(bytesTicket);
      print('Ticket screenshot saved: ${bytesTicket.length} bytes');
    });

    // Close ticket dialog by tapping outside
    await tester.tapAt(const Offset(20, 20));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Tap on СЕРВЕРЫ tab in the bottom menu
    await tester.tap(find.text('СЕРВЕРЫ'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final boundary2 =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final image2 = await boundary2.toImage(pixelRatio: 1.0);
      final byteData2 = await image2.toByteData(format: ui.ImageByteFormat.png);
      final bytes2 = byteData2!.buffer.asUint8List();

      final file2 = File(
        r'C:\Users\forsaken\.gemini\antigravity\brain\febebdc9-8816-4195-9738-2cc97b5b92cf\screen_v24_servers.png',
      );
      await file2.writeAsBytes(bytes2);
      print('Servers screenshot saved: ${bytes2.length} bytes');
    });

    await tester.pump(const Duration(seconds: 3));
  }, timeout: const Timeout(Duration(seconds: 15)));
}
