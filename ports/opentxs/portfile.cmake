set(OPENTXS_REPO "ssh://git@github.com/matterfi/opentxs")
set(OPENTXS_COMMIT "3dd365dc7c758b8250f7aa93820fc14b79ff58dc")
set(SOURCE_PATH "${DOWNLOADS}/opentxs.git")
set(OT_VERSION_STRING "1.210.1-0-g3dd365dc7c")

find_program(
  GIT
  git
  git.cmd
  NO_CMAKE_FIND_ROOT_PATH
)

if(GIT-NOTFOUND)
  message(FATAL_ERROR "git not found.")
endif()

if(EXISTS "${SOURCE_PATH}")
  vcpkg_execute_in_download_mode(
    COMMAND
    "${GIT}"
    -C
    "${SOURCE_PATH}"
    remote
    set-url
    origin
    "${OPENTXS_REPO}"
  )
  vcpkg_execute_in_download_mode(
    COMMAND
    "${GIT}"
    -C
    "${SOURCE_PATH}"
    remote
    update
    -p
  )
else()
  vcpkg_execute_in_download_mode(
    COMMAND
    "${GIT}"
    clone
    --recurse-submodules
    "${OPENTXS_REPO}"
    "${SOURCE_PATH}"
  )
endif()

file(REMOVE_RECURSE "${SOURCE_PATH}/cmake")
file(REMOVE_RECURSE "${SOURCE_PATH}/deps")

vcpkg_execute_in_download_mode(
  COMMAND
  "${GIT}"
  -C
  "${SOURCE_PATH}"
  reset
  --hard
  "${OPENTXS_COMMIT}"
)
vcpkg_execute_in_download_mode(
  COMMAND
  "${GIT}"
  -C
  "${SOURCE_PATH}"
  submodule
  update
  --init
  --recursive
)

set(OPENTXS_QT_DIR "")
set(OPENTXS_QT6_DIR "")
set(OPENTXS_USE_QT OFF)

if(("qt6"
    IN_LIST
    FEATURES)
   OR ("external-qt6"
       IN_LIST
       FEATURES)
)
  set(OPENTXS_USE_QT ON)
  set(OPENTXS_QT_VERSION_MAJOR 6)
endif()

if("external-qt6" IN_LIST FEATURES)
  if(NOT DEFINED ENV{EXTERNAL_QT_DIR})
    message(FATAL_ERROR "EXTERNAL_QT_DIR must be defined")
  endif()

  cmake_path(SET OPENTXS_QT_PATH NORMALIZE $ENV{EXTERNAL_QT_DIR})
  set(OPENTXS_QT_DIR "-DQT_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6")
  set(OPENTXS_QT6_DIR "-DQt6_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6")
  set(OPENTXS_Qt6Core_DIR "-DQt6Core_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6Core")
  set(OPENTXS_Qt6Gui_DIR "-DQt6Gui_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6Gui")
  set(OPENTXS_Qt6HostInfo_DIR "-DQt6HostInfo_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6HostInfo")
  set(OPENTXS_Qt6Network_DIR "-DQt6Network_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6Network")
  set(OPENTXS_Qt6QmlBuiltins_DIR "-DQt6QmlBuiltins_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6QmlBuiltins")
  set(OPENTXS_Qt6QmlIntegration_DIR "-DQt6QmlIntegration_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6QmlIntegration")
  set(OPENTXS_Qt6Qml_DIR "-DQt6Qml_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6Qml")
  message(STATUS "using external Qt located at ${OPENTXS_QT_DIR}")

  if(VCPKG_CROSSCOMPILING)
    cmake_path(SET OPENTXS_QT_HOST_PATH NORMALIZE $ENV{QT_HOST_PATH})
    set(OPENTXS_QT_CROSSCOMPILING "-DQT_HOST_PATH=${OPENTXS_QT_HOST_PATH}")
    message(STATUS "using host Qt located at ${OPENTXS_QT_HOST_PATH}")
  endif()
endif()

set(OPENTXS_PROTOBUF_PROTOC_LOCATION "${CURRENT_HOST_INSTALLED_DIR}/tools/protobuf/protoc")
set(OPENTXS_PROTOBUF_PROTOC_EXECUTABLE "-DOPENTXS_PROTOBUF_PROTOC_EXECUTABLE=${OPENTXS_PROTOBUF_PROTOC_LOCATION}")
message(STATUS "using host protoc located at ${OPENTXS_PROTOBUF_PROTOC_LOCATION}")

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        matterfi OT_ENABLE_MATTERFI
        pstl     OT_USE_PSTL
        rpc      OT_ENABLE_RPC
        test     OPENTXS_BUILD_TESTS
        tbb      OT_WITH_TBB
)


if(WIN32)
  vcpkg_cmake_configure(
    SOURCE_PATH
    "${SOURCE_PATH}"
    OPTIONS
    -DOPENTXS_PEDANTIC_BUILD=OFF
    -DOT_CRYPTO_SUPPORTED_KEY_RSA=ON
    -DOT_CASH_USING_LUCRE=OFF
    -DOT_SCRIPT_USING_CHAI=OFF
    -DOT_WITH_QT=${OPENTXS_USE_QT}
    -DOT_WITH_QML=${OPENTXS_USE_QT}
    -DOT_ENABLE_NONFREE=ON
    -DOT_USE_VCPKG_TARGETS=ON
    -DOT_BOOST_JSON_HEADER_ONLY=OFF
    -DOT_INSTALL_LIBRARY_DEPENDENCIES=OFF
    -DOT_MULTICONFIG=OFF
    -DOT_PCH=OFF
    ${FEATURE_OPTIONS}
    -DCMAKE_C_COMPILER=clang-cl.exe
    -DCMAKE_CXX_COMPILER=clang-cl.exe
    -Dopentxs_GIT_VERSION=${OT_VERSION_STRING}
    "${OPENTXS_PROTOBUF_PROTOC_EXECUTABLE}"
    "${OPENTXS_QT_DIR}"
    "${OPENTXS_QT6_DIR}"
    "${OPENTXS_Qt6Core_DIR}"
    "${OPENTXS_Qt6Gui_DIR}"
    "${OPENTXS_Qt6HostInfo_DIR}"
    "${OPENTXS_Qt6Network_DIR}"
    "${OPENTXS_Qt6QmlBuiltins_DIR}"
    "${OPENTXS_Qt6QmlIntegration_DIR}"
    "${OPENTXS_Qt6Qml_DIR}"
    "${OPENTXS_QT_CROSSCOMPILING}"
    OPTIONS_RELEASE
    -DOPENTXS_DEBUG_BUILD=OFF
    -DOT_INSTALL_HEADERS=ON
    -DOT_INSTALL_LICENSE=ON
    -DOT_INSTALL_PROTOBUF=ON
    -DOT_LICENSE_FILE_NAME=copyright
    OPTIONS_DEBUG
    -DOPENTXS_DEBUG_BUILD=ON
    -DOT_INSTALL_HEADERS=OFF
    -DOT_INSTALL_LICENSE=OFF
    -DOT_INSTALL_PROTOBUF=OFF
  )
else()
  vcpkg_cmake_configure(
    SOURCE_PATH
    "${SOURCE_PATH}"
    OPTIONS
    -DOPENTXS_PEDANTIC_BUILD=OFF
    -DOT_CRYPTO_SUPPORTED_KEY_RSA=ON
    -DOT_CASH_USING_LUCRE=OFF
    -DOT_SCRIPT_USING_CHAI=OFF
    -DOT_WITH_QT=${OPENTXS_USE_QT}
    -DOT_WITH_QML=${OPENTXS_USE_QT}
    -DOT_ENABLE_NONFREE=ON
    -DOT_USE_VCPKG_TARGETS=ON
    -DOT_BOOST_JSON_HEADER_ONLY=OFF
    -DOT_INSTALL_LIBRARY_DEPENDENCIES=OFF
    -DOT_MULTICONFIG=OFF
    -DOT_PCH=OFF
    ${FEATURE_OPTIONS}
    -Dopentxs_GIT_VERSION=${OT_VERSION_STRING}
    "${OPENTXS_PROTOBUF_PROTOC_EXECUTABLE}"
    "${OPENTXS_QT_DIR}"
    "${OPENTXS_QT6_DIR}"
    "${OPENTXS_Qt6Core_DIR}"
    "${OPENTXS_Qt6Gui_DIR}"
    "${OPENTXS_Qt6HostInfo_DIR}"
    "${OPENTXS_Qt6Network_DIR}"
    "${OPENTXS_Qt6QmlBuiltins_DIR}"
    "${OPENTXS_Qt6QmlIntegration_DIR}"
    "${OPENTXS_Qt6Qml_DIR}"
    "${OPENTXS_QT_CROSSCOMPILING}"
    OPTIONS_RELEASE
    -DOPENTXS_DEBUG_BUILD=OFF
    -DOT_INSTALL_HEADERS=ON
    -DOT_INSTALL_LICENSE=ON
    -DOT_INSTALL_PROTOBUF=ON
    -DOT_LICENSE_FILE_NAME=copyright
    OPTIONS_DEBUG
    -DOPENTXS_DEBUG_BUILD=ON
    -DOT_INSTALL_HEADERS=OFF
    -DOT_INSTALL_LICENSE=OFF
    -DOT_INSTALL_PROTOBUF=OFF
  )
endif()

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(NO_PREFIX_CORRECTION)

file(
  INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)
