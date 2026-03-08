#include <SPI.h>
#include "SessionState.h"
#include "access.h"


MFRC522 mfrc522(SS_PIN, RST_PIN);  // Create MFRC522 instance
LiquidCrystal lcd(
    LCD_RS_PIN, LCD_ENABLE_PIN, LCD_D4_PIN, LCD_D5_PIN, LCD_D6_PIN, LCD_D7_PIN
  );
Servo servo;

SessionState session(mfrc522, lcd, servo);

void setup() {
  Serial.begin(9600);
	SPI.begin();
	session.mfrc522.PCD_Init();
	delay(5);
  session.lcd.begin(16, 2);
  session.servo.attach(SERVO_PIN);
  session.servo.write(0); // Set the servo position
  pinMode(BUZZER_PIN, OUTPUT);
}

String hexArrToString(byte b[4]) {
  String str;
  for (int i = 0; i < 4 ; i++ ) {
    String s = hexToString(b[i]);
    str += s;
    if (i != 3) {
      str += String(":");
    }
  }
  return str;
}

void loop() {
  cardRet ret = session.cardDetails();
  if (ret == CARD_ACCEPT) {
    session.unlock();
    String str = String("CARD_ACCEPT - ") + hexArrToString(session.mfrc522.uid.uidByte) + String('\n');
    Serial.write(str.c_str());
  } else if (ret == CARD_DECLINE) {
    session.reject();
    String str = String("CARD_DECLINE - ") + hexArrToString(session.mfrc522.uid.uidByte) + String('\n');
    Serial.write(str.c_str());
  } else {
  }
  delay(300);
}

