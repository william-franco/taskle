import 'package:flutter_test/flutter_test.dart';
import 'package:taskle_app/src/common/validators/validators.dart';

void main() {
  test('name', () {
    expect(Validators.name(null), isNotNull);
    expect(Validators.name('  '), isNotNull);
    expect(Validators.name('ab'), isNotNull);
    expect(Validators.name('Ana'), isNull);
  });

  test('email', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('a@b'), isNotNull);
    expect(Validators.email('a b@c.com'), isNotNull);
    expect(Validators.email('a@b.com'), isNull);
  });

  test('password', () {
    expect(Validators.password(null), isNotNull);
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.password('123456'), isNull);
  });

  test('confirmPassword', () {
    expect(Validators.confirmPassword('', 'abc123'), isNotNull);
    expect(Validators.confirmPassword('abc124', 'abc123'), isNotNull);
    expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
  });

  test('taskTitle', () {
    expect(Validators.taskTitle('  '), isNotNull);
    expect(Validators.taskTitle('Tarefa'), isNull);
  });
}
