# strivacity_pushnotification

## Developer notes

### Requirements

Building the plugin's Android module — including running Gradle directly in
`strivacity_pushnotification/example/android` (`./gradlew assembleDebug`,
or the `spotlessCheck`/`detekt`/`lint` tasks), rather than via `flutter
build`/`flutter run` — requires **JDK 17 or 21** as `JAVA_HOME`.

**Open [`strivacity_pushnotification/`](strivacity_pushnotification) as the
project root** — not this repository's root. That subdirectory is the actual
Flutter plugin (`pubspec.yaml`, `lib/`, `ios/`, `android/`, `example/`,
`test/`, ...). In Android Studio / IntelliJ, use *File > Open* and point it at
`strivacity_pushnotification/` directly; the same applies to `flutter`/`dart`
CLI commands (`cd strivacity_pushnotification` first) and to VS Code.

See [`strivacity_pushnotification/README.md`](strivacity_pushnotification/README.md)
for the plugin's actual documentation and getting-started instructions.

### Activate the git hooks

This repo's native-code checks (SwiftFormat/SwiftLint and
Spotless/Detekt/Android Lint) run locally via
[lefthook](https://github.com/evilmartians/lefthook), declared in
[`.lefthook.yml`](.lefthook.yml) — the same tool the iOS SDK uses. Install
the toolchain, then activate the hook once per clone, both from **this
repo's root** (not `strivacity_pushnotification/`, since that's where `.git`
and `.lefthook.yml` live):

```bash
brew install lefthook swiftformat swiftlint
lefthook install
```

That installs a `pre-commit` hook running, in parallel: SwiftFormat +
SwiftLint on the plugin's iOS Swift code, and Spotless + Detekt + Android
Lint on the plugin's Android Kotlin code (via
`strivacity_pushnotification/example/android`'s Gradle build). The
[Code Quality](.github/workflows/code-quality.yml) workflow runs the same
checks on pull requests, plus `flutter analyze`, which the hook does not run
— run it yourself from `strivacity_pushnotification/`. The Android job
requires JDK 17 or 21 as `JAVA_HOME` (see
Requirements above) and expects `strivacity_pushnotification/example` to
already have its dependencies fetched at least once (`flutter pub get`).

Verify it's wired up with:

```bash
lefthook run pre-commit --force
```

(`--force` runs the hook even with nothing staged — useful for a first
check.) To remove the hooks again, run `lefthook uninstall`.

Note that lefthook lints the **staged** content, not your working tree — it
stashes unstaged changes first. After fixing a violation, `git add` the file
before retrying the commit, or the hook will keep reporting the old version.

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
