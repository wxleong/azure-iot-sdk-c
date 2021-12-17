#Copyright (c) Microsoft. All rights reserved.
#Licensed under the MIT license. See LICENSE file in the project root for full license information.

cmake_minimum_required (VERSION 3.5)

compileAsC99()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSE_PROV_MODULE")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSE_PROV_MODULE")

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/deps)

set(provisioning_libs)
set(provisioning_headers)

set(AUTH_CLIENT_H_FILES
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_auth_client.h
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_security_factory.h
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/iothub_auth_client.h
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_auth_client.h
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/iothub_security_factory.h
    )

set(AUTH_CLIENT_C_FILES
    ${CMAKE_CURRENT_LIST_DIR}/src/prov_auth_client.c
    ${CMAKE_CURRENT_LIST_DIR}/src/prov_security_factory.c
    ${CMAKE_CURRENT_LIST_DIR}/src/iothub_auth_client.c
    ${CMAKE_CURRENT_LIST_DIR}/src/iothub_security_factory.c)


set(HSM_CLIENT_H_FILES
    ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_data.h)
set(HSM_CLIENT_C_FILES
    ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_data.c)

if (${hsm_type_custom})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHSM_AUTH_TYPE_CUSTOM")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHSM_AUTH_TYPE_CUSTOM")
elseif (${use_prov_client})
    if (${hsm_type_x509})
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHSM_TYPE_X509")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHSM_TYPE_X509")
    endif()
    if (${hsm_type_sastoken})
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHSM_TYPE_SAS_TOKEN")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHSM_TYPE_SAS_TOKEN")

        if (${use_tpm_simulator})
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSE_EMULATOR_MODULE")
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSE_EMULATOR_MODULE")
        endif()
    endif()
    if (${hsm_type_symm_key})
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHSM_TYPE_SYMM_KEY")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHSM_TYPE_SYMM_KEY")
    endif()
endif()

##### Set Include directories for RIoT #####
if (${use_prov_client})
    if (${run_e2e_tests})
        # For e2e test we need to run a custom HSM to handle testing
        # TODO: Remove once utpm CMake is updated
        include_directories(${TPM_C_INC_FOLDER})

        # Include the riot directories
        include_directories(${CMAKE_CURRENT_LIST_DIR}/deps/RIoT/Simulation/DICE)
        include_directories(${CMAKE_CURRENT_LIST_DIR}/deps/RIoT/Simulation/RIoT/Core)
        include_directories(${CMAKE_CURRENT_LIST_DIR}/deps/RIoT/Simulation/RIoT/Core/RIoTCrypt/include)

        # For e2e test a custom HSM is needed
        add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/tests/common_prov_e2e/prov_hsm)

        set(HSM_CLIENT_LIBRARY ${HSM_CLIENT_LIBRARY} msr_riot utpm prov_hsm)
        if (WIN32)
            set(HSM_CLIENT_LIBRARY ${HSM_CLIENT_LIBRARY} Tbs)
        endif ()
    else ()
        if (${hsm_type_x509})
            # Using x509
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHSM_TYPE_X509")
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHSM_TYPE_X509")

            set(HSM_CLIENT_H_FILES ${HSM_CLIENT_H_FILES}
                ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_riot.h)
            set(HSM_CLIENT_C_FILES ${HSM_CLIENT_C_FILES}
                ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_riot.c)

            # Include the riot directories
            include_directories(${CMAKE_CURRENT_LIST_DIR}/deps/RIoT/Simulation/DICE)
            include_directories(${CMAKE_CURRENT_LIST_DIR}/deps/RIoT/Simulation/RIoT/Core)
            include_directories(${CMAKE_CURRENT_LIST_DIR}/deps/RIoT/Simulation/RIoT/Core/RIoTCrypt/include)

            set(HSM_CLIENT_LIBRARY ${HSM_CLIENT_LIBRARY} msr_riot)
        endif()

        if (${hsm_type_sastoken})
            # Using Sas Token
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHSM_TYPE_SAS_TOKEN")
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHSM_TYPE_SAS_TOKEN")

            set(HSM_CLIENT_H_FILES ${HSM_CLIENT_H_FILES}
                ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_tpm.h)
            set(HSM_CLIENT_C_FILES ${HSM_CLIENT_C_FILES}
                ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_tpm.c)

            if (${use_tpm_simulator})
                set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DUSE_EMULATOR_MODULE")
                set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSE_EMULATOR_MODULE")
            endif()

            include_directories(${TPM_C_INC_FOLDER})
        endif ()

        if (${hsm_type_symm_key})
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHSM_TYPE_SYMM_KEY")
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHSM_TYPE_SYMM_KEY")

            set(HSM_CLIENT_H_FILES ${HSM_CLIENT_H_FILES} 
                ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_key.h)
            set(HSM_CLIENT_C_FILES ${HSM_CLIENT_C_FILES} 
                ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_key.c)
        endif()
    endif ()
endif ()

if (${hsm_type_edge_module})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHSM_TYPE_HTTP_EDGE")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHSM_TYPE_HTTP_EDGE")

    set(HSM_CLIENT_H_FILES ${HSM_CLIENT_H_FILES}
        ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_http_edge.h)
    set(HSM_CLIENT_C_FILES ${HSM_CLIENT_C_FILES}
        ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_http_edge.c)

    set(HSM_CLIENT_LIBRARY ${HSM_CLIENT_LIBRARY} uhttp)
endif()

# Create the HSM security client
add_library(hsm_security_client
    ${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_data.c
    $<$<BOOL:${hsm_type_edge_module}>:${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_http_edge.c>
    $<$<BOOL:${hsm_type_symm_key}>:${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_key.c>
    $<$<BOOL:${hsm_type_sastoken}>:${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_tpm.c>
    $<$<BOOL:${hsm_type_x509}>:${CMAKE_CURRENT_LIST_DIR}/adapters/hsm_client_riot.c>
)

applyXcodeBuildFlagsIfNeeded(hsm_security_client)

# Install target and set target include directory
install(TARGETS hsm_security_client
    EXPORT azure_prov_sdkTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/azureiot
)

set(PROV_DEVICE_CLIENT_SOURCE_C_FILES
    ${CMAKE_CURRENT_LIST_DIR}/src/prov_device_client.c)

set(PROV_DEVICE_CLIENT_SOURCE_H_FILES
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_client_const.h
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_device_client.h)

set(PROV_DEVICE_LL_CLIENT_SOURCE_C_FILES
    ${CMAKE_CURRENT_LIST_DIR}/src/prov_device_ll_client.c)

set(PROV_DEVICE_LL_CLEINT_SOURCE_H_FILES
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_client_const.h
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_device_ll_client.h)

# Create the provisioning auth client
add_library(prov_auth_client
    ${CMAKE_CURRENT_LIST_DIR}/src/prov_auth_client.c
    ${CMAKE_CURRENT_LIST_DIR}/src/prov_security_factory.c
    ${CMAKE_CURRENT_LIST_DIR}/src/iothub_auth_client.c
    ${CMAKE_CURRENT_LIST_DIR}/src/iothub_security_factory.c
)
target_include_directories(prov_auth_client
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/inc>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/azureiot>
)
target_link_libraries(prov_auth_client
    PUBLIC
        aziotsharedutil
        hsm_security_client
)

applyXcodeBuildFlagsIfNeeded(prov_auth_client)

# Install public header files
install(FILES
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/iothub_security_factory.h
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_security_factory.h
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/azure_prov_client
)
# Install private header files
install(FILES
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/iothub_auth_client.h
    ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_auth_client.h
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/azure_prov_client/internal
)
# Install target and set target include directory
install(TARGETS prov_auth_client
    EXPORT azure_prov_sdkTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/azureiot
)

##################################################################################

if(${use_prov_client} OR (${use_prov_client_core} AND ${run_e2e_tests}))

    ######################### Provisioning LL Client #########################
    add_library(prov_device_ll_client
        ${CMAKE_CURRENT_LIST_DIR}/src/prov_device_ll_client.c
    )
    target_include_directories(prov_device_ll_client
        PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/inc>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )
endif()

set(provisioning_headers ${provisioning_headers} ${HSM_CLIENT_H_FILES})
set(provisioning_libs ${provisioning_libs} prov_auth_client)
set(provisioning_headers ${provisioning_headers} ${AUTH_CLIENT_H_FILES})

if(${use_prov_client} OR (${use_prov_client_core} AND ${run_e2e_tests}))
    add_library(prov_device_client ${PROV_DEVICE_CLIENT_SOURCE_C_FILES} ${PROV_DEVICE_CLIENT_SOURCE_H_FILES})
    applyXcodeBuildFlagsIfNeeded(prov_device_client)
    set(provisioning_libs ${provisioning_libs} prov_device_client)
    set(provisioning_headers ${provisioning_headers} ${PROV_DEVICE_CLIENT_SOURCE_H_FILES})

    applyXcodeBuildFlagsIfNeeded(prov_device_client)
    target_link_libraries(prov_device_client
        PUBLIC
            prov_device_ll_client
            parson
    )

    if (${build_as_dynamic})
        add_library(prov_device_client_dll SHARED
            ${PROV_DEVICE_CLIENT_SOURCE_C_FILES}
            ${PROV_DEVICE_CLEINT_SOURCE_H_FILES}
            ${PROV_DEVICE_LL_CLIENT_SOURCE_C_FILES}
            ${PROV_DEVICE_LL_CLEINT_SOURCE_H_FILES}
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_device_client_dll.def
        )
        linkSharedUtil(prov_device_client_dll)
        target_link_libraries(prov_device_client_dll prov_device_ll_client parson)

        if(NOT WIN32)
            set_target_properties(prov_device_client_dll PROPERTIES OUTPUT_NAME "prov_device_client")
        endif()
        set_target_properties(prov_device_client_dll PROPERTIES
            OUTPUT_NAME "prov_device_client"
            ARCHIVE_OUTPUT_NAME "prov_device_client_dll_import"
            ENABLE_EXPORTS YES
            PDB_NAME "prov_device_client_dll"
            VERSION ${PROV_SDK_VERSION}
            SOVERSION ${PROV_SDK_VERSION_MAJOR}
            BUILD_WITH_INSTALL_RPATH TRUE
        )
        if (${CMAKE_C_COMPILER_ID} STREQUAL "GNU" OR ${CMAKE_C_COMPILER_ID} STREQUAL "Clang")
            target_link_libraries(prov_device_client_dll
                "-Wl,--exclude-libs,libparson.a"
            )
        endif()
        install(TARGETS prov_device_client_dll
            EXPORT azure_prov_sdkTargets
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )
    endif()

    if (${use_http})
        set(PROV_HTTP_CLIENT_H_FILES
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_transport.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_transport_private.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_transport_http_client.h)
        set(PROV_HTTP_CLIENT_C_FILES
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_http_client.c)

        # Provisioning http Transport Client library
        add_library(prov_http_transport ${PROV_HTTP_CLIENT_C_FILES} ${PROV_HTTP_CLIENT_H_FILES})
        applyXcodeBuildFlagsIfNeeded(prov_http_transport)
        linkSharedUtil(prov_http_transport)
        set(provisioning_libs ${provisioning_libs} prov_http_transport)
        set(provisioning_headers ${provisioning_headers} ${PROV_HTTP_CLIENT_H_FILES})

        target_link_libraries(prov_http_transport uhttp)
    endif()

    if (${use_amqp})
        ######################### Provisioning AMQP Transport #########################
        include_directories(${UAMQP_INCLUDES} ${UAMQP_INC_FOLDER})
        # Provisioning AMQP Websocket transport library
        add_library(prov_amqp_ws_transport
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_amqp_ws_client.c
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_amqp_common.c
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_sasl_tpm.c
        )

        applyXcodeBuildFlagsIfNeeded(prov_amqp_ws_transport)

        target_link_libraries(prov_amqp_ws_transport
            PUBLIC
                uamqp
                aziotsharedutil
        )
        target_include_directories(prov_amqp_ws_transport
            PUBLIC
                $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/inc>
                $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/azureiot>
        )

        # Provisioning AMQP transport library
        add_library(prov_amqp_transport
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_amqp_client.c
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_amqp_common.c
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_sasl_tpm.c
        )

        applyXcodeBuildFlagsIfNeeded(prov_amqp_transport)

        target_link_libraries(prov_amqp_transport
            PUBLIC
                uamqp
                aziotsharedutil
        )

        target_include_directories(prov_amqp_transport
            PUBLIC
                $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/inc>
                $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/azureiot>
        )

        set(PROV_AMQP_CLIENT_H_FILES
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_transport.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_transport_amqp_client.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_transport_amqp_common.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_transport_private.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_sasl_tpm.h)
        set(PROV_AMQP_CLIENT_C_FILES
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_amqp_client.c
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_amqp_common.c
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_sasl_tpm.c)

        set(PROV_AMQP_WS_CLIENT_H_FILES
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_transport.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_transport_amqp_ws_client.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_transport_amqp_common.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_transport_private.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_sasl_tpm.h)
        set(PROV_AMQP_WS_CLIENT_C_FILES
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_amqp_ws_client.c
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_amqp_common.c
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_sasl_tpm.c)
        set(provisioning_headers ${provisioning_headers} ${PROV_AMQP_WS_CLIENT_H_FILES})

        set(provisioning_headers ${provisioning_headers} ${PROV_AMQP_CLIENT_H_FILES})
    endif()

    if (${use_mqtt})
        ######################### Provisioning MQTT Transport #########################
        include_directories(${MQTT_INC_FOLDER})

        set(PROV_MQTT_CLIENT_H_FILES
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_transport.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_transport_mqtt_client.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_transport_private.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_transport_mqtt_common.h)
        set(PROV_MQTT_CLIENT_C_FILES
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_mqtt_client.c
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_mqtt_common.c)

        set(PROV_MQTT_WS_CLIENT_H_FILES
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_transport.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/prov_transport_mqtt_ws_client.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_transport_private.h
            ${CMAKE_CURRENT_LIST_DIR}/inc/azure_prov_client/internal/prov_transport_mqtt_common.h)
        set(PROV_MQTT_WS_CLIENT_C_FILES
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_mqtt_ws_client.c
            ${CMAKE_CURRENT_LIST_DIR}/src/prov_transport_mqtt_common.c)

        add_library(prov_mqtt_ws_transport ${PROV_MQTT_WS_CLIENT_C_FILES} ${PROV_MQTT_WS_CLIENT_H_FILES})
        applyXcodeBuildFlagsIfNeeded(prov_mqtt_ws_transport)
        linkSharedUtil(prov_mqtt_ws_transport)
        target_link_libraries(prov_mqtt_ws_transport umqtt)
        set(provisioning_libs ${provisioning_libs} prov_mqtt_ws_transport)
        set(provisioning_headers ${provisioning_headers} ${PROV_MQTT_WS_CLIENT_H_FILES})

        # Provisioning mqtt Transport Client library
        add_library(prov_mqtt_transport ${PROV_MQTT_CLIENT_C_FILES} ${PROV_MQTT_CLIENT_H_FILES})
        applyXcodeBuildFlagsIfNeeded(prov_mqtt_transport)
        linkSharedUtil(prov_mqtt_transport)
        target_link_libraries(prov_mqtt_transport umqtt)
        set(provisioning_libs ${provisioning_libs} prov_mqtt_transport)
        set(provisioning_headers ${provisioning_headers} ${PROV_MQTT_CLIENT_H_FILES})
    endif()
endif()

if(NOT IN_OPENWRT)
    # Disable tests for OpenWRT
    add_subdirectory(tests)
endif()

if (${use_prov_client} AND (NOT ${skip_samples}))
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/samples)
    add_subdirectory(tools)
endif ()

install(
    EXPORT azure_prov_sdkTargets
    FILE "azure_prov_sdkTargets.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/azure_prov_sdk"
)

if(${use_installed_dependencies})

    # Install Provisioning libs
    set(package_location "${CMAKE_INSTALL_LIBDIR}/cmake/azure_prov_sdk")

    install(FILES ${provisioning_headers} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/azure_prov_client)

    include(CMakePackageConfigHelpers)

    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${PROJECT_NAME}ConfigVersion.cmake"
        VERSION ${PROV_SDK_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    configure_file("../configs/${PROJECT_NAME}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${PROJECT_NAME}Config.cmake"
        COPYONLY
    )

    # install(EXPORT azure_prov_sdksTargets
    #     FILE
    #         "${PROJECT_NAME}Targets.cmake"
    #     DESTINATION
    #         ${package_location}
    # )

    install(
        FILES
            "../configs/${PROJECT_NAME}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${PROJECT_NAME}ConfigVersion.cmake"
        DESTINATION
            ${package_location}
    )
else()
    # Install Provisioning libs
    if(NOT DEFINED CMAKE_INSTALL_LIBDIR)
        set(CMAKE_INSTALL_LIBDIR "lib")
    endif()
endif()