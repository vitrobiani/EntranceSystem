#ifndef SESSION_STATE
#define SESSION_STATE
#include <LiquidCrystal.h>
#include <Servo.h>
#include <MFRC522.h>
#include "access.h"
#include "pitches.h"

class SessionState {
public:
    MFRC522 mfrc522;
    LiquidCrystal lcd;
    Servo servo;
    bool isOpen = false;

    SessionState(MFRC522 mfrc522, LiquidCrystal lcd, Servo servo);
    SessionState();

    cardRet cardDetails();
    void print(String str, int line);
    void print(String str1, String str2);
    void unlock();
    void reject();
    void rejectSound();
    void acceptSound();

};

#endif
