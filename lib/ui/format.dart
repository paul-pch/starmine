import '../domain/resources.dart';

/// Entier tronqué avec séparateur de milliers (espace fine insécable).
String fmtAmount(double value) {
  if (value.isInfinite) return '∞';
  final negative = value < 0;
  final digits = value.abs().truncate().toString();
  final buf = StringBuffer(negative ? '−' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Durée compacte : « 2 j 03 h », « 1 h 05 min », « 4 min 09 s », « 12 s ».
String fmtDuration(Duration d) {
  if (d.isNegative) d = Duration.zero;
  String two(int n) => n.toString().padLeft(2, '0');
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  if (days > 0) return '$days j ${two(hours)} h';
  if (d.inHours > 0) return '${d.inHours} h ${two(minutes)} min';
  if (d.inMinutes > 0) return '${d.inMinutes} min ${two(seconds)} s';
  return '${d.inSeconds} s';
}

String resourceName(ResourceKind kind) => switch (kind) {
  ResourceKind.metal => 'Métal',
  ResourceKind.crystal => 'Cristal',
  ResourceKind.deuterium => 'Deutérium',
};

/// « 1 200 M · 300 C · 50 D », en omettant les zéros.
String fmtCost(Resources cost) {
  final parts = [
    if (cost.metal > 0) '${fmtAmount(cost.metal)} M',
    if (cost.crystal > 0) '${fmtAmount(cost.crystal)} C',
    if (cost.deuterium > 0) '${fmtAmount(cost.deuterium)} D',
  ];
  return parts.isEmpty ? 'gratuit' : parts.join(' · ');
}
