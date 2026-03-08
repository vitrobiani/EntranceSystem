#include "SessionState.h"


SessionState::SessionState(MFRC522 mfrc522, LiquidCrystal lcd, Servo servo):
  lcd(lcd), mfrc522(mfrc522), servo(servo) {};

cardRet SessionState::cardDetails() {
  // Reset the loop if no new card present on the sensor/reader. This saves the entire process when idle.
  if ( ! mfrc522.PICC_IsNewCardPresent()) {
    return NO_CARD;
  }

  // Select one of the cards
  if ( ! mfrc522.PICC_ReadCardSerial()) {
    return NO_CARD;
  }

  if(doesAccessListContain(mfrc522.uid.uidByte)) {
      return CARD_ACCEPT;
  }
  return CARD_DECLINE;
}

void SessionState::print(String str, int line = 0) {
    lcd.clear();
    lcd.setCursor(0, line);
    lcd.print(str);
}

void SessionState::print(String str1, String str2) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(str1);
    lcd.setCursor(0, 1);
    lcd.print(str2);
}

void SessionState::unlock() {
    acceptSound();
    if (isOpen) {
        print("Closing...");
        servo.write(0);
        isOpen = false;
    }
    servo.write(90);
    lcd.clear();
    print("Access Granted!", "Lock Open");
    isOpen = true;
}

void SessionState::reject() {
    rejectSound();
    print("Access Denied!");
    if (isOpen) {
        print("Access Denied!", "Lock Closed");
        servo.write(0);
        isOpen = false;
    }
}

void SessionState::rejectSound() {
  tone(BUZZER_PIN, NOTE_G5);
  delay(50);
  tone(BUZZER_PIN, NOTE_C5);
  delay(50);
  noTone(BUZZER_PIN);
}

void SessionState::acceptSound() {
  tone(BUZZER_PIN, NOTE_C5);
  delay(50);
  tone(BUZZER_PIN, NOTE_G5);
  delay(50);
  noTone(BUZZER_PIN);
}

