#pragma once
#ifndef _Configuration_h
#define _Configuration_h

//Other Configuration values
#define XBEE_BUAD_RATE 9600
#define HARD_SERIAL_BUAD_RATE 250000
#define NULL -0 //TODO: think about this value?
#define MAX_BUFFER_SIZE 80 //need to be based on a protocol we choose
#define ARDUINO_DEBUG_LED LED_BUILTIN //this is the onboard LED and for testing use only

#define MSG_HEADER_SPEED "S"
#define MSG_FOOTER_SPEED "D"
#define MSG_HEADER_CC_STATUS "C"
#define MSG_FOOTER_CC_STATUS "C"
#define MSG_HEADER_CC_SPEED "C"
#define MSG_FOOTER_CC_SPEED "S"
#define MSG_HEADER_THROTTLE "T"
#define MSG_FOOTER_THROTTLE "T"
#define MSG_HEADER_LOGGING "L"
#define MSG_FOOTER_LOGGING "L"
#define MSG_HEADER_PID "P"
#define MSG_SEPERATOR "I"
#define MSG_FOOTER_PID "D"
#define MSG_HEADER_ERROR "E"
#define MSG_FOOTER_ERROR "R"
#define MSG_HEADER_CAR "C"
#define MSG_FOOTER_CAR "R"

//CAN Setup
#define CAN_MESSEGE_BUFFER_SIZE 9
#define TEST_MSG_ID  0x01

#define PREFIX_ENGINE_RPM(e) e
#define GET_ENGINE_RPM_PREFIX  PREFIX_ENGINE_RPM("e")

#define PREFIX_DUMMY_VALUE(d) #d
#define GET_DUMMY_VALUE_PERFIX  PREFIX_DUMMY_VALUE(dummy)


//Define all the neccesry IO pins from Arduino here
#define ARDUINO_RX_PIN 0
#define ARDUINO_TX_PIN 1
#define ARDUINO_UNO_SOFT_SERIAL_RX 7
#define ARDUINO_UNO_SOFT_SERIAL_TX 8
#define ARDUINO_MEGA_SOFT_SERIAL_RX 11
#define ARDUINO_MEGA_SOFT_SERIAL_TX 12
#define XBEE_RX_PIN 3
#define XBEE_TX_PIN 5

#define XBEECOMMANDBUFFER 6
#define MAXXBEECOMMANDS 10
#define MAXDELIMETER 2
typedef struct _callback {
char command[XBEECOMMANDBUFFER];
void(*function)();
}CommandCallBack;
#endif

