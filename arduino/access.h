#ifndef ACCESS
#define ACCESS
#include "defines.h"
#include "Arduino.h"
#include <MFRC522.h>

enum cardRet {
  NO_CARD, CARD_DECLINE, CARD_ACCEPT, numOfCardRets
};
extern String cardOutputs[numOfCardRets];

extern byte accessGranted[1][4];
extern int accessGrantedLength;

bool doesAccessListContain(byte uid[4]);
String hexToString(byte b);

#endif 

