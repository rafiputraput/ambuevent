import 'package:flutter/material.dart';

// --- Background Gelombang Merah di Atas ---
class TopWavePainter extends StatelessWidget {
  const TopWavePainter({super.key});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      height: 120,
      child: CustomPaint(painter: WavePainter()),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paintRed = Paint()..color = const Color(0xFFEF4444)..style = PaintingStyle.fill;
    var paintWhite = Paint()..color = Colors.white..style = PaintingStyle.fill;

    // Layer Merah Paling Atas
    var path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(0, 40);
    path1.quadraticBezierTo(size.width * 0.25, 80, size.width * 0.5, 40);
    path1.quadraticBezierTo(size.width * 0.75, 0, size.width, 40);
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paintRed);

    // Garis Putih
    var path2 = Path();
    path2.moveTo(0, 55);
    path2.quadraticBezierTo(size.width * 0.25, 95, size.width * 0.5, 55);
    path2.quadraticBezierTo(size.width * 0.75, 15, size.width, 55);
    path2.lineTo(size.width, 40);
    path2.quadraticBezierTo(size.width * 0.75, 0, size.width * 0.5, 40);
    path2.quadraticBezierTo(size.width * 0.25, 80, 0, 40);
    path2.close();
    canvas.drawPath(path2, paintWhite);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Background Kota di Bawah ---
class BottomCityPainter extends StatelessWidget {
  const BottomCityPainter({super.key});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Opacity(
        opacity: 0.9,
        child: SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _building(40, 80, Colors.red.shade100),
              _building(50, 100, Colors.red.shade600),
              // Ikon Monas
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(width: 10, height: 10, color: Colors.amber), 
                  Container(width: 20, height: 80, color: Colors.red),
                  Container(width: 40, height: 10, color: Colors.red),
                  Container(width: 60, height: 30, color: Colors.red),
                ],
              ),
              _building(50, 90, Colors.red.shade200),
              _building(40, 60, Colors.red.shade100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _building(double width, double height, Color color) {
    return Container(width: width, height: height, margin: const EdgeInsets.symmetric(horizontal: 4), color: color);
  }
}

// --- Grid Peta ---
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.grey.withOpacity(0.3)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}