# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

if(MSVC)
    set(CMAKE_C_FLAGS           "/W3 /WX")
    set(CMAKE_C_FLAGS_RELEASE   "/MD /O2 /Ob2")
    set(CMAKE_CXX_FLAGS         "${CMAKE_C_FLAGS} /EHs")
    set(CMAKE_CXX_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})
else()
    set(CPACK_GENERATOR         "TGZ")
    set(CMAKE_C_FLAGS           "-std=c99 -pedantic -Werror -Wall -Wextra -fPIC")
    set(CMAKE_C_FLAGS_RELEASE   "-O2")
    set(CMAKE_CXX_FLAGS "-std=c++14 -pedantic -Werror -Wall -Wextra -fPIC -isystem /usr/local/include -isystem /opt/local/include")
    set(CMAKE_CXX_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})
    set(CMAKE_SHARED_LIBRARY_SUFFIX ".so")
endif()

add_definitions(-DDIST_VERSION="${PROJECT_VERSION}")
string(REPLACE "-" "_" MODULE_NAME ${PROJECT_NAME})

set(CPACK_INSTALL_CMAKE_PROJECTS "${CMAKE_CURRENT_BINARY_DIR};${MODULE_NAME};ALL;/")
set(CPACK_PACKAGE_NAME           luasandbox-${PROJECT_NAME})
set(CPACK_PACKAGE_VERSION_MAJOR  ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR  ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH  ${PROJECT_VERSION_PATCH})
set(CPACK_PACKAGE_VENDOR         "Mozilla Services")
set(CPACK_PACKAGE_CONTACT        "Mike Trinkala <trink@mozilla.com>")
set(CPACK_OUTPUT_CONFIG_FILE     "${CMAKE_BINARY_DIR}/${MODULE_NAME}.cpack")
set(CPACK_STRIP_FILES            TRUE)
set(CPACK_RESOURCE_FILE_LICENSE  "${CMAKE_SOURCE_DIR}/LICENSE.txt")
set(CPACK_RPM_PACKAGE_LICENSE    "MPLv2.0")

set(DPERMISSION DIRECTORY_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
set(SB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sandboxes)
if(IS_DIRECTORY ${SB_DIR})
    install(DIRECTORY ${SB_DIR}/ DESTINATION ${INSTALL_SANDBOX_PATH} ${DPERMISSION})
endif()

set(MODULE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/modules)
if(IS_DIRECTORY ${MODULE_DIR})
    install(DIRECTORY ${MODULE_DIR}/ DESTINATION ${INSTALL_MODULE_PATH} ${DPERMISSION})
endif()

set(IOMODULE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/io_modules)
if(IS_DIRECTORY ${IOMODULE_DIR})
    install(DIRECTORY ${IOMODULE_DIR}/ DESTINATION ${INSTALL_IOMODULE_PATH} ${DPERMISSION})
endif()

set(SCHEMA_DIR ${CMAKE_CURRENT_SOURCE_DIR}/schemas)
if(IS_DIRECTORY ${SCHEMA_DIR})
    install(DIRECTORY ${SCHEMA_DIR}/ DESTINATION ${INSTALL_SCHEMA_PATH} ${DPERMISSION})
endif()

if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/tests)
    add_custom_target(${MODULE_NAME}_copy_tests ALL COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/tests
        ${CMAKE_CURRENT_BINARY_DIR})
endif()

if(COPY_TEST_MAXMINDDB)
    add_custom_target(${MODULE_NAME}_copy_test_maxminddb ALL COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_SOURCE_DIR}/maxminddb/tests/GeoIP2-City-Test.mmdb
        ${CMAKE_CURRENT_BINARY_DIR}/GeoIP2-City-Test.mmdb)
    add_custom_target(${MODULE_NAME}_copy_test_maxminddb_isp ALL COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_SOURCE_DIR}/maxminddb/tests/GeoIP2-ISP-Test.mmdb
	${CMAKE_CURRENT_BINARY_DIR}/GeoIP2-ISP-Test.mmdb)
endif()

include_directories(${CMAKE_BINARY_DIR})
if(LUA51) # build against the installed Lua 5.1
    set(CPACK_PACKAGE_NAME "lua51-${PROJECT_NAME}")
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/modules)
      find_program(LUA NAMES lua lua.bat)
      if(TEST_CONFIGURATION)
          add_test(NAME ${MODULE_NAME}_test COMMAND ${LUA} test.lua CONFIGURATIONS ${TEST_CONFIGURATION})
      else()
          add_test(NAME ${MODULE_NAME}_test COMMAND ${LUA} test.lua)
      endif()
      set_property(TEST ${MODULE_NAME}_test PROPERTY ENVIRONMENT
      "LUA_PATH=${TEST_MODULE_PATH}" "LUA_CPATH=${TEST_MODULE_CPATH}" TZ=UTC
      )
    endif()
else() # build against the installed lua_sandbox
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/test_sandbox.c)
      add_executable(${MODULE_NAME}_test_sandbox test_sandbox.c)
      target_link_libraries(${MODULE_NAME}_test_sandbox ${LUASANDBOX_TEST_LIBRARY} ${LUASANDBOX_LIBRARIES})
      if(TEST_CONFIGURATION)
          add_test(NAME ${MODULE_NAME}_test_sandbox COMMAND ${MODULE_NAME}_test_sandbox CONFIGURATIONS ${TEST_CONFIGURATION})
      else()
          add_test(NAME ${MODULE_NAME}_test_sandbox COMMAND ${MODULE_NAME}_test_sandbox)
      endif()
    endif()
endif()

if(MODULE_SRCS)
    include_directories(${LUA_INCLUDE_DIR})
    add_library(${MODULE_NAME} SHARED ${MODULE_SRCS})
    if(MSVC)
      target_link_libraries(${MODULE_NAME} ${LUA_LIBRARIES})
    endif()
    set(EMPTY_DIR ${CMAKE_BINARY_DIR}/empty)
    file(MAKE_DIRECTORY ${EMPTY_DIR})
    install(DIRECTORY ${EMPTY_DIR}/ DESTINATION ${INSTALL_MODULE_PATH} ${DPERMISSION})
    install(TARGETS ${MODULE_NAME} DESTINATION ${INSTALL_MODULE_PATH})
endif()
include(CPack)
