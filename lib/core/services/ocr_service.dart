import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Resultado de analizar la foto de una factura/recibo con OCR local.
///
/// [name] y [amount] son mejores estimaciones (pueden venir en null si no
/// se detectó nada razonable) — siempre deben revisarse/corregirse a mano
/// antes de guardar el pago.
class ScanResult {
  final String? name;
  final double? amount;
  final String rawText;

  const ScanResult({this.name, this.amount, required this.rawText});
}

/// Envuelve Google ML Kit (Text Recognition) para extraer, de la foto de una
/// factura tomada con la cámara, un monto y un nombre de comercio probables.
/// Todo el procesamiento ocurre en el dispositivo: no se sube ninguna imagen
/// ni texto a servidores externos, y no tiene costo.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<ScanResult> scanImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer.processImage(inputImage);
    final rawText = recognizedText.text;

    final amount = _extractAmount(rawText);
    final name = _extractName(recognizedText);

    return ScanResult(name: name, amount: amount, rawText: rawText);
  }

  /// Busca el número con formato de monto más grande del texto reconocido.
  /// Las facturas suelen tener varios números (fecha, folio, subtotales);
  /// se asume que el monto total es, casi siempre, el valor más alto.
  double? _extractAmount(String text) {
    final matches = RegExp(
      r'[\$₡]?\s?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\d+(?:[.,]\d{2})?)',
    ).allMatches(text);

    double? best;
    for (final m in matches) {
      final raw = m.group(1);
      if (raw == null) continue;
      final normalized = _normalizeNumber(raw);
      final value = double.tryParse(normalized);
      if (value == null) continue;
      // Se descartan números menores a 1 (probablemente ruido de OCR,
      // como un dígito suelto de una fecha).
      if (value < 1) continue;
      if (best == null || value > best) {
        best = value;
      }
    }
    return best;
  }

  /// Normaliza un número detectado con separadores de miles/decimales que
  /// pueden venir como "," o "." según el formato regional de la factura.
  String _normalizeNumber(String raw) {
    final hasComma = raw.contains(',');
    final hasDot = raw.contains('.');
    var cleaned = raw;

    if (hasComma && hasDot) {
      if (raw.lastIndexOf(',') > raw.lastIndexOf('.')) {
        // Formato 1.234,56 -> 1234.56
        cleaned = raw.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Formato 1,234.56 -> 1234.56
        cleaned = raw.replaceAll(',', '');
      }
    } else if (hasComma && !hasDot) {
      final parts = raw.split(',');
      if (parts.last.length == 2) {
        // 25,50 -> 25.50 (coma como decimal)
        cleaned = raw.replaceAll(',', '.');
      } else {
        // 25,000 -> 25000 (coma como separador de miles)
        cleaned = raw.replaceAll(',', '');
      }
    } else if (hasDot && !hasComma) {
      final parts = raw.split('.');
      if (parts.length > 1 && parts.last.length == 3) {
        // 25.000 -> 25000 (punto como separador de miles)
        cleaned = raw.replaceAll('.', '');
      }
    }
    return cleaned;
  }

  /// Toma la primera línea de texto "razonable" (con letras, longitud
  /// mínima) como probable nombre del comercio/servicio. Es una heurística
  /// simple: en la mayoría de facturas y recibos, el nombre del negocio
  /// aparece en las primeras líneas, en la parte superior del ticket.
  String? _extractName(RecognizedText recognizedText) {
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.length >= 3 &&
            RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(text)) {
          return text;
        }
      }
    }
    return null;
  }

  void dispose() {
    _recognizer.close();
  }
}
