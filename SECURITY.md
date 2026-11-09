# Security

## Reporting a problem

Please do not open a public issue for a security problem. Report it
privately: on the repository's **Security** tab choose **Report a
vulnerability**. Say what you found, how to reproduce it, and which version
and platform (Android or Windows) you used.

Fixes go into the next release, and the release notes credit you unless
you ask otherwise.

## What counts

- iLoveHTML itself: importing files, ZIPs, backups and URLs; the preview;
  building; release keys and certificates; the update check; the QR install
  server.
- The apps iLoveHTML builds: the Android wrapper (`android_template/`) and
  the Windows wrapper (`windows_template/`), for example a web page reaching
  files, other apps or native features it was not given.

Not covered: what a website does inside its own page (iLoveHTML ships the
site's files as they are and does not scan them), and warnings from Play
Protect or SmartScreen about apps that are not yet known to them.

## Supported versions

Only the latest release gets fixes.

## More

How the project is hardened, what was reviewed and the known limits:
[docs/security-review.md](docs/security-review.md).
