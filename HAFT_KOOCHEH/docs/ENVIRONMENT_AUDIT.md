# Environment audit — 2026-11-15

Workspace: /workspace/scratch/9fd60dbdba5c
Project: HAFT_KOOCHEH/ (new; no existing project or active Git repo was found).
OS: Debian GNU/Linux 13.6 (trixie), x86_64; kernel 6.18.57.
Git 2.52.0; Python 3.12.14.

## Engine
Initial PATH lookup found no executable Godot. Existing aliases at
/usr/local/bin/godot and godot4 point to a missing 4.6.3 binary.
Downloaded the official Linux x86_64 **Standard** ZIP for 4.7.2 to workspace tools/.
Actual executable: ../tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
Actual --version: **4.7.2.stable.official.ed1daf0bf** (exit 0).
Engine binary is a local tool, not part of the project source archive.
Official download: https://downloads.godotengine.org/?version=4.7.2&flavor=stable&slug=linux.x86_64.zip
Binary fingerprint and raw probes: android_preflight_results.json.
Fingerprint is recorded for reproducibility, not an independent signature verification.

## Android preflight (Test E)
| Component | Required baseline | Observed |
| --- | --- | --- |
| OpenJDK | 17 | Java runtime 21.0.13; javac absent; JDK 17 not found |
| SDK | Android SDK + command-line tools | sdkmanager absent; no SDK in probed roots |
| Platform Tools | >=35.0.0 | adb absent; version not verifiable |
| Build Tools | 35.0.1 | not found in probed SDK roots |
| Platform | android-35 | not found in probed SDK roots |
| NDK | r28b / 28.1.13356709 | not found in probed SDK roots |
| CMake | 3.10.2.4988404 | cmake command absent; not found in SDK roots |
| Export templates | 4.7.2.stable Standard | not found in default user Godot data directories |

Probed roots: /opt/android-sdk, /opt/android, /usr/lib/android-sdk,
/home/agent/Android/Sdk, /root/Android/Sdk; user Godot export_templates directories.
ANDROID_HOME, ANDROID_SDK_ROOT and JAVA_HOME unset. XDG_DATA_HOME is
/home/agent/.local/share. This is a scoped filesystem/PATH audit, not proof that
no unconfigured installation exists anywhere on the host.

Official Stable documentation checked:
https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
It recommends JDK 17 and also supports newer JDKs. The Java 21 runtime alone
is not a verified complete Android JDK setup. The requested SDK component
versions match the page checked on the audit date.

After installing official command-line tools, the documented package command is:

```sh
sdkmanager --sdk_root=<android_sdk_path> "platform-tools" "build-tools;35.0.1" "platforms;android-35" "cmdline-tools;latest" "cmake;3.10.2.4988404" "ndk;28.1.13356709"
```

This installation command was NOT executed. No Android toolchain installation,
APK export, device test, Release key or final publishing occurred.
Debug export is currently blocked; no export preset was added without validation.

## Graphics / editor
DISPLAY and WAYLAND_DISPLAY unset; Xvfb/xvfb-run unavailable on PATH.
Actual graphical Editor launch failed (exit 1): X11 Display unavailable;
Wayland/XDG_RUNTIME_DIR initialization failed. Raw output including cleanup
warnings is retained in engine_test_results.json. Headless Editor import succeeds.
Visual title placement, GPU Compatibility rendering, resizing/letterboxing and
physical Android orientation remain unverified.

## R1 follow-up — supersedes the graphics/Git status above
Xvfb and xvfb-run remain absent on PATH. Xorg 1.21.1.16, its dummy driver and
Mesa swrast_dri.so are present. ldd resolves the listed driver dependencies.
A local dummy-screen Xorg startup failed: `Could not create lock file in
/tmp/.tX91-lock`. No usable display was established. With DISPLAY=:91 and
LIBGL_ALWAYS_SOFTWARE=1, Godot graphical launch failed to connect to X11/Wayland.
No software OpenGL context or actual title rendering has been verified.
No real execution screenshot is available. See r1_test_results.json for raw evidence.
Git report generation order was corrected; final Index and source ZIP both contain
18 files, including docs/git_validation_results.json. No commit or remote exists.
