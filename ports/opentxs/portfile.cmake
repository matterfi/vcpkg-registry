set(OPENTXS_REPO "ssh://git@github.com/matterfi/opentxs")
set(OPENTXS_COMMIT "3938104a9ef097934b4337992a12bb67327c0856")
set(SOURCE_PATH "${DOWNLOADS}/opentxs.git")
set(OT_VERSION_STRING "1.210.2-0-g3938104a9e")

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
  set(OPENTXS_Qt6BundledFreetype_DIR "-DQt6BundledFreetype_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6BundledFreetype")
  set(OPENTXS_Qt6BundledHarfbuzz_DIR "-DQt6BundledHarfbuzz_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6BundledHarfbuzz")
  set(OPENTXS_Qt6BundledLibjpeg_DIR "-DQt6BundledLibjpeg_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6BundledLibjpeg")
  set(OPENTXS_Qt6BundledLibpng_DIR "-DQt6BundledLibpng_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6BundledLibpng")
  set(OPENTXS_Qt6BundledPcre2_DIR "-DQt6BundledPcre2_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6BundledPcre2")
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

if(VCPKG_TARGET_IS_IOS)
  set(OPENTXS_TARGET_IS_IOS "-DOPENTXS_TARGET_IS_IOS=ON")
endif()

if(VCPKG_TARGET_IS_WINDOWS)
  set(OPENTXS_C_COMPILER "-DCMAKE_C_COMPILER=clang-cl.exe")
  set(OPENTXS_CXX_COMPILER "-DCMAKE_CXX_COMPILER=clang-cl.exe")
endif()

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        matterfi OT_ENABLE_MATTERFI
        pstl     OT_USE_PSTL
        rpc      OT_ENABLE_RPC
        test     OPENTXS_BUILD_TESTS
        tbb      OT_WITH_TBB
)

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
  ${OPENTXS_C_COMPILER}
  ${OPENTXS_CXX_COMPILER}
  -Dopentxs_GIT_VERSION=${OT_VERSION_STRING}
  "${OPENTXS_PROTOBUF_PROTOC_EXECUTABLE}"
  "${OPENTXS_QT_DIR}"
  "${OPENTXS_QT6_DIR}"
  "${OPENTXS_Qt6BundledFreetype_DIR}"
  "${OPENTXS_Qt6BundledHarfbuzz_DIR}"
  "${OPENTXS_Qt6BundledLibjpeg_DIR}"
  "${OPENTXS_Qt6BundledLibpng_DIR}"
  "${OPENTXS_Qt6BundledPcre2_DIR}"
  "${OPENTXS_Qt6Core_DIR}"
  "${OPENTXS_Qt6Gui_DIR}"
  "${OPENTXS_Qt6HostInfo_DIR}"
  "${OPENTXS_Qt6Network_DIR}"
  "${OPENTXS_Qt6QmlBuiltins_DIR}"
  "${OPENTXS_Qt6QmlIntegration_DIR}"
  "${OPENTXS_Qt6Qml_DIR}"
  "${OPENTXS_QT_CROSSCOMPILING}"
  "${OPENTXS_TARGET_IS_IOS}"
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

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(NO_PREFIX_CORRECTION)

file(
  INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)
