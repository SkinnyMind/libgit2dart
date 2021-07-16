import 'package:test/test.dart';
import 'package:libgit2dart/src/oid.dart';
import 'package:libgit2dart/src/error.dart';

void main() {
  const sha = '9d81c715ff606057fa448e558c7458467a86c8c7';

  group('Oid', () {
    group('fromSHA()', () {
      test('initializes successfully', () {
        expect(Oid.fromSHA(sha), isA<Oid>());
      });

      test('throws when hex string is lesser than 40 characters', () {
        expect(() => Oid.fromSHA('9d8'), throwsA(isA<LibGit2Error>()));
      });
    });

    test('returns sha hex string', () {
      final oid = Oid.fromSHA(sha);
      final hex = oid.sha;
      expect(hex, equals(sha));
    });

    group('compare', () {
      test('< and <=', () {
        final oid1 = Oid.fromSHA(sha);
        final oid2 = Oid.fromSHA('9d81c715ff606057fa448e558c7458467a86c8c8');
        expect(oid1 < oid2, true);
        expect(oid1 <= oid2, true);
      });

      test('==', () {
        final oid1 = Oid.fromSHA(sha);
        final oid2 = Oid.fromSHA(sha);
        expect(oid1 == oid2, true);
      });

      test('> and >=', () {
        final oid1 = Oid.fromSHA(sha);
        final oid2 = Oid.fromSHA('9d81c715ff606057fa448e558c7458467a86c8c6');
        expect(oid1 > oid2, true);
        expect(oid1 >= oid2, true);
      });
    });
  });
}
