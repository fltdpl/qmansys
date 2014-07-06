#include <math.h>
#include <WProgram.h>
#include "chipKITCan.h"

/********************************************
* Deklarationen fuer CAN (von Christopher) *
********************************************/
 
/* Lokale Typen und Defeintionen */
#define	KMS_Message_TX1	0x001L // CAN Knoten1 Schnittstelle1
#define Display_Message_TX1	0x002L // CAN Knoten2 Schnittstelle2

#define SYS_FREQ	(80000000L) // Frequenz
#define CAN_BUS_SPEED 500000	// Bus Speed

/* Globale Variablen */
CAN canMod1(CAN::CAN1); // Dieses Objekt benutzt Can Modul 1

/* Lokale Variablen */
uint8_t CAN1MessageFifoArea[2 * 8 * 16]; // CAN Nachrichten Buffer
static volatile bool isCAN1MsgReceived = false; // Interupt

/* Vorwärtsdeklarationen */
void initCan1(uint32_t myaddr);
void doCan1Interrupt();
void txCAN1(uint32_t rxnode);
void rxCAN1(void);
void doCan1Interrupt();



/**********************************************
* Deklarationen fuer Kuehlwassermanipulation *
**********************************************/

// Deklaration Interrupt: Schalter und entprellen
int button_start = 0; // Signalisieren, dass der Motor gestartet wird
int button_manuell = 0; // Manuell Start/Stopp
const unsigned int DEBOUNCE_TIME = 200; // Bouncezeit
unsigned long interrupt_time_1 = 0;
unsigned long interrupt_time_2 = 0;
static unsigned long last_interrupt_time_1 = 0;
static unsigned long last_interrupt_time_2 = 0;

// Deklarationen fuer Temperatureinlesen
int sens = 0; // Sensorwert für Temperatur (Spannung)
int T_KW = 0; // Temperatur Kuehlwasser
int T_B = 0; // Temperatur Boilerwasser

// Deklarationen fuer Zweipunktregler
int PumpenFlag = 0; // Pumpe An und Aus
int Heat = 0; // 1=Heizen, 0=Abkuehlen
int Tset = 80; // Sollwert der Boilertemperatur
float KH = 0.1; // Kopplungsfaktor

// Deklaration Relais
int Relaisstatus = 0; // Status des Relais bzw. Pumpe

// Deklaration Fehler
int Fehlercode = 0; // Fehlercode gibt verschiedene Fehler an (0=kein Fehler, 1= ...)

// Deklaration Vorheizen
int T_KW_set = 40;

// Deklaration Startphase
int Startphase = 1;
int VorheizenFlag = 0; // 0 wenn Vorheizen nicht Sinnvoll, sonst 1
int VorheizenTrue = 0; // 1, wenn Vorheizen aktiv ist
int Pruefwert = 0;
long Startphase_zeit = 0; // Zeitstempel
long Startzeit_set = 10000; // Wartezeit 600000ms = 10min

// Deklaration Manueller Start/Stopp
int man = 0;

// Fallbackfunktion
int fallbackFlag = 0;

void setup() {
  // Setup CAN
  initCan1(Display_Message_TX1); // CAN Modul initialisieren
  canMod1.attachInterrupt(doCan1Interrupt); // Interrupt Service Routine
  
  // Setup Kuehlwassermanipulation
  Serial.begin(9600);
  attachInterrupt(0, readbutton1, FALLING); // Interrupt bei fallender Flanke
  attachInterrupt(1, readbutton2, FALLING); // Interrupt bei fallender Flanke
  pinMode(2, INPUT);
  pinMode(3, INPUT);
  pinMode(10, OUTPUT);
  }


void loop() {
  
  // Temperaturen einlesen
  sens = analogRead(A0); // Sensor Kuehlwasser
  T_KW = voltageToTemperature(sens); // Temperatur Kuehlwasser speichern
  
  sens = analogRead(A1); // Sensor Boiler
  T_B = voltageToTemperature(sens); // Temperatur Boilerwasser speichern
  
  
    
  if (Startphase == 1) {
    digitalWrite(10, HIGH); // Relais ausschalten
    // Vorheizen vor dem Motorstart
    if (button_start == 1) {
      // Pruefen ob Vorheizen sinnvoll ist
      Pruefwert = pruefvorheizen(T_B, T_KW);
      Serial.println ("Pruefen ob vorheizen notwendig ist...");
      delay(1000);
      if (Pruefwert == 1) {
        Serial.println ("Vorheizen beginnt...");
        delay(2000);
        VorheizenTrue = 1;
        // Vorheizen aufrufen
        vorheizen();
        VorheizenTrue = 0;
        Startphase = 0;
        Startphase_zeit = millis();
      } else {
        Serial.println ("Vorheizen ist nicht notwendig...");
        delay(2000);
        Startphase = 0;
        Startphase_zeit = millis();
      }
    }
    anzeigen();
    
    
  } else {
    
    // Aufwaermphase des Boilerwassers
    if ((millis() - Startphase_zeit) > Startzeit_set && T_KW > 80) {
      if (fallbackFlag == 0) {
        Serial.println ("Boilerwasser wird beheizt...");
        delay(2000);
      }
      // Flag setzen fuer Rueckfalloption
      fallbackFlag = 1;
      // Zweipunktregler zum Temperatur halten
      Relaisstatus = zweipunkt(T_B);
      // Relais schalten
      if (Relaisstatus == 1) {
        digitalWrite(10, LOW); // Relais anschalten
      } else {
        digitalWrite(10, HIGH); // Relais ausschalten
      }
    }
    anzeigen();
    
    
  }
  
  // Rueckfalloption
  if (fallbackFlag == 1 && T_KW < 70) {
    Startphase = 1;
    button_start = 0;
    fallbackFlag = 0;
  }
  
  // Manuelles Starten
//  if (man == 1) {
//    Serial.println ("Manueller Pumpenstart");
//    delay(2000);
//    while (man == 1) {
//      // Temperaturen einlesen
//      sens = analogRead(A0); // Sensor Kuehlwasser
//      T_KW = voltageToTemperature(sens); // Temperatur Kuehlwasser speichern
//      sens = analogRead(A1); // Sensor Boiler
//      T_B = voltageToTemperature(sens); // Temperatur Boilerwasser speichern
//      digitalWrite(10, LOW); // Relais anschalten
//      Relaisstatus = 1;
//      anzeigen();
//      delay(2000);
//    }
//    Startphase = 0;
//    Serial.println ("Manueller Pumpenstopp");
//    digitalWrite(10, HIGH); // Relais ausschalten
//    Relaisstatus = 0;
//  }
  
    if (man == 1) {
      delay(2000);
      while (man == 1) {
        // Temperaturen einlesen
        sens = analogRead(A0); // Sensor Kuehlwasser
        T_KW = voltageToTemperature(sens); // Temperatur Kuehlwasser speichern
        sens = analogRead(A1); // Sensor Boiler
        T_B = voltageToTemperature(sens); // Temperatur Boilerwasser speichern
        digitalWrite(10, HIGH); // Relais ausschalten
        Relaisstatus = 0;
        anzeigen();
        delay(2000);
      }
    Startphase = 0;
    Serial.println ("Automatik an");
  }
  
  
  delay(2000);
}

  
/***************************************************
* Interrupt-Funktion zum druecken des Starttaster *
***************************************************/
void readbutton1() {
  interrupt_time_1 = millis(); // Zeitstempel
  if (interrupt_time_1 - last_interrupt_time_1 > DEBOUNCE_TIME) {
    button_start = !button_start;
  }
  last_interrupt_time_1 = interrupt_time_1;
}


/**********************************************************************
* Interrupt-Funktion zum druecken des Manuellen Start/Stopp -tasters *
**********************************************************************/
void readbutton2() {
  interrupt_time_2 = millis(); // Zeitstempel
  if (interrupt_time_2 - last_interrupt_time_2 > DEBOUNCE_TIME) {
    if (VorheizenTrue == 1) {
      Pruefwert = 0; // Wird verwendet zum verlassen der Vorheizphase
      digitalWrite(10, HIGH); // Relais anschalten
      Relaisstatus = 0; // Status der Pumpe, bzw. des Relais setzen
      VorheizenTrue = 0;
      Serial.println ("Vorheizen abgebrochen...");
      delay(2000);
    } else {
      if (man == 1) {
        man = 0;
      } else {
        man = 1;
      }
    }
  }
  last_interrupt_time_2 = interrupt_time_2;
}
  
   
/***********************
* Temperatur einlesen *
***********************/
float voltageToTemperature(float rawVoltage) {
  float temperatureKelvin;
  float realVoltage;
  float resistance;
  float B = 3435.0;
  float temperatureNominal = 25.0 + 273.0;
  float resistanceNominal = 10000.0;
  realVoltage = rawVoltage * 3.3 / 1024;
  resistance = (3.3 - realVoltage) * resistanceNominal / realVoltage;
  temperatureKelvin = B * temperatureNominal / (B + log(resistance / resistanceNominal) * temperatureNominal);
  return temperatureKelvin - 273.0;
}


/*******************
* Zweipunktregler *
*******************/
int zweipunkt(int T_B_Pruef) {
  if (Heat == 1) {
    if (T_B_Pruef < Tset + Tset*KH) {
      PumpenFlag = 1;
    } else {
      PumpenFlag = 0;
      Heat = 0;
    }
  } else {
    if (T_B_Pruef > Tset - Tset*KH) {
      PumpenFlag = 0;
    } else {
      PumpenFlag = 1;
      Heat = 1;
    }
  }
  return PumpenFlag;
}


/*************************************
* Pruefen ob Vorheizen sinnvoll ist *
*************************************/
 int pruefvorheizen(int T_B_Pruef, int T_KW_Pruef) {
   if (T_KW_Pruef < 50 && T_B_Pruef > 60) {
     VorheizenFlag = 1;
   } else {
     VorheizenFlag = 0;
   }
   return VorheizenFlag;
 }
 
 
/*************
* Vorheizen *
*************/
void vorheizen() {
  Serial.println ("Vorheizen.........................");
  digitalWrite(10, LOW); // Relais anschalten
  Relaisstatus = 1; // Status der Pumpe, bzw. des Relais setzen
  while(T_KW < T_KW_set){
    Serial.println ("Vorheizen");
    if (Pruefwert == 0) {
      Serial.println ("Vorheizen verlassen");
      return; // Wird bei Interrupt = 0
    }
    sens = analogRead(A0); // Sensor Kuehlwasser
    T_KW = voltageToTemperature(sens); // Temperatur Kuehlwasser speichern
    sens = analogRead(A1); // Sensor Boiler
    T_B = voltageToTemperature(sens); // Temperatur Boilerwasser speichern
    anzeigen();
    delay(2000);
  }
  digitalWrite(10, HIGH); // Relais ausschalten
  Relaisstatus = 0; // Status der Pumpe, bzw. des Relais setzen
}


/************
* Anzeigen *
************/
void anzeigen() {
  // Temperaturen Anzeigen
  Serial.print ("Temperatur des Kuehlwassers: ");
  Serial.print (T_KW);
  Serial.println (" C");
  Serial.print ("Temperatur des Boilerwasser: ");
  Serial.print (T_B);
  Serial.println (" C");
  
  // Pumpenstatus, bzw. Relaisstatus
  if (Relaisstatus == 1) {
    Serial.println ("Pumpe ist in Betrieb");
  } else {
    Serial.println ("Pumpe ist aus");
  }
  
  // Anzeigen des Manuellen Modus
  if (man == 1) {
    Serial.println ("Automatik aus");
  }
  
  // Warnung bei Ueberhitzung des Boilerwassers anzeigen
  if (T_B > 100) {
    Serial.println ("!!! Boilerwasser ueber 100 C !!!");
  }
  Serial.println();
  Serial.println();
  rxCAN1(); // Empfang von Daten
  txCAN1(KMS_Message_TX1); // Versenden von Daten
}




/*******
* CAN *
*******/
 /* CAN Initialisrierung (InitCAN) Deklaration */
void
initCan1(uint32_t myaddr) {
  CAN::BIT_CONFIG canBitConfig;
  canMod1.enableModule(true);
  canMod1.setOperatingMode(CAN::CONFIGURATION);
  while(canMod1.getOperatingMode() != CAN::CONFIGURATION);
  canBitConfig.phaseSeg2Tq = CAN::BIT_3TQ;
  canBitConfig.phaseSeg1Tq = CAN::BIT_3TQ;
  canBitConfig.propagationSegTq = CAN::BIT_3TQ;
  canBitConfig.phaseSeg2TimeSelect = CAN::TRUE;
  canBitConfig.sample3Time = CAN::TRUE;
  canBitConfig.syncJumpWidth = CAN::BIT_2TQ;
  canMod1.setSpeed (&canBitConfig,SYS_FREQ,CAN_BUS_SPEED);
  canMod1.assignMemoryBuffer (CAN1MessageFifoArea,2 * 8 * 16);
  canMod1.configureChannelForTx(CAN::CHANNEL0,8,CAN::TX_RTR_DISABLED,CAN::LOW_MEDIUM_PRIORITY);
  canMod1.configureChannelForRx(CAN::CHANNEL1,8,CAN::RX_FULL_RECEIVE);
  canMod1.configureFilter (CAN::FILTER0, myaddr, CAN::SID);
  canMod1.configureFilterMask (CAN::FILTER_MASK0, 0xFFF, CAN::SID, CAN::FILTER_MASK_IDE_TYPE);
  canMod1.linkFilterToChannel (CAN::FILTER0, CAN::FILTER_MASK0, CAN::CHANNEL1);
  canMod1.enableFilter (CAN::FILTER0, true);
  canMod1.enableChannelEvent (CAN::CHANNEL1, CAN::RX_CHANNEL_NOT_EMPTY, true);
  canMod1.enableModuleEvent (CAN::RX_EVENT, true);
  canMod1.setOperatingMode (CAN::NORMAL_OPERATION);
  while(canMod1.getOperatingMode() != CAN::NORMAL_OPERATION);	
  
}

/* txCAN Deklaration */
void
txCAN1(uint32_t rxnode) {
  
  CAN::TxMessageBuffer * message;
  message = canMod1.getTxMessageBuffer(CAN::CHANNEL0);
  
  if (message != NULL) {
    
    message->messageWord[0] = 0; // clear buffer
    message->messageWord[1] = 0; // clear buffer
    message->messageWord[2] = 0; // clear buffer
    message->messageWord[3] = 0; // clear buffer

    message->msgSID.SID = rxnode;	// receiving node
    message->msgEID.IDE = 0;	// ID des Frames
    message->msgEID.DLC = 3; // Frame Größe
    message->data[0] = T_KW; // 1. Byte
    message->data[1] = T_B; // 2. Byte
    message->data[2] = Relaisstatus; // 3.Byte
    message->data[3] = Fehlercode; // 4.Byte
        
    canMod1.updateChannel(CAN::CHANNEL0);
    canMod1.flushTxChannel(CAN::CHANNEL0);
  }	

}

/* rxCAN Deklaration */
void
rxCAN1(void) {
  
  CAN::RxMessageBuffer * message;
  if (isCAN1MsgReceived == false) {
    Serial.println("Keine gueltigen Frames empfangen");
    return;
    }
  isCAN1MsgReceived = false;	
  message = canMod1.getRxMessage(CAN::CHANNEL1);
  
  /* PLOTTEN */
  //Serial.print(byte(message->msgSID.SID));
  //Serial.print("Frame Name: ");
  //Serial.print(byte(message->msgEID.IDE));
  //Serial.print("Frame ID: ");
  //Serial.print(byte(message->msgEID.DLC));
  Serial.print("Frame DLC: ");
  Serial.print(byte(message->data[0]));
  Serial.print(byte(message->data[1]));
  Serial.println();
  
  canMod1.updateChannel(CAN::CHANNEL1);
  canMod1.enableChannelEvent(CAN::CHANNEL1, CAN::RX_CHANNEL_NOT_EMPTY, true);
  
  int Temp = byte(message->data[1]);
  if (Temp == 'B') {
    readbutton2();
  }
  Temp = byte(message->data[0]);
  if (Temp == 'A') {
    readbutton1();
  }

}

/* Interrupt Deklaration */
void
doCan1Interrupt() {
  
  if ((canMod1.getModuleEvent() & CAN::RX_EVENT) != 0) {
    if(canMod1.getPendingEventCode() == CAN::CHANNEL1_EVENT) {
      canMod1.enableChannelEvent(CAN::CHANNEL1, CAN::RX_CHANNEL_NOT_EMPTY, false);
      isCAN1MsgReceived = true;	
    }
  }
}

/* ENDE */
