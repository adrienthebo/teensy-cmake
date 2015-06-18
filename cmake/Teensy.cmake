# Copyright (c) 2015, Pierre-Andre Saulais <pasaulais@free.fr>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set(TEENSY_C_CORE_FILES
    ${TEENSY_ROOT}/math_helper.c
    ${TEENSY_ROOT}/analog.c
    ${TEENSY_ROOT}/serial1.c
    ${TEENSY_ROOT}/serial2.c
    ${TEENSY_ROOT}/serial3.c
    ${TEENSY_ROOT}/usb_mem.c
    ${TEENSY_ROOT}/usb_dev.c
    ${TEENSY_ROOT}/usb_midi.c
    ${TEENSY_ROOT}/usb_mouse.c
    ${TEENSY_ROOT}/usb_desc.c
    ${TEENSY_ROOT}/usb_keyboard.c
    ${TEENSY_ROOT}/usb_joystick.c
    ${TEENSY_ROOT}/usb_rawhid.c
    ${TEENSY_ROOT}/usb_seremu.c
    ${TEENSY_ROOT}/usb_serial.c
    ${TEENSY_ROOT}/mk20dx128.c
    ${TEENSY_ROOT}/touch.c
    ${TEENSY_ROOT}/pins_teensy.c
    ${TEENSY_ROOT}/keylayouts.c
    ${TEENSY_ROOT}/nonstd.c
    ${TEENSY_ROOT}/eeprom.c
)

set(TEENSY_CXX_CORE_FILES
    ${TEENSY_ROOT}/main.cpp
    ${TEENSY_ROOT}/usb_inst.cpp
    ${TEENSY_ROOT}/yield.cpp
    ${TEENSY_ROOT}/HardwareSerial1.cpp
    ${TEENSY_ROOT}/HardwareSerial2.cpp
    ${TEENSY_ROOT}/HardwareSerial3.cpp
    ${TEENSY_ROOT}/WMath.cpp
    ${TEENSY_ROOT}/Print.cpp

    ${TEENSY_ROOT}/new.cpp
    ${TEENSY_ROOT}/usb_flightsim.cpp
    ${TEENSY_ROOT}/avr_emulation.cpp
    ${TEENSY_ROOT}/IPAddress.cpp
    ${TEENSY_ROOT}/Stream.cpp
    ${TEENSY_ROOT}/Tone.cpp
    ${TEENSY_ROOT}/IntervalTimer.cpp
    ${TEENSY_ROOT}/DMAChannel.cpp
    ${TEENSY_ROOT}/AudioStream.cpp
    ${TEENSY_ROOT}/WString.cpp
)

function(add_teensy_core TARGET_NAME)
    add_library(${TARGET_NAME}
        ${TEENSY_C_CORE_FILES}
        ${TEENSY_CXX_CORE_FILES}
    )

    set(USB_MODE_DEF USB_SERIAL)
    set(TARGET_FLAGS "-D${USB_MODE_DEF} -DF_CPU=${TEENSY_FREQUENCY}000000 ${TEENSY_FLAGS}")

    set_source_files_properties(${TEENSY_C_CORE_FILES}
        PROPERTIES COMPILE_FLAGS ${TARGET_FLAGS})
    set_source_files_properties(${TEENSY_CXX_CORE_FILES}
        PROPERTIES COMPILE_FLAGS ${TARGET_FLAGS})
endfunction()

function(add_teensy_core_library TARGET_NAME)
    add_teensy_core(${TARGET_NAME}_TeensyCor)
endfunction()

function(add_teensy_executable TARGET_NAME)
    # Determine the target flags for this executable.

    set(USB_MODE_DEF USB_SERIAL)
    set(TARGET_FLAGS "-D${USB_MODE_DEF} -DF_CPU=${TEENSY_FREQUENCY}000000 ${TEENSY_FLAGS}")

    # Build the ELF executable.
    add_executable(${TARGET_NAME} ${ARGN})
    set_source_files_properties(${ARGN}
        PROPERTIES COMPILE_FLAGS ${TARGET_FLAGS})
    set_target_properties(${TARGET_NAME} PROPERTIES
        OUTPUT_NAME ${TARGET_NAME}
        SUFFIX ".elf"
    )

    set(TARGET_ELF "${TARGET_NAME}.elf")

    # Generate the hex firmware files that can be flashed to the MCU.
    set(EEPROM_OPTS -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0)
    set(HEX_OPTS -O ihex -R .eeprom)

    add_custom_command(OUTPUT ${TARGET_ELF}.eep
                       COMMAND ${CMAKE_OBJCOPY} ${EEPROM_OPTS} ${TARGET_ELF} ${TARGET_ELF}.eep
                       DEPENDS ${TARGET_NAME})

    add_custom_command(OUTPUT ${TARGET_ELF}.hex
                       COMMAND ${CMAKE_OBJCOPY} ${HEX_OPTS} ${TARGET_ELF} ${TARGET_ELF}.hex
                       DEPENDS ${TARGET_NAME})

    add_custom_target(${TARGET_NAME}_Firmware ALL
                      DEPENDS ${TARGET_ELF}.eep ${TARGET_ELF}.hex)

    add_dependencies(${TARGET_NAME}_Firmware ${TARGET_NAME})

endfunction(add_teensy_executable)

macro(import_arduino_library LIB_NAME)
    # Check if we can find the library.
    if(NOT EXISTS ${ARDUINO_LIB_ROOT})
        message(FATAL_ERROR "Could not find the Arduino library directory")
    endif(NOT EXISTS ${ARDUINO_LIB_ROOT})
    set(LIB_DIR "${ARDUINO_LIB_ROOT}/${LIB_NAME}")
    if(NOT EXISTS "${LIB_DIR}")
        message(FATAL_ERROR "Could not find the directory for library '${LIB_NAME}'")
    endif(NOT EXISTS "${LIB_DIR}")

    # Add it to the include path.
    include_directories("${LIB_DIR}")

    # Mark source files to be built along with the sketch code.
    file(GLOB SOURCES_CPP ABSOLUTE "${LIB_DIR}" "${LIB_DIR}/*.cpp")
    foreach(SOURCE_CPP ${SOURCES_CPP})
        set(TEENSY_LIB_SOURCES ${TEENSY_LIB_SOURCES} ${SOURCE_CPP})
    endforeach(SOURCE_CPP ${SOURCES_CPP})
    file(GLOB SOURCES_C ABSOLUTE "${LIB_DIR}" "${LIB_DIR}/*.c")
    foreach(SOURCE_C ${SOURCES_C})
        set(TEENSY_LIB_SOURCES ${TEENSY_LIB_SOURCES} ${SOURCE_C})
    endforeach(SOURCE_C ${SOURCES_C})
endmacro(import_arduino_library)

macro(_add_sketch_internal SKETCH_DIR SKETCH)
    set(SKETCH_SOURCE_INO "${SKETCH_DIR}/${SKETCH}/${SKETCH}.ino")
    set(SKETCH_SOURCE_PDE "${SKETCH_DIR}/${SKETCH}/${SKETCH}.pde")
    get_filename_component(SKETCH_DIR_NAME ${SKETCH_DIR} NAME)
    set(SKETCH_TARGET_NAME ${SKETCH})
    if(NOT ${SKETCH_DIR_NAME} STREQUAL "sketches")
        set(SKETCH_TARGET_NAME "${SKETCH_DIR_NAME}_${SKETCH_TARGET_NAME}")
    endif()
    if(EXISTS ${SKETCH_SOURCE_INO})
        add_teensy_executable(${SKETCH_TARGET_NAME} ${SKETCH_SOURCE_INO})
    elseif(EXISTS ${SKETCH_SOURCE_PDE})
        add_teensy_executable(${SKETCH_TARGET_NAME} ${SKETCH_SOURCE_PDE})
    endif()
endmacro(_add_sketch_internal)

# Create a target for every Arduino sketch file in sub-directories.
macro(add_sketches)
    set(SKETCH_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    file(GLOB SKETCHES RELATIVE ${SKETCH_DIR} ${SKETCH_DIR}/*)
    foreach(SKETCH ${SKETCHES})
        set(SKETCH_CONFIG "${SKETCH_DIR}/${SKETCH}/CMakeLists.txt")
        if(EXISTS ${SKETCH_CONFIG})
            # If there is a CMakeLists.txt file in the sketch's directory,
            # it is probably configuration settings. Include it.
            subdirs("${SKETCH_DIR}/${SKETCH}")
        else()
            _add_sketch_internal(${SKETCH_DIR} ${SKETCH})
        endif()
    endforeach()
endmacro()

# Create a target for the sketch in the current directory.
macro(add_sketch)
    get_filename_component(SKETCH "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
    get_filename_component(SKETCH_DIR "${CMAKE_CURRENT_SOURCE_DIR}" DIRECTORY)
    _add_sketch_internal(${SKETCH_DIR} ${SKETCH})
endmacro()
