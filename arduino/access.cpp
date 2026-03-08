#include "access.h"


String cardOutputs[numOfCardRets] = {
  "", "Access Granted!", "Access Denied!"
};

byte accessGranted[1][4] = {{0xD3, 0x30, 0xCE, 0x2C}};
int accessGrantedLength = 1;

bool doesAccessListContain(byte uid[4]) {
  bool broken = false;
  for (int c = 0; c < accessGrantedLength ; c++) {
    for(int i = 0; i < 4; i++){
      if (accessGranted[c][i] != uid[i]) {
        broken = true;
        break;
      }
    }
    if(broken) {
      broken = false;
    } else {
      return true;
    }
  }
  return false;
}

String hexToString(byte b) {
    String hex = "";
    char hexChars[] = "0123456789ABCDEF"; // Our lookup table
    
    // Higher nibble (the first hex digit)
    byte higher = (b >> 4) & 0x0F;
    // Lower nibble (the second hex digit)
    byte lower = b & 0x0F;
    
    hex += hexChars[higher];
    hex += hexChars[lower];
    
    return hex;
}
