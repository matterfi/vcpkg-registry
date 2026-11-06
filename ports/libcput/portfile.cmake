# Linux builds need system libatspi2.0-dev and pkg-config for libcput's AT-SPI probe.
vcpkg_from_git(
  OUT_SOURCE_PATH SOURCE_PATH
  URL ssh://git@github.com/matterfi/libcput.git
  REF 143300c73f47e81a0905840d071f7f85bbdb2c4a
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
file(
  WRITE
  "${CURRENT_PACKAGES_DIR}/share/libcput/LIBCPUT_SHA.txt"
  "143300c73f47e81a0905840d071f7f85bbdb2c4a\n"
)
