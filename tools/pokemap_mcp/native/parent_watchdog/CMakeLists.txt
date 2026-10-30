cmake_minimum_required(VERSION 3.14)
project(avelune_parent_watchdog LANGUAGES CXX)
find_package(Threads REQUIRED)
add_library(avelune_parent_watchdog SHARED parent_watchdog.cc)
target_compile_features(avelune_parent_watchdog PRIVATE cxx_std_17)
target_link_libraries(avelune_parent_watchdog PRIVATE Threads::Threads)
set_target_properties(avelune_parent_watchdog PROPERTIES
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/parent-watchdog"
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/parent-watchdog"
)
