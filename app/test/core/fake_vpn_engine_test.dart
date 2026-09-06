import 'package:flutter_test/flutter_test.dart';

import 'package:ender_trails/core/vpn/fake_vpn_engine.dart';
import 'package:ender_trails/core/vpn/vpn_engine.dart';

void main() {
  group('FakeVpnEngine', () {
    late FakeVpnEngine engine;

    setUp(() {
      engine = FakeVpnEngine(
        connectDelay: const Duration(milliseconds: 50),
      );
    });

    tearDown(() {
      engine.dispose();
    });

    test('initial state is disconnected', () {
      expect(engine.currentStatus, equals(VpnStatus.disconnected));
    });

    test('transitions through states on connect and disconnect', () async {
      final statuses = <VpnStatus>[];
      final subscription = engine.statusStream.listen(statuses.add);

      final session = VpnSession(
        configJson: '{"outbounds":[]}',
        outboundTag: 'nl-01',
      );

      final connectRes = await engine.connect(session);
      expect(connectRes.isRight(), isTrue);
      expect(engine.currentStatus, equals(VpnStatus.connected));

      final disconnectRes = await engine.disconnect();
      expect(disconnectRes.isRight(), isTrue);
      expect(engine.currentStatus, equals(VpnStatus.disconnected));

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(
        statuses,
        equals([
          VpnStatus.preparing,
          VpnStatus.connecting,
          VpnStatus.connected,
          VpnStatus.disconnecting,
          VpnStatus.disconnected,
        ]),
      );
    });
  });
}
