import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TextDirection enum test', () {
    expect(TextDirection.rtl, isNotNull);
    expect(TextDirection.ltr, isNotNull);
  });
}
