import 'package:flutter_test/flutter_test.dart';
import 'package:powerlifting_app/utils/uid_generator.dart';

void main() {
  group('UidGenerator', () {
    test('should generate 12-character UIDs', () {
      final uid = UidGenerator.generate();
      expect(uid.length, 12);
    });

    test('should generate unique UIDs', () {
      final uids = <String>{};
      for (var i = 0; i < 1000; i++) {
        uids.add(UidGenerator.generate());
      }
      // All 1000 should be unique
      expect(uids.length, 1000);
    });

    test('should generate alphanumeric UIDs', () {
      final uid = UidGenerator.generate();
      final isAlphanumeric =
          RegExp(r'^[a-zA-Z0-9]+$').hasMatch(uid);
      expect(isAlphanumeric, true);
    });
  });
}
