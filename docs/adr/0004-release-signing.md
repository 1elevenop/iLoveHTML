# ADR 0004: Release signing with exportable keystores

Status: accepted (2026-10-21)

## Decision

Release keys are ordinary, exportable keystores protected by the user's
password, so the same key can sign on the phone and on Windows and can be
backed up. (The alternative, a non-exportable Android Keystore key, would
make every app un-updatable once the phone is lost.)

- **Format.** HTML2APK writes **PKCS12** files and saves backups with a
  `.jks` name. Android has no JKS provider; PKCS12 is what `keytool` and
  Android Studio produce by default since JDK 9, and Gradle, `keytool` and
  Google Play accept it. Legacy **JKS** files (magic `FEEDFEED`) are
  imported through our own reader (`JksReader`: Sun's SHA-1 key protector
  and integrity digest) and converted to PKCS12. JCEKS is rejected with a
  `keytool -importkeystore` hint.
- **Key generation (phone).** RSA 2048, SHA256withRSA, self-signed X.509 v3
  with a subject key identifier, valid 30 years (Play requires validity past
  2033). Android has no public certificate builder, so the certificate is
  DER-encoded by `Der.kt` and checked by parsing it back with
  `CertificateFactory` and verifying its signature.
- **Storage (phone).** `files/signing/<id>.p12` (the keystore exactly as
  exported) and `keys.json` (certificate details plus the password encrypted
  with AES-256-GCM under a non-exportable Android Keystore key). App-private
  files, `allowBackup="false"`. Passwords are never written in plain text or
  logged; char arrays are zeroed after use.
- **Projects.** `project.json` stores only `signing.releaseCertSha256`, set by
  the first successful release. Later releases with another key need
  explicit confirmation. A release whose version code is not higher than the
  last release is refused.
- **Windows.** `GradleProjectBuildEngine` passes the keystore path, alias
  and passwords through environment variables read by
  `android_template/app/build.gradle.kts`, never command-line arguments.
  The CLI reads passwords from `HTML2APK_KEYSTORE_PASSWORD` /
  `HTML2APK_KEY_PASSWORD`. Every build is checked with `apksigner verify`,
  and the signer's SHA-256 is recorded in build history.

## Verified (Galaxy S25 Ultra, Windows 11, 2026-10-21)

- Key created on the phone, backed up via the system "save" screen as
  `upload.jks`; `keytool -list` on Windows reads it (PKCS12, SHA256withRSA,
  2048-bit, valid to 2056). Password not present in plain text on the phone.
- Release APK built on the phone and release APK built on Windows from the
  backup have the identical certificate SHA-256. Installing the Windows build
  over the phone build succeeds (Android accepts it as an update); installing
  a debug-signed build over it fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
- Second release with the same version code is refused.
- A genuine JKS created by `keytool -storetype JKS` with separate store and
  key passwords imports on the phone with the same SHA-256.
- 8 JVM tests for certificate building, PKCS12 and JKS reading.

## Not done

- **AAB signing** (milestone 5).
- **Google Play App Signing** guidance: HTML2APK's key works as the *upload*
  key; Play holds the app-signing key. The UI explains the same-key rule but
  not the upload-key reset process.
- Optional biometric/PIN unlock before using a release key.
- Windows desktop UI for key management (CLI only).
