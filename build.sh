#!/usr/bin/env bash
# Builds the Stockfish executables exactly as the Kibitz app does, without Android Studio.
# Usage: ANDROID_NDK=/path/to/ndk/27.0.12077973 ./build.sh [abi ...]
set -euo pipefail
cd "$(dirname "$0")"

: "${ANDROID_NDK:?Set ANDROID_NDK to the Android NDK 27.0.12077973 directory}"
CMAKE="${CMAKE:-cmake}"
NINJA="${NINJA:-ninja}"
ABIS=("$@")
[ ${#ABIS[@]} -eq 0 ] && ABIS=(arm64-v8a armeabi-v7a x86_64 x86)

for abi in "${ABIS[@]}"; do
  echo "== $abi"
  build="build/$abi"
  out="$PWD/out/$abi"
  mkdir -p "$out"
  "$CMAKE" -S . -B "$build" -G Ninja \
    -DCMAKE_MAKE_PROGRAM="$(command -v "$NINJA")" \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$abi" \
    -DANDROID_PLATFORM=android-26 \
    -DANDROID_STL=c++_static \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="$out"
  "$CMAKE" --build "$build"
done
echo "Done. Executables are in out/<abi>/"
