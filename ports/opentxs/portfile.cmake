set(OPENTXS_REPO "ssh://git@github.com/matterfi/opentxs")
set(OPENTXS_COMMIT "f1aff775d8e2b5002b0a98c43a69f8d326081c51")
set(SOURCE_PATH "${DOWNLOADS}/opentxs.git")
set(OT_VERSION_STRING "1.233.0-0-gf1aff775d8")

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
  file(GLOB QT_CMAKE_DIRS LIST_DIRECTORIES true "${OPENTXS_QT_PATH}/lib/cmake/*")
  set(QT_CMAKE_VARS -DQT_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6\"\ \"-DQT6_DIR=${OPENTXS_QT_PATH}/lib/cmake/Qt6)
  foreach(QT_CMAKE_DIR IN LISTS QT_CMAKE_DIRS)
    string(FIND ${QT_CMAKE_DIR} "/" POS REVERSE)
    math(EXPR BEGIN "${POS} + 1")
    string(SUBSTRING ${QT_CMAKE_DIR} ${BEGIN} -1 DIR_NAME)
    string(APPEND QT_CMAKE_VARS \"\ \"-D${DIR_NAME}_DIR=${QT_CMAKE_DIR})
  endforeach()
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
  -DOPENTXS_HIDE_SYMBOLS=ON
  ${FEATURE_OPTIONS}
  -Dopentxs_GIT_VERSION=${OT_VERSION_STRING}
  "${OPENTXS_PROTOBUF_PROTOC_EXECUTABLE}"
  ${QT_CMAKE_VARS}
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
