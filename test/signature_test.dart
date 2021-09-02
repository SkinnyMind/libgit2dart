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
      final defaultSignature =
          Signature.create(name: 'Name', email: 'email@example.com');
      expect(defaultSignature, isA<Signature>());
      expect(defaultSignature.name, 'Name');
      expect(defaultSignature.email, 'email@example.com');
      expect(
        defaultSignature.time -
            (DateTime.now().millisecondsSinceEpoch / 1000).truncate(),
        lessThan(5),
      );
      expect(defaultSignature.offset, 180);
      defaultSignature.free();
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
