# Builds Stockfish 19 as a standalone executable. The output is named lib*.so so the
# Android packager places it in nativeLibraryDir, from where the app can execute it.
cmake_minimum_required(VERSION 3.22.1)
project(kibitz_engine CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(SF ${CMAKE_CURRENT_SOURCE_DIR}/stockfish/src)
set(SF_SOURCES
    ${SF}/attacks.cpp ${SF}/benchmark.cpp ${SF}/bitboard.cpp ${SF}/evaluate.cpp ${SF}/main.cpp
    ${SF}/misc.cpp ${SF}/movegen.cpp ${SF}/movepick.cpp ${SF}/position.cpp
    ${SF}/search.cpp ${SF}/thread.cpp ${SF}/timeman.cpp ${SF}/tt.cpp ${SF}/uci.cpp
    ${SF}/ucioption.cpp ${SF}/tune.cpp ${SF}/syzygy/tbprobe.cpp
    ${SF}/nnue/nnue_accumulator.cpp ${SF}/nnue/nnue_misc.cpp ${SF}/nnue/network.cpp
    ${SF}/nnue/features/half_ka_v2_hm.cpp ${SF}/nnue/features/full_threats.cpp
    ${SF}/nnue/features/pp_3wide.cpp
    ${SF}/engine.cpp ${SF}/score.cpp ${SF}/memory.cpp)

set(SF_COMMON_FLAGS -O3 -fno-exceptions -DNDEBUG -DUSE_PTHREADS
    -DNNUE_EMBEDDING_OFF -Wno-deprecated-declarations)

function(stockfish_executable name)
    add_executable(${name} ${SF_SOURCES})
    target_compile_options(${name} PRIVATE ${SF_COMMON_FLAGS} ${ARGN})
    # 16 KB page alignment: required by Google Play for apps targeting Android 15+ (harmless on 4 KB devices).
    target_link_options(${name} PRIVATE -static-libstdc++ -Wl,--gc-sections -Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384)
    set_target_properties(${name} PROPERTIES
        OUTPUT_NAME "lib${name}.so"
        SUFFIX ""
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})
endfunction()

if(ANDROID_ABI STREQUAL "arm64-v8a")
    stockfish_executable(stockfish -DIS_64BIT -DUSE_POPCNT -DUSE_NEON=8)
    # Faster variant for CPUs with the ARMv8.2 dot-product extension; picked at runtime.
    stockfish_executable(stockfish_dotprod -DIS_64BIT -DUSE_POPCNT -DUSE_NEON=8 -march=armv8.2-a+dotprod -DUSE_NEON_DOTPROD)
elseif(ANDROID_ABI STREQUAL "x86_64")
    stockfish_executable(stockfish -DIS_64BIT -DUSE_POPCNT -msse3 -mpopcnt -mssse3 -msse4.1
        -DUSE_SSE2 -DUSE_SSSE3 -DUSE_SSE41)
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    # Older and budget 32-bit phones. NEON is mandatory on every armeabi-v7a device Android 8+ runs on.
    stockfish_executable(stockfish -DUSE_POPCNT -mfpu=neon -DUSE_NEON=7)
elseif(ANDROID_ABI STREQUAL "x86")
    # 32-bit x86 (old emulators, a few tablets). SSSE3 is guaranteed by the Android x86 ABI.
    stockfish_executable(stockfish -msse2 -mssse3 -DUSE_SSE2 -DUSE_SSSE3)
else()
    message(FATAL_ERROR "Unsupported ABI ${ANDROID_ABI}")
endif()
