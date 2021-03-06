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
endfunction()

function(add_teensy_library TARGET_NAME)
    add_library(${TARGET_NAME} ${ARGN})
    set_source_files_properties(${ARGN} PROPERTIES COMPILE_FLAGS "-include Arduino.h")
endfunction()

function(add_teensy_executable TARGET_NAME)

    # Build the ELF executable.
    add_executable(${TARGET_NAME} ${ARGN})
    set_target_properties(${TARGET_NAME} PROPERTIES
        OUTPUT_NAME ${TARGET_NAME}
        SUFFIX ".elf"
    )
    set_source_files_properties(${ARGN} PROPERTIES COMPILE_FLAGS "-include Arduino.h")

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
endfunction()
