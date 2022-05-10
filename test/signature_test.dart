import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

void main() {
  late Signature signature;
  const name = 'Some Name';
  const email = 'some@email.com';
  const time = 1234567890;
  const offset = 0;

  setUp(() {
    signature = Signature.create(
      name: name,
      email: email,
      time: time,
    );
  });

  group('Signature', () {
    test('creates with provided time and offset', () {
      expect(signature, isA<Signature>());
    });

    test('throws when trying to create with empty name and email', () {
      expect(
        () => Signature.create(name: '', email: '', time: 0),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test(
        'throws when trying to create with empty name and email and '
        'default time', () {
      expect(
        () => Signature.create(name: '', email: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('creates without provided time and offset', () {
      final sig = Signature.create(name: 'Name', email: 'email@example.com');
      expect(sig, isA<Signature>());
      expect(sig.name, 'Name');
      expect(sig.email, 'email@example.com');
      expect(
        sig.time - (DateTime.now().millisecondsSinceEpoch / 1000).truncate(),
        lessThan(5),
      );
      expect(sig.offset, isA<int>());
      expect(sig.sign, isNotEmpty);
    });

    test('returns correct values', () {
      expect(signature.name, name);
      expect(signature.email, email);
      expect(signature.time, time);
      expect(signature.offset, offset);
    });

    test('compares two objects', () {
      final otherSignature = Signature.create(
        name: name,
        email: email,
        time: time,
      );
      expect(signature, equals(otherSignature));
    });

    test('manually releases allocated memory', () {
      final signature = Signature.create(
        name: name,
        email: email,
        time: time,
      );
      expect(() => signature.free(), returnsNormally);
    });

    test('returns string representation of Signature object', () {
      expect(signature.toString(), contains('Signature{'));
    });

    test('supports value comparison', () {
      expect(
        Signature.create(name: name, email: email, time: time),
        equals(Signature.create(name: name, email: email, time: time)),
      );
    });
  });
}
