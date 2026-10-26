import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/monthyl_expense.dart';
import '../../../utils/app_colors.dart';

/// Wallet / "This Month Spend" card shown at the top of the home screen.
///
/// The artwork (brushed-metal top, curved leather pocket, stitching,
/// rivets) is `assets/wallet_card_bg.png` by default. If that asset is
/// ever missing or fails to decode, it falls back automatically to a
/// hand-painted [_WalletArtPainter] equivalent so the card never breaks —
/// pass [useImageArtwork]: false to force the painted version.
class WalletWidget extends StatelessWidget {
  const WalletWidget({
    super.key,
    this.expenseData,
    this.onTap,
    this.accountNumberSuffix = '0045',
    this.useImageArtwork = true,
  });

  /// Optional live data. When left null the card shows the same
  /// placeholder figures as the design (₹18,000 of ₹1,25,000). Pass
  /// `provider.currentExpenseData` for the card to reflect real spend.
  final MonthlyExpenseData? expenseData;

  /// Called when the card is tapped. Optional — the card just won't react
  /// to taps if you don't pass one.
  final VoidCallback? onTap;

  /// Last 4 digits shown after the masked UID / account number.
  final String accountNumberSuffix;

  /// When true (default), renders `assets/wallet_card_bg.png` for the
  /// wallet artwork, falling back to the CustomPainter version if the
  /// asset fails to load. Set to false to always use the painted version.
  final bool useImageArtwork;

  static const String _artworkAsset = 'assets/wallet_card_bg.png';

  // Width : height ratio for the card — matches wallet_card_bg.png (1206x820).
  static const double _cardAspectRatio = 1206 / 820;

  String _money(num value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final data = expenseData;
    final spendText = data != null ? _money(data.totalSpent) : '₹18,000';
    final budgetText = data != null
        ? 'of ${_money(data.totalBudget)} Budget'
        : 'of ₹1,25,000 Budget';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: _cardAspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. WALLET ARTWORK (metal card slot + leather pocket)
                if (useImageArtwork)
                  Image.asset(
                    _artworkAsset,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) =>
                        const CustomPaint(painter: _WalletArtPainter()),
                  )
                else
                  const CustomPaint(painter: _WalletArtPainter()),

                // 2. UID / ACCOUNT NUMBER
                Positioned(
                  left: width * 0.08,
                  top: height * 0.10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UID / Account No.',
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '•••• •••• •••• $accountNumberSuffix',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. WALLET TAG BADGE
                Positioned(
                  right: width * 0.065,
                  top: height * 0.10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'A1 WALLET',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. SPEND INFO (on the leather pocket)
                Positioned(
                  left: width * 0.15,
                  top: height * 0.480,
                  right: width * 0.08,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Month Spend',
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        spendText,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        budgetText,
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Paints the metal card-slot top and the curved leather-pocket bottom,
/// including the brushed-metal sheen, dashed stitching, and rivets — i.e.
/// everything that used to come from `assets/wallet_card_bg.png`.
class _WalletArtPainter extends CustomPainter {
  const _WalletArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cornerRadius = w * 0.045;

    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(cornerRadius),
    );

    canvas.save();
    canvas.clipRRect(outer);

    // ---------------------------------------------------------------
    // METAL TOP (card slot)
    // ---------------------------------------------------------------
    final metalPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF242427), Color(0xFF0A0A0B)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), metalPaint);

    // Brushed-metal diagonal sheen, upper-right.
    final streakPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.4;
    final streakSpan = h * 0.62;
    for (double x = w * 0.48; x < w + streakSpan; x += w * 0.05) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - streakSpan, streakSpan),
        streakPaint,
      );
    }

    // ---------------------------------------------------------------
    // LEATHER POCKET — wavy top edge, like a card peeking out of a slot
    // ---------------------------------------------------------------
    final edgeY = h * 0.46;
    final dipY = h * 0.545;

    final pocketPath = Path()
      ..moveTo(0, edgeY)
      ..quadraticBezierTo(w * 0.5, dipY, w, edgeY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final leatherPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1C1618), Color(0xFF0C0909)],
      ).createShader(Rect.fromLTWH(0, edgeY, w, h - edgeY));
    canvas.drawPath(pocketPath, leatherPaint);

    // Faint cross-grain leather texture, clipped to the pocket only.
    canvas.save();
    canvas.clipPath(pocketPath);
    final grainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double gx = -h; gx < w + h; gx += 7) {
      canvas.drawLine(
        Offset(gx, edgeY),
        Offset(gx + (h - edgeY), h),
        grainPaint,
      );
    }
    canvas.restore();

    // ---------------------------------------------------------------
    // STITCHING — dashed outline following the pocket shape
    // ---------------------------------------------------------------
    final inset = w * 0.045;
    final stitchTopEdgeY = edgeY + h * 0.035;
    final stitchDipY = dipY + h * 0.02;
    final stitchBottom = h - inset * 0.7;
    final r = cornerRadius * 0.5;

    final stitchPath = Path()
      ..moveTo(inset, stitchTopEdgeY)
      ..quadraticBezierTo(w * 0.5, stitchDipY, w - inset, stitchTopEdgeY)
      ..lineTo(w - inset, stitchBottom - r)
      ..quadraticBezierTo(w - inset, stitchBottom, w - inset - r, stitchBottom)
      ..lineTo(inset + r, stitchBottom)
      ..quadraticBezierTo(inset, stitchBottom, inset, stitchBottom - r)
      ..close();

    _drawDashedPath(canvas, stitchPath, Colors.white.withValues(alpha: 0.55));

    canvas.restore();

    // ---------------------------------------------------------------
    // RIVETS
    // ---------------------------------------------------------------
    final rivetY = edgeY + h * 0.035;
    _drawRivet(canvas, Offset(inset + w * 0.02, rivetY));
    _drawRivet(canvas, Offset(w - inset - w * 0.02, rivetY));
  }

  void _drawRivet(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFF3A3A3D));
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      center,
      1.6,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Color color, {
    double dashWidth = 5,
    double gapWidth = 4,
    double strokeWidth = 1.4,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashWidth < metric.length
            ? distance + dashWidth
            : metric.length;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WalletArtPainter oldDelegate) => false;
}
