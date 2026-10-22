import 'package:html2apk_core/html2apk_core.dart';

/// A release key kept by the app. The keystore and its encrypted password
/// stay with the platform's key manager; the UI only sees certificate details.
class SigningKey {
  const SigningKey({
    required this.id,
    required this.alias,
    required this.subject,
    required this.sha256,
    required this.sha1,
    required this.notAfter,
    required this.createdAt,
    required this.origin,
  });

  SigningKey.fromMap(Map<Object?, Object?> m)
      : id = m['id']! as String,
        alias = m['alias']! as String,
        subject = m['subject']! as String,
        sha256 = m['sha256']! as String,
        sha1 = m['sha1']! as String,
        notAfter = DateTime.fromMillisecondsSinceEpoch(m['notAfter']! as int),
        createdAt = DateTime.fromMillisecondsSinceEpoch(m['createdAt']! as int),
        origin = m['origin']! as String;

  final String id;
  final String alias;
  final String subject;
  final String sha256;
  final String sha1;
  final DateTime notAfter;
  final DateTime createdAt;

  /// `created` or `imported`.
  final String origin;

  Map<String, Object?> toMap() => {
        'id': id,
        'alias': alias,
        'subject': subject,
        'sha256': sha256,
        'sha1': sha1,
        'notAfter': notAfter.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'origin': origin,
      };

  /// Short form for lists, e.g. `AB:CD:EF…12:34`.
  String get shortSha256 => '${sha256.substring(0, 8)}…${sha256.substring(sha256.length - 5)}';
}

/// Signs a release with a key from [KeyManager.listKeys].
class DeviceKeySigning implements ReleaseSigning {
  const DeviceKeySigning(this.key);

  final SigningKey key;
}

/// Release keys the app keeps for the user: on Android in the Kotlin engine
/// (passwords under Android Keystore), on Windows under DPAPI.
/// Methods throw [KeyManagerException] (or PlatformException on Android)
/// with a readable message.
abstract interface class KeyManager {
  Future<List<SigningKey>> listKeys();

  Future<SigningKey> createKey({
    required String alias,
    required String commonName,
    String? organization,
    String? country,
    required String password,
  });

  /// Key aliases inside a picked keystore file (checks the store password).
  Future<List<String>> inspectKeystore(String path, String storePassword);

  Future<SigningKey> importKey({
    required String path,
    required String storePassword,
    required String alias,
    required String keyPassword,
  });

  /// Saves the keystore where the user chooses. Returns null if they cancelled.
  Future<String?> exportKey(String id);

  Future<void> deleteKey(String id);
}

class KeyManagerException implements Exception {
  const KeyManagerException(this.message);

  final String message;

  @override
  String toString() => message;
}
