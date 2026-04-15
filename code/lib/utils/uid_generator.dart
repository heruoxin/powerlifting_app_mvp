import 'dart:math';

class UidGenerator {
  static final _random = Random.secure();

  static String generate({int length = 12}) {
    final bytes = List<int>.generate(
      length ~/ 2 + 1,
      (_) => _random.nextInt(256),
    );
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return hex.substring(0, length);
  }
}
