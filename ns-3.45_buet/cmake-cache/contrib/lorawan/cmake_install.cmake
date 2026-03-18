# Install script for directory: /Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan

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
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/build/lib/libns3.45-lorawan-default.dylib")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.45-lorawan-default.dylib" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.45-lorawan-default.dylib")
    execute_process(COMMAND /usr/bin/install_name_tool
      -delete_rpath "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/build/lib"
      -add_rpath "/usr/local/lib:$ORIGIN/:$ORIGIN/../lib:/usr/local/lib64:$ORIGIN/:$ORIGIN/../lib64"
      "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.45-lorawan-default.dylib")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/strip" -x "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libns3.45-lorawan-default.dylib")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/ns3" TYPE FILE FILES
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-net-device.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lorawan-mac.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-phy.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/building-penetration-loss.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/correlated-shadowing-propagation-loss-model.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-channel.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-interference-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/gateway-lorawan-mac.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/end-device-lorawan-mac.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/class-a-end-device-lorawan-mac.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/gateway-lora-phy.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/end-device-lora-phy.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/simple-end-device-lora-phy.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/simple-gateway-lora-phy.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/sub-band.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/logical-lora-channel.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/logical-lora-channel-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/periodic-sender.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/one-shot-sender.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/forwarder.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lorawan-mac-header.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-frame-header.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/mac-command.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-device-address.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-device-address-generator.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-tag.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/network-server.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/network-status.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/network-controller.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/network-controller-components.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/network-scheduler.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/end-device-status.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/gateway-status.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-radio-energy-model.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-tx-current-model.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/lora-utils.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/adr-component.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/model/hex-grid-position-allocator.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/helper/lora-radio-energy-model-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/helper/lora-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/helper/lora-phy-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/helper/lorawan-mac-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/helper/periodic-sender-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/helper/one-shot-sender-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/helper/forwarder-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/helper/network-server-helper.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/helper/lora-packet-tracker.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/contrib/lorawan/test/utilities.h"
    "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/build/include/ns3/lorawan-module.h"
    )
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/dipit099/NeatDownload/ns3 project/ns-3.45_buet/cmake-cache/contrib/lorawan/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
