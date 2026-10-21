set(MATTERFI_NAME_ORACLE_REPO "ssh://git@github.com/matterfi/name_oracle.git")
set(MATTERFI_NAME_ORACLE_COMMIT "1cb476f695e8e3f1943340ba2f298226cda3e67a")
set(SOURCE_PATH "${DOWNLOADS}/matterfi-name-oracle.git")
set(MATTERFI_NAME_ORACLE_VERSION_STRING "26.9.2-0-g1cb476f")

find_program(GIT git git.cmd NO_CMAKE_FIND_ROOT_PATH)

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
    "${MATTERFI_NAME_ORACLE_REPO}"
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
    "${MATTERFI_NAME_ORACLE_REPO}"
    "${SOURCE_PATH}"
  )
endif()

vcpkg_execute_in_download_mode(
  COMMAND
  "${GIT}"
  -C
  "${SOURCE_PATH}"
  fetch --all --tags
)
vcpkg_execute_in_download_mode(
  COMMAND
  "${GIT}"
  -C
  "${SOURCE_PATH}"
  reset
  --hard
  "${MATTERFI_NAME_ORACLE_COMMIT}"
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

vcpkg_cmake_configure(
  SOURCE_PATH
  "${SOURCE_PATH}"
  DISABLE_PARALLEL_CONFIGURE
  OPTIONS
  -Dmatterfi_name_oracle_GIT_VERSION=${MATTERFI_NAME_ORACLE_VERSION_STRING}
  -DNAME_ORACLE_CMAKE_INSTALL_PATH=share/matterfi_name_oracle
  -DNAME_ORACLE_PEDANTIC_BUILD=OFF
  -DNAME_ORACLE_BUILD_TESTS=OFF
  -DNAME_ORACLE_BUILD_CORE=OFF
  -DNAME_ORACLE_BUILD_CREDITCARD=OFF
  -DNAME_ORACLE_BUILD_LIB=ON
  OPTIONS_RELEASE
  -DNAME_ORACLE_INSTALL_HEADERS=ON
  OPTIONS_DEBUG
  -DNAME_ORACLE_INSTALL_HEADERS=OFF
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(PACKAGE_NAME matterfi_name_oracle)

file(
  INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)
