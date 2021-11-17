
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HintMatrix {
  List<int> storage;

  HintMatrix([List<int>? storage]) : storage = storage == null ? List.filled(9, 0) : storage {
    if (this.storage.length < 9) {
      this.storage.addAll(List<int>.filled(9 - this.storage.length, 0));
    }
  }

  @override
  int get hashCode {
    int hash = 0;
    for (var i in storage) {
      hash = (hash << 1) | i;
    }
    return hash | 0x77800f;
  }

  @override
  bool operator ==(Object other) {
    if (other is HintMatrix) {
      for (int i = 0, t = storage.length; i < t; ++i) {
        if (other.storage[i] != storage[i]) return false;
      }
      return true;
    }
    return false;
  }

  int findValue(Size size, Offset point) {
    int x = ((point.dx / size.width) * 3).toInt();
    int y = ((point.dy / size.height) * 3).toInt();
    return storage[x + y * 3];
  }
}

class PictureHintPainter extends CustomPainter {

  final HintMatrix matrix;
  late Paint prevPaint;
  late Paint menuPaint;
  late Paint nextPaint;
  late TextPainter textPainter;
  late TextStyle textStyle;
  String prevText;
  String menuText;
  String nextText;

  PictureHintPainter({
    required this.matrix,
    this.prevText = "Prev",
    this.menuText = "Menu",
    this.nextText = "Next",
  }) {
    prevPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green.withOpacity(0.4);
    menuPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue.withOpacity(0.4);
    nextPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red.withOpacity(0.4);
    textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: [
        Shadow(
          color: Colors.black,
          blurRadius: 4,
        ),
      ]
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    List<Offset> prevBlocks = [];
    List<Offset> menuBlocks = [];
    List<Offset> nextBlocks = [];
    double blockWidth = size.width / 3, blockHeight = size.height / 3;
    for (int y = 0; y < 3; ++y) {
      for (int x = 0; x < 3; ++x) {
        Paint paint;
        int i = matrix.storage[x + y * 3];
        Rect rect = Rect.fromLTWH(
            blockWidth * x,
            blockHeight * y,
            blockWidth,
            blockHeight);
        if (i > 0) {
          paint = nextPaint;
          nextBlocks.add(rect.center);
        } else if ( i < 0) {
          paint = prevPaint;
          prevBlocks.add(rect.center);
        } else {
          paint = menuPaint;
          menuBlocks.add(rect.center);
        }
        canvas.drawRect(rect, paint);
      }
    }
    if (prevBlocks.isNotEmpty) {
      var center = sum(prevBlocks) / prevBlocks.length.toDouble();
      textPainter.text = TextSpan(
        text: prevText,
        style: textStyle
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: double.maxFinite,
      );
      textPainter.paint(canvas, center - Offset(textPainter.size.width, textPainter.size.height) / 2);
    }
    if (menuBlocks.isNotEmpty) {
      var center = sum(menuBlocks) / menuBlocks.length.toDouble();
      textPainter.text = TextSpan(
          text: menuText,
          style: textStyle
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: double.maxFinite,
      );
      textPainter.paint(canvas, center - Offset(textPainter.size.width, textPainter.size.height) / 2);
    }
    if (nextBlocks.isNotEmpty) {
      var center = sum(nextBlocks) / nextBlocks.length.toDouble();
      textPainter.text = TextSpan(
          text: nextText,
          style: textStyle
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: double.maxFinite,
      );
      textPainter.paint(canvas, center - Offset(textPainter.size.width, textPainter.size.height) / 2);
    }
  }

  Offset sum(List<Offset> points) {
    Offset ret = Offset.zero;
    for (var point in points) {
      ret += point;
    }
    return ret;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PictureHintPainter) {
      return matrix != oldDelegate.matrix;
    }
    return true;
  }

}