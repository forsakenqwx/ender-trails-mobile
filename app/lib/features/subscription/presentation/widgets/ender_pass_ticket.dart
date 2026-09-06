import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/utils/telegram_launcher.dart';
import '../../../../shared/design_system/theme/app_colors.dart';
import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../../shared/design_system/widgets/block_button.dart';
import '../../domain/entities/subscription_profile.dart';

/// Интерактивный билет «Ender Pass '26» с отрывным корешком.
///
/// Особенности:
/// - Чистый парящий билет с 3D-наклоном (гироскоп + касания).
/// - Внутри билета расположена кнопка «ПРОДЛИТЬ В TELEGRAM».
/// - Интерактивный отрывной корешок (Stub): свайп/оттягивание пальцем
///   анимированно отрывает нижнюю часть билета с тактильным откликом и закрывает профиль.
class EnderPassTicket extends StatefulWidget {
  const EnderPassTicket({
    super.key,
    required this.profile,
    this.userName,
    this.onTorn,
  });

  final SubscriptionProfile profile;
  final String? userName;
  final VoidCallback? onTorn;

  @override
  State<EnderPassTicket> createState() => _EnderPassTicketState();
}

class _EnderPassTicketState extends State<EnderPassTicket>
    with TickerProviderStateMixin {
  final ValueNotifier<Offset> _tiltNotifier = ValueNotifier<Offset>(Offset.zero);
  late final AnimationController _resetController;
  late Animation<double> _animX;
  late Animation<double> _animY;
  StreamSubscription<AccelerometerEvent>? _sensorSub;
  bool _isPanning = false;

  // Параметры отрывания корешка билета
  late final AnimationController _tearAnimController;
  late Animation<double> _tearDxAnim;
  late Animation<double> _tearDyAnim;
  late Animation<double> _tearAngleAnim;
  late Animation<double> _tearOpacityAnim;

  double _dragDx = 0.0;
  double _dragDy = 0.0;
  double _dragAngle = 0.0;
  double _stubOpacity = 1.0;
  bool _isTorn = false;
  bool _isTearing = false;
  double _lastHapticDx = 0.0;

  @override
  void initState() {
    super.initState();

    // Анимация возврата 3D наклона
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(() {
        _tiltNotifier.value = Offset(_animX.value, _animY.value);
      });

    // Анимация отрывания / возврата корешка
    _tearAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _initSensors();
  }

  void _initSensors() {
    // В тестовой среде сенсоры не подключаем
    if (WidgetsBinding.instance is! WidgetsFlutterBinding) {
      return;
    }

    try {
      _sensorSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          if (!mounted || _isPanning || _isTearing || _resetController.isAnimating) {
            return;
          }

          final targetTiltY = (event.x / 9.8).clamp(-1.0, 1.0) * 0.26;
          final targetTiltX = -((event.y - 6.5) / 9.8).clamp(-1.0, 1.0) * 0.22;

          final cur = _tiltNotifier.value;
          final newX = cur.dx + (targetTiltX - cur.dx) * 0.15;
          final newY = cur.dy + (targetTiltY - cur.dy) * 0.15;

          if ((newX - cur.dx).abs() < 0.002 && (newY - cur.dy).abs() < 0.002) return;

          _tiltNotifier.value = Offset(newX, newY);
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _resetController.dispose();
    _tearAnimController.dispose();
    _tiltNotifier.dispose();
    super.dispose();
  }

  // Обработчики 3D наклона верхней части билета
  void _onPanDown() {
    if (_isTearing) return;
    _isPanning = true;
    if (_resetController.isAnimating) _resetController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_isTearing) return;
    _isPanning = true;
    if (_resetController.isAnimating) _resetController.stop();

    final localPos = details.localPosition;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final dx = ((localPos.dx - centerX) / centerX).clamp(-1.0, 1.0);
    final dy = ((localPos.dy - centerY) / centerY).clamp(-1.0, 1.0);

    _tiltNotifier.value = Offset(-dy * 0.18, dx * 0.18);
  }

  void _onPanEnd() {
    if (_isTearing) return;
    final cur = _tiltNotifier.value;
    _animX = Tween<double>(begin: cur.dx, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _animY = Tween<double>(begin: cur.dy, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _resetController.forward(from: 0.0).whenComplete(() {
      if (mounted) _isPanning = false;
    });
  }

  // --- Механика отрывания корешка билета ---
  void _onStubPanStart(DragStartDetails details) {
    if (_isTorn) return;
    _isTearing = true;
    _tearAnimController.stop();
    _lastHapticDx = 0.0;
  }

  void _onStubPanUpdate(DragUpdateDetails details) {
    if (_isTorn) return;
    setState(() {
      _dragDx += details.delta.dx;
      _dragDy = (_dragDy + details.delta.dy * 0.35).clamp(0.0, 70.0) + (_dragDx.abs() * 0.06);
      _dragAngle = (_dragDx / 320.0).clamp(-0.40, 0.40);
    });

    // Тактильный эффект треска рвущейся перфорации
    if ((_dragDx.abs() - _lastHapticDx).abs() > 20.0) {
      HapticFeedback.selectionClick();
      _lastHapticDx = _dragDx.abs();
    }
  }

  void _onStubPanEnd(DragEndDetails details) {
    if (_isTorn) return;
    final v = details.primaryVelocity ?? 0.0;
    final shouldTear = _dragDx.abs() > 65.0 || _dragDy > 40.0 || v.abs() > 380.0;

    if (shouldTear) {
      _executeTearOff(flyRight: _dragDx >= 0);
    } else {
      _resetStubPosition();
    }
  }

  void _onStubPanCancel() {
    if (!_isTorn) _resetStubPosition();
  }

  void _resetStubPosition() {
    _isTearing = false;
    final startDx = _dragDx;
    final startDy = _dragDy;
    final startAngle = _dragAngle;

    _tearDxAnim = Tween<double>(begin: startDx, end: 0.0).animate(
      CurvedAnimation(parent: _tearAnimController, curve: Curves.easeOutBack),
    );
    _tearDyAnim = Tween<double>(begin: startDy, end: 0.0).animate(
      CurvedAnimation(parent: _tearAnimController, curve: Curves.easeOutBack),
    );
    _tearAngleAnim = Tween<double>(begin: startAngle, end: 0.0).animate(
      CurvedAnimation(parent: _tearAnimController, curve: Curves.easeOutBack),
    );
    _tearOpacityAnim = ConstantTween<double>(1.0).animate(_tearAnimController);

    _tearAnimController.duration = const Duration(milliseconds: 260);
    _tearAnimController.addListener(_onTearAnimTick);
    _tearAnimController.forward(from: 0.0).whenComplete(() {
      _tearAnimController.removeListener(_onTearAnimTick);
    });
  }

  void _onTearAnimTick() {
    setState(() {
      _dragDx = _tearDxAnim.value;
      _dragDy = _tearDyAnim.value;
      _dragAngle = _tearAngleAnim.value;
      _stubOpacity = _tearOpacityAnim.value;
    });
  }

  void _executeTearOff({required bool flyRight}) {
    setState(() {
      _isTorn = true;
      _isTearing = false;
    });

    HapticFeedback.heavyImpact();

    final targetDx = flyRight ? 450.0 : -450.0;
    final targetDy = _dragDy + 220.0;
    final targetAngle = flyRight ? 0.70 : -0.70;

    _tearDxAnim = Tween<double>(begin: _dragDx, end: targetDx).animate(
      CurvedAnimation(parent: _tearAnimController, curve: Curves.easeInQuad),
    );
    _tearDyAnim = Tween<double>(begin: _dragDy, end: targetDy).animate(
      CurvedAnimation(parent: _tearAnimController, curve: Curves.easeInQuad),
    );
    _tearAngleAnim = Tween<double>(begin: _dragAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _tearAnimController, curve: Curves.easeInQuad),
    );
    _tearOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _tearAnimController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _tearAnimController.duration = const Duration(milliseconds: 320);
    _tearAnimController.addListener(_onTearAnimTick);
    _tearAnimController.forward(from: 0.0).whenComplete(() {
      _tearAnimController.removeListener(_onTearAnimTick);
      widget.onTorn?.call();
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 МБ';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.profile.userInfo;
    final daysRemaining = info.daysRemaining;
    final isUnlimited = info.isUnlimited;
    final isExpired = info.isExpired;

    final daysText = isExpired
        ? '0'
        : isUnlimited
            ? '∞'
            : (daysRemaining > 999 ? '365+' : '$daysRemaining');

    const topBodyHeight = 330.0;
    const stubHeight = 92.0;
    const notchRadius = 14.0;
    const cornerRadius = 20.0;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ticketWidth = math.min(constraints.maxWidth, 335.0);
          final size = Size(ticketWidth, topBodyHeight + stubHeight);

          // 1. Верхняя часть билета (Main Body)
          final topBodyCard = ClipPath(
            clipper: const TopTicketClipper(
              notchRadius: notchRadius,
              cornerRadius: cornerRadius,
            ),
            child: CustomPaint(
              foregroundPainter: const TopTicketBorderPainter(
                notchRadius: notchRadius,
                cornerRadius: cornerRadius,
              ),
              child: Container(
                width: ticketWidth,
                height: topBodyHeight,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF161622),
                      Color(0xFF11111A),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    // Кибер-сетка
                    const Positioned.fill(
                      child: CustomPaint(
                        painter: CyberGridPainter(),
                      ),
                    ),

                    // Контент верхней части
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Шапка: Логотип + Бейдж VIP PASS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.mcEnder.withValues(alpha: 0.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.mcEnder.withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.shield_rounded,
                                      size: 14,
                                      color: AppColors.mcEnder,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ENDER TRAILS',
                                    style: AppTypography.label(Colors.white).copyWith(
                                      letterSpacing: 1.0,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0x188B5CF6),
                                  border: Border.all(
                                    color: AppColors.mcEnder,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.mcEnder.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'VIP PASS',
                                  style: AppTypography.caption(AppColors.mcEnder).copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Титул: ENDER PASS '26
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Colors.white,
                                Color(0xFFDDD6FE),
                                Color(0xFFA78BFA),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              'ENDER PASS \'26',
                              style: AppTypography.headline(Colors.white).copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Private Gateway Network • Global Access',
                            style: AppTypography.caption(AppColors.mcTextDim).copyWith(
                              fontFamily: null,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2x2 матрица параметров билета
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  label: 'ПОЛЬЗОВАТЕЛЬ',
                                  value: (widget.userName != null && widget.userName!.isNotEmpty)
                                      ? widget.userName!
                                      : 'Agent #Ender',
                                  valueColor: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: _buildDetailItem(
                                  label: 'СРОК',
                                  value: isExpired
                                      ? 'ИСТЕКЛА'
                                      : info.expireDate == null
                                          ? 'БЕССРОЧНО'
                                          : '${info.expireDate!.day}.${info.expireDate!.month}.${info.expireDate!.year}',
                                  valueColor: isExpired ? AppColors.mcRedstone : AppColors.mcGrass,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  label: 'ТРАФИК',
                                  value: isUnlimited
                                      ? '${_formatBytes(info.usedBytes)} / ∞'
                                      : '${_formatBytes(info.usedBytes)} / ${_formatBytes(info.totalBytes)}',
                                  valueColor: AppColors.mcDiamond,
                                ),
                              ),
                              Expanded(
                                child: _buildDetailItem(
                                  label: 'ПРОТОКОЛ',
                                  value: 'VLESS Reality',
                                  valueColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Единственная кнопка на билете: «ПРОДЛИТЬ В TELEGRAM»
                          BlockButton(
                            label: 'ПРОДЛИТЬ В TELEGRAM',
                            icon: const Icon(Icons.send_rounded, size: 16),
                            height: 42,
                            variant: BlockButtonVariant.grass,
                            onTap: () {
                              TelegramLauncher.openSubscription();
                            },
                          ),
                        ],
                      ),
                    ),

                    // Зубчики рвущейся бумаги при начале отрыва
                    if (_dragDx.abs() > 2)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: CustomPaint(
                          painter: TornEdgePainter(
                            isTop: true,
                            notchRadius: notchRadius,
                            tearProgress: (_dragDx.abs() / 40.0).clamp(0.0, 1.0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );

          // 2. Нижний отрывной корешок билета (Stub)
          final stubCard = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _onStubPanStart,
            onPanUpdate: _onStubPanUpdate,
            onPanEnd: _onStubPanEnd,
            onPanCancel: _onStubPanCancel,
            child: ClipPath(
              clipper: const StubTicketClipper(
                notchRadius: notchRadius,
                cornerRadius: cornerRadius,
              ),
              child: CustomPaint(
                foregroundPainter: const StubTicketBorderPainter(
                  notchRadius: notchRadius,
                  cornerRadius: cornerRadius,
                ),
                child: Container(
                  width: ticketWidth,
                  height: stubHeight,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D0D14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Штрихкод и серийник
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CustomPaint(
                                size: Size(115, 30),
                                painter: BarcodePainter(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ET-2026-${widget.profile.hashCode.abs().toString().padLeft(6, '0').substring(0, 6)}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 10,
                                  letterSpacing: 2.0,
                                  color: AppColors.mcTextDim,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          // Счётчик дней
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ОСТАЛОСЬ',
                                style: AppTypography.caption(AppColors.mcTextDim).copyWith(
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                daysText,
                                style: TextStyle(
                                  fontFamily: 'PixCyrillic',
                                  fontSize: 32,
                                  height: 1.0,
                                  fontWeight: FontWeight.w900,
                                  color: isExpired
                                      ? AppColors.mcRedstone
                                      : const Color(0xFFA855F7),
                                  shadows: [
                                    BoxShadow(
                                      color: (isExpired ? AppColors.mcRedstone : AppColors.mcEnder)
                                          .withValues(alpha: 0.8),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Зубчики рвущейся бумаги на верхнем крае корешка
                      if (_dragDx.abs() > 2)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: CustomPaint(
                            painter: TornEdgePainter(
                              isTop: false,
                              notchRadius: notchRadius,
                              tearProgress: (_dragDx.abs() / 40.0).clamp(0.0, 1.0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );

          return GestureDetector(
            onPanDown: (_) => _onPanDown(),
            onPanUpdate: (details) => _onPanUpdate(details, size),
            onPanEnd: (_) => _onPanEnd(),
            onPanCancel: () => _onPanEnd(),
            child: ValueListenableBuilder<Offset>(
              valueListenable: _tiltNotifier,
              builder: (context, tilt, _) {
                final tiltX = tilt.dx;
                final tiltY = tilt.dy;

                final matrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(tiltX)
                  ..rotateY(tiltY);

                return Transform(
                  transform: matrix,
                  alignment: FractionalOffset.center,
                  child: Container(
                    width: ticketWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cornerRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: AppColors.mcEnder.withValues(alpha: 0.22),
                          blurRadius: 26,
                          spreadRadius: -4,
                          offset: Offset(-tiltY * 26, -tiltX * 26),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Верхняя основная часть
                        topBodyCard,

                        // 2. Отрывной корешок
                        Transform(
                          transform: Matrix4.identity()
                            ..translate(_dragDx, _dragDy)
                            ..rotateZ(_dragAngle),
                          alignment: _dragDx >= 0 ? Alignment.topLeft : Alignment.topRight,
                          child: Opacity(
                            opacity: _stubOpacity.clamp(0.0, 1.0),
                            child: stubCard,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption(AppColors.mcTextDim).copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.label(valueColor).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Фигурный обрезчик верхней основной части билета.
class TopTicketClipper extends CustomClipper<Path> {
  const TopTicketClipper({
    required this.notchRadius,
    required this.cornerRadius,
  });

  final double notchRadius;
  final double cornerRadius;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final nr = notchRadius;

    // Верхний левый угол
    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);

    // Верхняя грань
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);

    // Правая грань до выреза
    path.lineTo(w, h - nr);
    // Верхняя четверть правого выреза
    path.arcToPoint(
      Offset(w - nr, h),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    // Нижняя грань (линия перфорации)
    path.lineTo(nr, h);

    // Верхняя четверть левого выреза
    path.arcToPoint(
      Offset(0, h - nr),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    // Левая грань до верхнего угла
    path.lineTo(0, r);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant TopTicketClipper oldClipper) =>
      oldClipper.notchRadius != notchRadius ||
      oldClipper.cornerRadius != cornerRadius;
}

/// Фигурный обрезчик нижнего отрывного корешка билета.
class StubTicketClipper extends CustomClipper<Path> {
  const StubTicketClipper({
    required this.notchRadius,
    required this.cornerRadius,
  });

  final double notchRadius;
  final double cornerRadius;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final nr = notchRadius;

    // Начинаем от левого выреза (нижняя четверть дуги)
    path.moveTo(0, nr);
    path.arcToPoint(
      Offset(nr, 0),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    // Верхняя грань (линия перфорации)
    path.lineTo(w - nr, 0);

    // Нижняя четверть правого выреза
    path.arcToPoint(
      Offset(w, nr),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    // Правая грань
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);

    // Нижняя грань
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);

    // Левая грань
    path.lineTo(0, nr);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant StubTicketClipper oldClipper) =>
      oldClipper.notchRadius != notchRadius ||
      oldClipper.cornerRadius != cornerRadius;
}

/// Контур верхней части билета с пунктиром перфорации снизу.
class TopTicketBorderPainter extends CustomPainter {
  const TopTicketBorderPainter({
    required this.notchRadius,
    required this.cornerRadius,
  });

  final double notchRadius;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = TopTicketClipper(
      notchRadius: notchRadius,
      cornerRadius: cornerRadius,
    );
    final path = clipper.getClip(size);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x28FFFFFF)
      ..strokeWidth = 1.2;

    canvas.drawPath(path, borderPaint);

    // Пунктирная линия перфорации снизу
    final dashPaint = Paint()
      ..color = const Color(0x35FFFFFF)
      ..strokeWidth = 1.5;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final startX = notchRadius + 3.0;
    final endX = size.width - notchRadius - 3.0;

    double x = startX;
    while (x < endX) {
      final currentDash = math.min(dashWidth, endX - x);
      canvas.drawLine(Offset(x, size.height), Offset(x + currentDash, size.height), dashPaint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TopTicketBorderPainter oldDelegate) =>
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.cornerRadius != cornerRadius;
}

/// Контур нижнего корешка с пунктиром перфорации сверху.
class StubTicketBorderPainter extends CustomPainter {
  const StubTicketBorderPainter({
    required this.notchRadius,
    required this.cornerRadius,
  });

  final double notchRadius;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = StubTicketClipper(
      notchRadius: notchRadius,
      cornerRadius: cornerRadius,
    );
    final path = clipper.getClip(size);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x28FFFFFF)
      ..strokeWidth = 1.2;

    canvas.drawPath(path, borderPaint);

    // Пунктирная линия перфорации сверху
    final dashPaint = Paint()
      ..color = const Color(0x35FFFFFF)
      ..strokeWidth = 1.5;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final startX = notchRadius + 3.0;
    final endX = size.width - notchRadius - 3.0;

    double x = startX;
    while (x < endX) {
      final currentDash = math.min(dashWidth, endX - x);
      canvas.drawLine(Offset(x, 0), Offset(x + currentDash, 0), dashPaint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant StubTicketBorderPainter oldDelegate) =>
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.cornerRadius != cornerRadius;
}

/// Зигзагообразные волокна рвущейся бумаги перфорации
class TornEdgePainter extends CustomPainter {
  const TornEdgePainter({
    required this.isTop,
    required this.notchRadius,
    required this.tearProgress,
  });

  final bool isTop;
  final double notchRadius;
  final double tearProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (tearProgress <= 0.01) return;

    final paint = Paint()
      ..color = const Color(0x608B5CF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final y = isTop ? size.height : 0.0;
    final startX = notchRadius + 4.0;
    final endX = size.width - notchRadius - 4.0;

    final path = Path()..moveTo(startX, y);

    const step = 4.0;
    int i = 0;
    for (double x = startX; x <= endX; x += step) {
      final tooth = (i % 2 == 0 ? 1.8 : -1.8) * tearProgress.clamp(0.0, 1.0);
      path.lineTo(x, y + (isTop ? tooth : -tooth));
      i++;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TornEdgePainter oldDelegate) =>
      oldDelegate.tearProgress != tearProgress;
}

/// Неоновая сетка Энда (Cyber Grid).
class CyberGridPainter extends CustomPainter {
  const CyberGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x188B5CF6)
      ..strokeWidth = 1.0;

    const gridSize = 24.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Векторный генератор штрихкода.
class BarcodePainter extends CustomPainter {
  const BarcodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);

    const pattern = [
      2.0, 2.0, 4.0, 1.5, 1.0, 3.0, 2.0, 1.5, 5.0, 2.0,
      1.5, 3.0, 2.0, 2.0, 4.0, 1.0, 3.0, 2.0, 1.5, 4.0,
      2.0, 1.5, 3.0, 2.0, 5.0, 1.5, 2.0, 3.0, 1.0, 4.0,
    ];

    double currentX = 0;
    bool isBar = true;

    for (final width in pattern) {
      if (currentX + width > size.width) break;
      if (isBar) {
        canvas.drawRect(
          Rect.fromLTWH(currentX, 0, width, size.height),
          paint,
        );
      }
      currentX += width;
      isBar = !isBar;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Классический цельный TicketClipper для обратной совместимости.
class TicketClipper extends CustomClipper<Path> {
  const TicketClipper({
    required this.notchRadius,
    required this.cornerRadius,
    required this.notchBottomOffset,
  });

  final double notchRadius;
  final double cornerRadius;
  final double notchBottomOffset;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final notchY = h - notchBottomOffset;
    final r = cornerRadius;
    final nr = notchRadius;

    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, notchY - nr);
    path.arcToPoint(Offset(w, notchY + nr), radius: Radius.circular(nr), clockwise: false);
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);
    path.lineTo(0, notchY + nr);
    path.arcToPoint(Offset(0, notchY - nr), radius: Radius.circular(nr), clockwise: false);
    path.lineTo(0, r);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant TicketClipper oldClipper) =>
      oldClipper.notchRadius != notchRadius ||
      oldClipper.cornerRadius != cornerRadius ||
      oldClipper.notchBottomOffset != notchBottomOffset;
}

/// Классический TicketBorderPainter для обратной совместимости.
class TicketBorderPainter extends CustomPainter {
  const TicketBorderPainter({
    required this.notchRadius,
    required this.cornerRadius,
    required this.notchBottomOffset,
  });

  final double notchRadius;
  final double cornerRadius;
  final double notchBottomOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = TicketClipper(
      notchRadius: notchRadius,
      cornerRadius: cornerRadius,
      notchBottomOffset: notchBottomOffset,
    );
    final path = clipper.getClip(size);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x28FFFFFF)
      ..strokeWidth = 1.2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TicketBorderPainter oldDelegate) =>
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.notchBottomOffset != notchBottomOffset;
}
