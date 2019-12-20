# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

if(MSVC)
    set(CMAKE_C_FLAGS           "/W3 /WX")
    set(CMAKE_C_FLAGS_RELEASE   "/MD /O2 /Ob2")
else()
    set(CMAKE_C_FLAGS           "-std=c99 -pedantic -Werror -Wall -Wextra -fPIC")
    set(CMAKE_C_FLAGS_RELEASE   "-O2")
endif()
include(CTest)

if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/tests)
    add_custom_target(${PROJECT_NAME}_copy_tests ALL COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_CURRENT_SOURCE_DIR}/tests
            ${CMAKE_CURRENT_BINARY_DIR})
endif()

if(COPY_TEST_MAXMINDDB)
    add_custom_target(${MODULE_NAME}_copy_test_maxminddb_city ALL COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_SOURCE_DIR}/maxminddb/tests/GeoIP2-City-Test.mmdb
        ${CMAKE_CURRENT_BINARY_DIR}/GeoIP2-City-Test.mmdb)
    add_custom_target(${MODULE_NAME}_copy_test_maxminddb_isp ALL COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_SOURCE_DIR}/maxminddb/tests/GeoIP2-ISP-Test.mmdb
	${CMAKE_CURRENT_BINARY_DIR}/GeoIP2-ISP-Test.mmdb)
endif()

include_directories(${CMAKE_BINARY_DIR})
if(LUA51) # build against installed lua 5.1
    find_program(LUA NAMES lua lua.bat)
    add_test(NAME ${PROJECT_NAME}_test COMMAND ${LUA} test.lua)
    set_property(TEST ${PROJECT_NAME}_test PROPERTY ENVIRONMENT
    "LUA_PATH=${TEST_MODULE_PATH}" "LUA_CPATH=${TEST_MODULE_CPATH}" TZ=UTC
    )
else() # lua_sandbox build
    add_executable(${PROJECT_NAME}_test_sandbox test_sandbox.c)
    target_link_libraries(${PROJECT_NAME}_test_sandbox ${LUASANDBOX_TEST_LIBRARY} ${LUASANDBOX_LIBRARIES})
    add_test(NAME ${PROJECT_NAME}_test_sandbox COMMAND ${PROJECT_NAME}_test_sandbox)
endif()
