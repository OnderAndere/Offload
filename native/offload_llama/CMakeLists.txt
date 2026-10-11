# Offload's handwriting reader (T6a.2, DD-021): one shared library,
# offload_llama, with llama.cpp, mtmd and ggml's CPU backend linked in
# statically behind the small C API of offload_llama.h. Only that API is
# exported, so a second ggml (whisper.cpp, M6) cannot clash with this one.
#
# The llama.cpp source is not in the repository: the pinned release is
# downloaded once into .cache/ next to this file, checked against its
# SHA-256 and unpacked; later builds reuse it. Built for the CPU only and
# without common, tools, server, OpenSSL, subprocess or video: nothing that
# reaches the network or starts a program is compiled in (DD-008).
#
# Used by android/app/build.gradle.kts (arm64-v8a, x86_64) and by
# windows/CMakeLists.txt.
cmake_minimum_required(VERSION 3.18...3.28)
project(offload_llama C CXX)

set(OFFLOAD_LLAMA_TAG b11526)
set(OFFLOAD_LLAMA_SHA256
  6fb0c360b0f9528d75e50e0ddfdb19a6f471c5ba4ea8844e9e73c64862f687b5)
set(OFFLOAD_LLAMA_URL
  "https://github.com/ggml-org/llama.cpp/archive/refs/tags/${OFFLOAD_LLAMA_TAG}.tar.gz")

# --- Source: download once, verify, unpack -------------------------------

set(cache_dir "${CMAKE_CURRENT_SOURCE_DIR}/.cache")
set(archive "${cache_dir}/llama.cpp-${OFFLOAD_LLAMA_TAG}.tar.gz")
set(source_dir "${cache_dir}/llama.cpp-${OFFLOAD_LLAMA_TAG}")
set(stamp "${source_dir}/.offload-sha256")

file(MAKE_DIRECTORY "${cache_dir}")
# Gradle may configure several ABIs at once; one of them unpacks.
file(LOCK "${cache_dir}/.lock" GUARD FILE TIMEOUT 1800)
set(unpacked FALSE)
if(EXISTS "${stamp}")
  file(READ "${stamp}" unpacked_hash)
  string(STRIP "${unpacked_hash}" unpacked_hash)
  if(unpacked_hash STREQUAL OFFLOAD_LLAMA_SHA256)
    set(unpacked TRUE)
  endif()
endif()
if(NOT unpacked)
  if(EXISTS "${archive}")
    file(SHA256 "${archive}" archive_hash)
    if(NOT archive_hash STREQUAL OFFLOAD_LLAMA_SHA256)
      file(REMOVE "${archive}")
    endif()
  endif()
  if(NOT EXISTS "${archive}")
    message(STATUS "offload_llama: downloading llama.cpp ${OFFLOAD_LLAMA_TAG}")
    file(DOWNLOAD "${OFFLOAD_LLAMA_URL}" "${archive}.part"
      EXPECTED_HASH SHA256=${OFFLOAD_LLAMA_SHA256}
      TLS_VERIFY ON
      STATUS download_status)
    list(GET download_status 0 download_code)
    if(NOT download_code EQUAL 0)
      file(REMOVE "${archive}.part")
      message(FATAL_ERROR "offload_llama: download failed: ${download_status}")
    endif()
    file(RENAME "${archive}.part" "${archive}")
  endif()
  file(REMOVE_RECURSE "${source_dir}")
  file(ARCHIVE_EXTRACT INPUT "${archive}" DESTINATION "${cache_dir}")
  if(NOT EXISTS "${source_dir}/CMakeLists.txt")
    message(FATAL_ERROR "offload_llama: ${archive} did not unpack to ${source_dir}")
  endif()
  file(WRITE "${stamp}" "${OFFLOAD_LLAMA_SHA256}\n")
endif()
file(LOCK "${cache_dir}/.lock" RELEASE)

# --- llama.cpp options ---------------------------------------------------

# The unpacked source has no .git; without a ceiling, llama.cpp's version
# lookup would find Offload's repository instead.
set(ENV{GIT_CEILING_DIRECTORIES} "${cache_dir}")
set(LLAMA_BUILD_NUMBER 11526)
set(LLAMA_BUILD_COMMIT 5e4878e9)

set(BUILD_SHARED_LIBS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
# Only offload_llama's own functions are exported.
set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

set(LLAMA_BUILD_COMMON OFF)
set(LLAMA_BUILD_TESTS OFF)
set(LLAMA_BUILD_TOOLS OFF)
set(LLAMA_BUILD_EXAMPLES OFF)
set(LLAMA_BUILD_SERVER OFF)
set(LLAMA_BUILD_APP OFF)
set(LLAMA_BUILD_MTMD ON)
set(LLAMA_OPENSSL OFF)
set(LLAMA_SUBPROCESS OFF)
set(MTMD_VIDEO OFF CACHE BOOL "" FORCE)
set(LLAMA_ALL_WARNINGS OFF)

set(GGML_NATIVE OFF)
set(GGML_BACKEND_DL OFF)
set(GGML_CPU_ALL_VARIANTS OFF)
set(GGML_OPENMP OFF)
set(GGML_CCACHE OFF)
set(GGML_RPC OFF)
set(GGML_CPU_KLEIDIAI OFF)
set(GGML_ALL_WARNINGS OFF)

# One fixed CPU level per architecture (no runtime choice of variants).
# arm64: dotprod and i8mm, the instructions that set the speed of the
# quantised matrix products; both target phones (Fairphone Gen. 6,
# Samsung S23) have them. x86_64: AVX2 with FMA and F16C (about every PC
# since 2015; the emulator on the development PC too).
if(ANDROID AND ANDROID_ABI STREQUAL "arm64-v8a")
  set(GGML_CPU_ARM_ARCH "armv8.6-a+dotprod+i8mm+fp16")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$"
       OR (ANDROID AND ANDROID_ABI STREQUAL "x86_64"))
  set(GGML_AVX ON)
  set(GGML_AVX2 ON)
  set(GGML_BMI2 ON)
  set(GGML_FMA ON)
  set(GGML_F16C ON)
else()
  message(FATAL_ERROR "offload_llama: unsupported target ${CMAKE_SYSTEM_PROCESSOR} ${ANDROID_ABI}")
endif()

# A debug build of the app still reads at full speed: the model is useless
# unoptimised (minutes per photo).
foreach(lang C CXX)
  set(CMAKE_${lang}_FLAGS_DEBUG "${CMAKE_${lang}_FLAGS_RELEASE}")
endforeach()

if(MSVC)
  # The Flutter runner defines UNICODE for the whole build; llama.cpp calls
  # the narrow Windows API.
  remove_definitions(-DUNICODE -D_UNICODE)
endif()

# Warnings in llama.cpp's own code are upstream's business; they would
# bury those of the app's build.
if(MSVC)
  add_compile_options(/W0)
else()
  add_compile_options(-w)
endif()

add_subdirectory("${source_dir}" llama.cpp EXCLUDE_FROM_ALL)

# --- The library ---------------------------------------------------------

add_library(offload_llama SHARED offload_llama.c offload_llama.h)
# Not the /w above: the shim's own warnings count.
set_property(TARGET offload_llama PROPERTY COMPILE_OPTIONS "")
if(MSVC)
  # C4201: the nameless union in llama.h.
  target_compile_options(offload_llama PRIVATE /W4 /WX /wd4201)
else()
  target_compile_options(offload_llama PRIVATE -Wall -Wextra -Werror)
endif()
target_compile_definitions(offload_llama PRIVATE OFFLOAD_LLAMA_BUILD)
target_link_libraries(offload_llama PRIVATE mtmd llama ggml)
if(ANDROID)
  # Keep the symbols of the static archives out of the export table and
  # drop unused code.
  target_link_options(offload_llama PRIVATE
    "-Wl,--exclude-libs,ALL" "-Wl,--gc-sections")
endif()
