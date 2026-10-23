# ADR 0008: Windows installers (MSIX)

Status: accepted (2026-10-23)

## Context

A bare `.exe` (ADR 0007) has no Start menu entry, no uninstall and no
update path. Users asked for apps that install like other Windows
software. MSIX is Windows' own package format: per-user install without
admin rights, clean uninstall, in-place updates, and the format the
Microsoft Store takes.

## Decision

- **Package = the .exe from ADR 0007 + tiles + manifest.**
  `app/lib/src/engine/msix_builder.dart` builds the .exe into a staging
  folder (`App\<name>.exe`), renders `StoreLogo` (50), `Square44x44Logo`
  and `Square150x150Logo` from the project icon (or a letter tile), and
  writes `AppxManifest.xml`:
  - `Identity Name` = application ID with characters outside
    `[A-Za-z0-9.-]` turned into `-` (3–50 characters);
  - `Version` = `versionName` as up to three numbers 0–65535 plus `.0`
    (the Store requires the fourth part to be 0); other version names are
    refused with a message, because Windows only updates to a higher
    version;
  - `Publisher` = the signing certificate's subject, exactly;
  - x64, `Windows.Desktop` 10.0.17763+, `Windows.FullTrustApplication`
    with `runFullTrust` and `internetClient`.
- **Tools: the Windows SDK's `makeappx.exe` and `signtool.exe`**, found
  under `Windows Kits\10\bin\<newest>\x64`. They are not shipped with
  iLoveHTML; the UI shows the `winget` command when they are missing.
  `makeappx pack /h SHA256`, then `signtool sign /fd SHA256`. The package
  is written to `<name>.part.msix` (signtool picks its signer by
  extension) and renamed only after signing succeeded.
- **One installer certificate per iLoveHTML user**, in
  `workspace\windows-signing\` (`certificate.pfx`, `.cer`, and a JSON
  record whose password is DPAPI-protected like release keys, ADR 0004):
  - *Use my .pfx*: the user's code-signing certificate. It must have a
    private key and the Code Signing EKU (1.3.6.1.5.5.7.3.3).
  - *Create test certificate*: keytool (from the JDK already used for
    Android builds) makes a self-signed RSA 3072 / SHA-256 certificate
    `CN=<publisher name>` with the Code Signing EKU, valid 5 years.
    A test certificate's `.cer` is copied next to every installer.
  - Certificates are read with .NET's `X509Certificate2` through
    PowerShell with `EphemeralKeySet`: no certificate store is touched.
    Passwords reach keytool and PowerShell through the environment.
- **Replacing the certificate warns** that installed apps only update from
  installers with the same publisher.

## Trade-offs

- `signtool` accepts the `.pfx` password only on its command line. Other
  processes of the same Windows user can read command lines, but they can
  already decrypt the DPAPI-protected password, so this exposes nothing
  new; other users cannot read it without admin rights. The password is
  never logged.
- A test certificate is not trusted anywhere. People must import the
  `.cer` into Local Machine → Trusted People once (admin), or Windows
  refuses the installer. Only a certificate from a certificate authority
  removes this step; buying one is the user's decision.
- Needing the Windows SDK (≈ 1 GB of which two tools are used) is heavy
  for people who only want installers. Bundling `makeappx`/`signtool`
  (Microsoft.Windows.SDK.BuildTools) would remove it; not done yet.
- MSIX virtualises writes to `%LOCALAPPDATA%`, so a packaged app's
  WebView2 data lives in the package's own folder and is removed on
  uninstall. That is the expected behaviour for an installed app.

## Verified (2026-10-23)

- `app/test/msix_builder_test.dart`: version, identity, file-name, CN and
  XML-escaping rules; end to end with a real test certificate: the
  package is signed by `CN=iLoveHTML Test` (read from
  `AppxSignature.p7x`), its manifest has the expected identity,
  publisher, version and escaped name, the exe and three tiles are
  inside, the `.cer` is written, no password appears in the log, a wrong
  `.pfx` password keeps the current certificate, and builds fail without
  a certificate.
- Manually: a built package, unpacked and registered with Developer
  Mode, installed per user, started from its Start menu entry at its
  packaged path, and uninstalled cleanly.

## Not done

- Installing a signed package on a PC that trusts the test certificate
  (needs an admin to trust it; left to the user).
- Microsoft Store submission, `.appinstaller` auto-update files, ARM64.
- Bundling the SDK tools.
