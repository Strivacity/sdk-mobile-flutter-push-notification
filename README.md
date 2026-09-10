# strivacity_pushnotification

## Developer notes

**Open [`strivacity_pushnotification/`](strivacity_pushnotification) as the
project root** — not this repository's root. That subdirectory is the actual
Flutter plugin (`pubspec.yaml`, `lib/`, `ios/`, `android/`, `example/`,
`test/`, ...). In Android Studio / IntelliJ, use *File > Open* and point it at
`strivacity_pushnotification/` directly; the same applies to `flutter`/`dart`
CLI commands (`cd strivacity_pushnotification` first) and to VS Code.

See [`strivacity_pushnotification/README.md`](strivacity_pushnotification/README.md)
for the plugin's actual documentation and getting-started instructions.

### Why the plugin isn't at this repo's root

This plugin ships iOS support via Swift Package Manager only — no
`.podspec`, no CocoaPods. That requires the directory containing the plugin's
`pubspec.yaml` to be named exactly `strivacity_pushnotification`, matching the
package name Xcode expects when it resolves `FlutterGeneratedPluginSwiftPackage`.

This repository, however, has to be checked out under a fixed name that
doesn't match the package name. Renaming this checkout isn't an option, so the plugin is nested
in a correctly-named subdirectory instead — that way nobody cloning this repo
needs to remember to rename anything for the iOS build to work.

**The mechanism, precisely:** Xcode's Swift Package Manager resolver computes
a local package's *identity* from the last path component (basename) of the
directory it's checked out in — not from the `name:` field in `Package.swift`,
and not from `pubspec.yaml`. This is implemented directly in Swift Package
Manager's own source:
[`PackageIdentity.swift#L44`](https://github.com/swiftlang/swift-package-manager/blob/6b256f36d86bc134575940f1aa2009133594d057/Sources/PackageModel/PackageIdentity.swift#L44).
If the checkout directory's name doesn't exactly match the plugin's declared
package name, Xcode fails with:

```
unable to override package 'strivacity_pushnotification' because its identity
'<checkout-dir-name>' doesn't match override's identity (directory name)
'strivacity_pushnotification'
```
