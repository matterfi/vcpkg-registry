# Linux builds need system libatspi2.0-dev and pkg-config for libcput's AT-SPI probe.
vcpkg_from_git(
  OUT_SOURCE_PATH SOURCE_PATH
  URL https://github.com/matterfi/libcput.git
  REF d74b6d7d553c330a9561c28173b3251fd280e6d9
  HEAD_REF main
)

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    -DBUILD_TESTING=OFF
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME libcput CONFIG_PATH lib/cmake/libcput)

file(
  REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
