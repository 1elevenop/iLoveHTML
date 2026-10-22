import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Windows Data Protection API (CryptProtectData), user scope: only this
/// Windows account on this PC can decrypt. Used for keystore passwords, as
/// Android Keystore is on phones (ADR 0004).
final class _Blob extends Struct {
  @Uint32()
  external int cbData;
  external Pointer<Uint8> pbData;
}

typedef _CryptNative = Int32 Function(
    Pointer<_Blob>, Pointer<Utf16>, Pointer<_Blob>, Pointer<Void>, Pointer<Void>, Uint32, Pointer<_Blob>);
typedef _Crypt = int Function(
    Pointer<_Blob>, Pointer<Utf16>, Pointer<_Blob>, Pointer<Void>, Pointer<Void>, int, Pointer<_Blob>);

final _crypt32 = DynamicLibrary.open('crypt32.dll');
final _kernel32 = DynamicLibrary.open('kernel32.dll');
final _protect = _crypt32.lookupFunction<_CryptNative, _Crypt>('CryptProtectData');
final _unprotect = _crypt32.lookupFunction<_CryptNative, _Crypt>('CryptUnprotectData');
final _localFree = _kernel32.lookupFunction<Pointer<Void> Function(Pointer<Void>), Pointer<Void> Function(Pointer<Void>)>(
    'LocalFree');

const _uiForbidden = 0x1;

// Extra entropy so other programs calling DPAPI without it cannot decrypt.
final _entropy = utf8.encode('html2apk-keystore-password-v1');

Uint8List _run(_Crypt fn, List<int> input, String name) {
  return using((arena) {
    final inBlob = arena<_Blob>();
    final inData = arena<Uint8>(input.length);
    inData.asTypedList(input.length).setAll(0, input);
    inBlob.ref
      ..cbData = input.length
      ..pbData = inData;
    final entropy = arena<_Blob>();
    final entropyData = arena<Uint8>(_entropy.length);
    entropyData.asTypedList(_entropy.length).setAll(0, _entropy);
    entropy.ref
      ..cbData = _entropy.length
      ..pbData = entropyData;
    final out = arena<_Blob>();
    if (fn(inBlob, nullptr, entropy, nullptr, nullptr, _uiForbidden, out) == 0) {
      throw StateError('$name failed');
    }
    try {
      return Uint8List.fromList(out.ref.pbData.asTypedList(out.ref.cbData));
    } finally {
      // Clear the plaintext copy Windows allocated before freeing it.
      if (fn == _unprotect) out.ref.pbData.asTypedList(out.ref.cbData).fillRange(0, out.ref.cbData, 0);
      _localFree(out.ref.pbData.cast());
      inData.asTypedList(input.length).fillRange(0, input.length, 0);
    }
  });
}

/// Encrypts [secret] for the current Windows user; returns base64.
String protectString(String secret) => base64Encode(_run(_protect, utf8.encode(secret), 'CryptProtectData'));

/// Reverses [protectString]. Throws if the data came from another user or PC.
String unprotectString(String protected) =>
    utf8.decode(_run(_unprotect, base64Decode(protected), 'CryptUnprotectData'));
