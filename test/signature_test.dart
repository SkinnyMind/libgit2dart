import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';

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
      offset: offset,
    );
  });

  tearDown(() {
    signature.free();
  });
  group('Signature', () {
    test('successfully creates with provided time and offset', () {
      expect(signature, isA<Signature>());
    });

    test('successfully creates without provided time and offset', () {
      final sig = Signature.create(name: 'Name', email: 'email@example.com');
      expect(sig, isA<Signature>());
      expect(sig.name, 'Name');
      expect(sig.email, 'email@example.com');
      expect(
        sig.time - (DateTime.now().millisecondsSinceEpoch / 1000).truncate(),
        lessThan(5),
      );
      expect(sig.offset, 180);
      sig.free();
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
        offset: offset,
      );
      expect(signature == otherSignature, true);

      otherSignature.free();
    });
  });
}
