# Install script for directory: /Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "default")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/build/lib/libns3.45-core-default.dylib")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.45-core-default.dylib" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.45-core-default.dylib")
    execute_process(COMMAND /usr/bin/install_name_tool
      -add_rpath "/usr/local/lib:$ORIGIN/:$ORIGIN/../lib:/usr/local/lib64:$ORIGIN/:$ORIGIN/../lib64"
      "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.45-core-default.dylib")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/strip" -x "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.45-core-default.dylib")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/ns3" TYPE FILE FILES
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/build/include/ns3/core-config.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/int64x64-128.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/helper/csv-reader.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/helper/event-garbage-collector.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/helper/random-variable-stream-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/abort.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/ascii-file.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/ascii-test.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/assert.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/attribute-accessor-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/attribute-construction-list.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/attribute-container.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/attribute-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/attribute.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/boolean.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/breakpoint.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/build-profile.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/calendar-scheduler.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/callback.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/command-line.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/config.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/default-deleter.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/default-simulator-impl.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/demangle.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/deprecated.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/des-metrics.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/double.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/enum.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/event-id.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/event-impl.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/fatal-error.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/fatal-impl.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/fd-reader.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/environment-variable.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/global-value.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/hash-fnv.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/hash-function.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/hash-murmur3.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/hash.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/heap-scheduler.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/int64x64-double.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/int64x64.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/integer.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/length.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/list-scheduler.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/log-macros-disabled.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/log-macros-enabled.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/log.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/make-event.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/map-scheduler.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/math.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/names.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/node-printer.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/nstime.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/object-base.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/object-factory.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/object-map.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/object-ptr-container.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/object-vector.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/object.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/pair.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/pointer.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/priority-queue-scheduler.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/ptr.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/random-variable-stream.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/rng-seed-manager.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/rng-stream.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/scheduler.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/show-progress.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/shuffle.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/simple-ref-count.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/simulation-singleton.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/simulator-impl.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/simulator.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/singleton.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/string.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/synchronizer.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/system-path.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/system-wall-clock-ms.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/system-wall-clock-timestamp.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/test.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/time-printer.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/timer-impl.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/timer.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/trace-source-accessor.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/traced-callback.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/traced-value.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/trickle-timer.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/tuple.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/type-id.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/type-name.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/type-traits.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/uinteger.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/uniform-random-bit-generator.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/valgrind.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/vector.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/warnings.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/watchdog.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/realtime-simulator-impl.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/wall-clock-synchronizer.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/val-array.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/src/core/model/matrix-array.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/build/include/ns3/core-module.h"
    )
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/cmake-cache/src/core/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
