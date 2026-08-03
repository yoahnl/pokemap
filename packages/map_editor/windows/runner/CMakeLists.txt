cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(WINSPARKLE_VERSION "0.9.4")
set(WINSPARKLE_SHA256
  "452f4076a41cebc81540dfa34af9a28d4718ac976612c1f41a0581ddcbdf9007")
set(WINSPARKLE_PACKAGE_URL
  "https://www.nuget.org/api/v2/package/WinSparkle/${WINSPARKLE_VERSION}")
set(WINSPARKLE_ROOT
  "${CMAKE_BINARY_DIR}/winsparkle/${WINSPARKLE_VERSION}")
set(WINSPARKLE_PACKAGE
  "${WINSPARKLE_ROOT}/WinSparkle.${WINSPARKLE_VERSION}.nupkg")
set(WINSPARKLE_HEADER
  "${WINSPARKLE_ROOT}/build/native/include/winsparkle.h")
set(WINSPARKLE_LIBRARY
  "${WINSPARKLE_ROOT}/build/native/x64/WinSparkle.lib")
set(WINSPARKLE_DLL
  "${WINSPARKLE_ROOT}/build/native/x64/WinSparkle.dll")

if(NOT EXISTS "${WINSPARKLE_HEADER}" OR
   NOT EXISTS "${WINSPARKLE_LIBRARY}" OR
   NOT EXISTS "${WINSPARKLE_DLL}")
  file(MAKE_DIRECTORY "${WINSPARKLE_ROOT}")
  file(DOWNLOAD
    "${WINSPARKLE_PACKAGE_URL}"
    "${WINSPARKLE_PACKAGE}"
    EXPECTED_HASH "SHA256=${WINSPARKLE_SHA256}"
    TLS_VERIFY ON
    STATUS WINSPARKLE_DOWNLOAD_STATUS
    LOG WINSPARKLE_DOWNLOAD_LOG)
  list(GET WINSPARKLE_DOWNLOAD_STATUS 0 WINSPARKLE_DOWNLOAD_CODE)
  if(NOT WINSPARKLE_DOWNLOAD_CODE EQUAL 0)
    message(FATAL_ERROR
      "WinSparkle ${WINSPARKLE_VERSION} download failed: "
      "${WINSPARKLE_DOWNLOAD_STATUS}\n${WINSPARKLE_DOWNLOAD_LOG}")
  endif()
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xvf "${WINSPARKLE_PACKAGE}"
    WORKING_DIRECTORY "${WINSPARKLE_ROOT}"
    RESULT_VARIABLE WINSPARKLE_EXTRACT_RESULT
    OUTPUT_QUIET)
  if(NOT WINSPARKLE_EXTRACT_RESULT EQUAL 0)
    message(FATAL_ERROR "WinSparkle package extraction failed.")
  endif()
endif()

foreach(WINSPARKLE_REQUIRED_FILE
    "${WINSPARKLE_HEADER}"
    "${WINSPARKLE_LIBRARY}"
    "${WINSPARKLE_DLL}")
  if(NOT EXISTS "${WINSPARKLE_REQUIRED_FILE}")
    message(FATAL_ERROR
      "WinSparkle package has an unexpected structure: "
      "${WINSPARKLE_REQUIRED_FILE}")
  endif()
endforeach()

set(POKEMAP_WINSPARKLE_EDDSA_PUBLIC_KEY
  "$ENV{POKEMAP_WINSPARKLE_EDDSA_PUBLIC_KEY}"
  CACHE STRING "Base64 EdDSA public key embedded in PokeMap releases")
if(POKEMAP_WINSPARKLE_EDDSA_PUBLIC_KEY STREQUAL "")
  set(POKEMAP_WINSPARKLE_CONFIGURED 0)
else()
  string(LENGTH "${POKEMAP_WINSPARKLE_EDDSA_PUBLIC_KEY}"
    POKEMAP_WINSPARKLE_KEY_LENGTH)
  if(NOT POKEMAP_WINSPARKLE_KEY_LENGTH EQUAL 44)
    message(FATAL_ERROR "WinSparkle EdDSA public key must be 44 base64 characters.")
  endif()
  set(POKEMAP_WINSPARKLE_CONFIGURED 1)
endif()

configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/editor_update_resources.rc.in"
  "${CMAKE_CURRENT_BINARY_DIR}/editor_update_resources.rc"
  @ONLY)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "editor_updater_bridge.cpp"
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "${CMAKE_CURRENT_BINARY_DIR}/editor_update_resources.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
target_compile_definitions(${BINARY_NAME} PRIVATE
  "POKEMAP_WINSPARKLE_CONFIGURED=${POKEMAP_WINSPARKLE_CONFIGURED}")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_link_libraries(${BINARY_NAME} PRIVATE "shell32.lib")
target_link_libraries(${BINARY_NAME} PRIVATE "${WINSPARKLE_LIBRARY}")
target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
  "${WINSPARKLE_ROOT}/build/native/include")

add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND "${CMAKE_COMMAND}" -E copy_if_different
    "${WINSPARKLE_DLL}"
    "$<TARGET_FILE_DIR:${BINARY_NAME}>/WinSparkle.dll"
  VERBATIM)

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
