# Stockfish 19 for Kibitz (Android) — corresponding source

This repository contains the **complete corresponding source code** of the Stockfish chess
engine binaries that are shipped inside the Kibitz Android app, as required by the
GNU General Public License v3.

- **Engine:** Stockfish 19, **unmodified**, from the official repository
  <https://github.com/official-stockfish/Stockfish>, tag `sf_19`
  (commit `edb0d9db6731067ec50ce619ff372b463bc4dd5d`). It is in `stockfish/`.
- **Build files:** `CMakeLists.txt` is the exact file the app uses to compile the engine.
  `build.sh` runs the same build without Android Studio.
- **Licence:** Stockfish is licensed under the GNU GPL v3 — see `LICENSE` and
  `stockfish/Copying.txt`. The Kibitz app itself is a separate, proprietary program
  that starts Stockfish as an independent process and talks to it over the standard UCI
  text protocol; the app's own code is not part of this repository.

## What the app ships

| Android ABI | File in the APK | Compiler flags (besides `-O3 -fno-exceptions -DNDEBUG -DUSE_PTHREADS -DNNUE_EMBEDDING_OFF`) |
|---|---|---|
| arm64-v8a | `lib/arm64-v8a/libstockfish.so` | `-DIS_64BIT -DUSE_POPCNT -DUSE_NEON=8` |
| arm64-v8a | `lib/arm64-v8a/libstockfish_dotprod.so` | `-DIS_64BIT -DUSE_POPCNT -DUSE_NEON=8 -march=armv8.2-a+dotprod -DUSE_NEON_DOTPROD` |
| armeabi-v7a | `lib/armeabi-v7a/libstockfish.so` | `-DUSE_POPCNT -mfpu=neon -DUSE_NEON=7` |
| x86_64 | `lib/x86_64/libstockfish.so` | `-DIS_64BIT -DUSE_POPCNT -msse3 -mpopcnt -mssse3 -msse4.1 -DUSE_SSE2 -DUSE_SSSE3 -DUSE_SSE41` |
| x86 | `lib/x86/libstockfish.so` | `-msse2 -mssse3 -DUSE_SSE2 -DUSE_SSSE3` |

Despite the `.so` name these are ordinary executables (Android only installs files named
`lib*.so` into a directory from which an app may run programs). They are linked with
`-static-libstdc++` against the NDK's libc++ (`ANDROID_STL=c++_static`), minimum API level 26,
and with `-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384` so they run on devices
with 16 KB memory pages (a Google Play requirement for Android 15+).

### Neural network

The engine is built with `NNUE_EMBEDDING_OFF`; the app ships the official Stockfish 19
network separately and starts the engine in the directory that contains it:

- File: `nn-1a298aa575a0.nnue`
- SHA-256: `1a298aa575a085434d29027978dc36867fe9c5bcea9376654b7a8eba1e52dfc2`
- Download: <https://tests.stockfishchess.org/api/nn/nn-1a298aa575a0.nnue>
  (or run `stockfish/scripts/net.sh` from `stockfish/src`)

## Building it yourself

Requirements: Android NDK **27.0.12077973**, CMake ≥ 3.22 and Ninja (both ship with the
Android SDK under `cmake/3.22.1/bin`).

```bash
export ANDROID_NDK=/path/to/android-sdk/ndk/27.0.12077973
./build.sh            # all ABIs, results in out/<abi>/
./build.sh arm64-v8a  # a single ABI
```

To install your own build into the app on a device, replace the corresponding
`lib/<abi>/libstockfish*.so` file (for example by rebuilding the APK); the app uses
whatever engine executable is present.

## Questions

Stockfish is developed by the Stockfish team — <https://stockfishchess.org>.
All credit for the engine goes to them.
