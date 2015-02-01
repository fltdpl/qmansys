#include <math.h>
#include <WProgram.h>
#include "chipKITCan.h"

/********************************************
* Deklarationen fuer CAN (von Christopher) *
********************************************/

/* Lokale Typen und Defeintionen */
#define	KMS_Message_TX1	0x001L // CAN Knoten1 Schnittstelle1
#define Display_Message_TX1	0x002L // CAN Knoten2 Schnittstelle2

#define SYS_FREQ      (80000000L) // Frequenz
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
int button_autostart = 0; // Signalisieren, dass der Motor gestartet wird
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
int Heat = 0;       // 1=Heizen, 0=Abkuehlen
float KH = 0.05;     // Kopplungsfaktor


// Deklaration Relais
int Relaisstatus = 0; // Status des Relais bzw. Pumpe

// Deklaration Fehler und Nachrichten
int Fehlercode = 0;       // Fehlercode gibt verschiedene Fehler an (0=kein Fehler, 1= ...)
int nachricht_phase = 1;  // Nachricht, die per CAN gesendet wird
int nachricht_info = 1;   // Nachricht, die per CAN gesendet wird

// Deklaration Startphase
int zustand = 1;       // 1=Startphase, 2=
int Startphase = 1;
int VorheizenFlag = 0; // 0 wenn Vorheizen nicht Sinnvoll, sonst 1
int VorheizenTrue = 0; // 1, wenn Vorheizen aktiv ist
int Pruefwert = 0;
long Startphase_zeit = 0;   // Zeitstempel
long Heartbeat = 5000;      // Sollzeit fuer Heartbeat fuer CAN-Uebertragung
long Heartbeat_time = 0;    // Zeitstempel fuer Heartbeat fuer CAN-Uebertragung
long Startzeit_set = 10000; // Wartezeit 600000ms = 10min

// Temperaturen festlegen
int T_KW_set = 35;        // Bis zu welcher Temperatur wird vorgeheizt (40grad)
int Tset = 40;            // Sollwert der Boilertemperatur (80grad)
int T_KW_min = 40;        // Minimale Temperatur des Kühlwassers zum beheizen des Boilerwassers (80grad)
int Temperaturen[10];     // Temperaturenbuffer

// Temporaere Speicher zum Senden bei Aenderung
int T_KW_temp = 0;
int T_B_temp = 0;
int nachricht_info_temp = 0;
int zustand_temp = 0;
int Relaisstatus_temp = 0;

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
  pinMode(11, OUTPUT);
  pinMode(10, OUTPUT);
  pinMode(9, OUTPUT);
  pinMode(8, OUTPUT);
}



void loop() {

  // Temperaturen einlesen
  T_KW = gettemperature(analogRead(A0)); // Temperatur Kuehlwasser speichern
  T_B  = gettemperature(analogRead(A1)); // Temperatur Boilerwasser speichern





  switch (zustand) {

    // Startphase inaktiv
    case 1:
      pumpeAUS();
      Pruefwert = pruefvorheizen(T_B, T_KW);
      if (Pruefwert == 0){
        nachricht_info = 1; // Vorheizen ist nicht sinnvoll.
        if (button_autostart == 1){
          button_autostart = 0;
          zustand = 3;      // Springen in die Wartephase
          nachricht_info = 0;
        }
      }else{
        nachricht_info = 2; // Vorheizen ist sinnvoll.
        if (button_autostart == 1){
          button_autostart = 0;
          zustand = 2;      // Springen in die Vorheizphase
          nachricht_info = 0;
        }
      }
      if (button_manuell == 1) {
        zustand = 5;        // Springen in manuellen Startbetrieb
        nachricht_info = 0;
      }

      break;

    // Startphase aktiv -> Vorheizen
    case 2:
      pumpeAN();
      Startphase_zeit = millis();
      while(T_KW < T_KW_set) {
        if (button_manuell == 1) {   // Bei Interrupt
          button_manuell = 0;
          Serial.println ("Vorheizen verlassen");
          zustand = 6;    // Springen in den Manuellen Stoppbetrieb
          pumpeAUS();     // Pumpe ausschalten
          return;
        }
        // Temperaturen einlesen
        T_KW = gettemperature(analogRead(A0)); // Temperatur Kuehlwasser speichern
        T_B  = gettemperature(analogRead(A1)); // Temperatur Boilerwasser speichern
        senden();
        delay(100);
      }
      pumpeAUS();
      zustand = 3;        // Springen in die Wartephase
      break;

    // Wartephase
    case 3:
      if ((millis() - Startphase_zeit) > Startzeit_set && T_KW > T_KW_min ) {
        zustand = 4;      // Springen in die Zweipunktreglerphase
      }
      if (button_manuell == 1) {
        zustand = 5;      // Springen in den manuellen Startbetrieb
      }
      if (button_autostart == 1) {
        inireset();
      }
      if ((millis() - Startphase_zeit) > 60000 && T_KW < 35 ) {
        inireset();
      }

      break;

    // Zweipunktregler -> Boilerwasser heizen
    case 4:
      if (zweipunkt(T_B) == 1){
        pumpeAN();
        if (button_manuell == 1) {
          button_manuell = 0;
          zustand = 6;      // Springen in den manuellen Stoppbetrieb
        }
      } else {
        pumpeAUS();
        if (button_manuell == 1) {
          zustand = 5;      // Springen in den manuellen Startbetrieb
        }
      }
      if ((millis() - Startphase_zeit) > 60000 && T_KW < T_KW_min-0.1*T_KW_min) {
        pumpeAUS();
        nachricht_info = 3; // Kühlwasser zu kalt um das Boilerwasser zu heizen
        //delay(1000);
        inireset();
      }
      if (button_autostart == 1) {
        inireset();
      }

      break;

    // Manuell Start
    case 5:
      pumpeAN();
      if (button_manuell == 0) {
        zustand = 6;        // Springen in den manuellen Stoppbetrieb
      }
      if (button_autostart == 1) {
        zustand = 3;      // Springen in die Wartephase
      }

      break;

    // Manuell Stopp
    case 6:
      pumpeAUS();
      if (button_manuell == 1) {
        zustand = 5;        // Springen in den manuellen Startbetrieb
      }
      if (button_autostart == 1) {
        zustand = 3;      // Springen in die Wartephase
      }

      break;
  }

  senden();
  delay(100);

}






/********
* Reset *
*********/
void inireset() {
  // Reset Startphase
  zustand = 1;       // Startphase inaktiv
  Startphase = 1;
  VorheizenFlag = 0; // 0 wenn Vorheizen nicht Sinnvoll, sonst 1
  VorheizenTrue = 0; // 1, wenn Vorheizen aktiv ist
  Pruefwert = 0;
  Startphase_zeit = 0; // Zeitstempel
  // Reset Manueller Start/Stopp
  button_manuell = 0;
  // Deklaration Fehler und Nachrichten
  Fehlercode = 0;
  nachricht_phase = 1;
  nachricht_info = 1;
  // Deklaration Interrupt: Schalter und entprellen
  button_autostart = 0;
  button_manuell = 0;
}


/**************************************************
* Interrupt-Funktion zum druecken des Starttaster *
***************************************************/
void readbutton1() {
  interrupt_time_1 = millis(); // Zeitstempel
  if (interrupt_time_1 - last_interrupt_time_1 > DEBOUNCE_TIME) {
    button_autostart = !button_autostart;
  }
  last_interrupt_time_1 = interrupt_time_1;
}


/**********************************************************************
* Interrupt-Funktion zum druecken des Manuellen Start/Stopp -tasters *
**********************************************************************/
void readbutton2() {
  interrupt_time_2 = millis(); // Zeitstempel
  if (interrupt_time_2 - last_interrupt_time_2 > DEBOUNCE_TIME) {
     button_manuell = !button_manuell;
  }
  last_interrupt_time_2 = interrupt_time_2;
}

/**********************
* Temperatur einlesen *
***********************/
float gettemperature(float sens) {
  int temperaturMittelwert; //Mittelwert als Integer definieren
  int zaehlerSoll = 50;     //Durchläufe Soll
  int zaehlerIst = 0 ;      //Durchläufe Ist

  temperaturMittelwert = 0; //Gemittelten Wert auf 0 zurücksetzen
  for(zaehlerIst = 0; zaehlerIst < zaehlerSoll; zaehlerIst++)
   {
     int sensorLesen = sens;                                         //wir lesen den Sensorwert (Pin A0) ein
     int temperatur = voltageToTemperature(sens);                    //Umrechnung in Grad Celsius
     temperaturMittelwert = (temperaturMittelwert + temperatur) / 2; //Neuer Mittelwert
     delay(1); //wir warten 1ms
   }

   return temperaturMittelwert;
}

/************************
* Temperatur umrechnene *
*************************/
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

/************
* Pumpe aus *
*************/
void pumpeAUS(){
  digitalWrite(10, HIGH); // Relais 1 ausschalten
  digitalWrite(9, LOW);   // Relais 2 anschalten
  digitalWrite(8, LOW);   // Relais 3 immer an
  digitalWrite(11, HIGH);  // Relais 4 (LED) ausschalten
  Relaisstatus = 0; // Status der Pumpe, bzw. des Relais setzen
}

/************
* Pumpe an *
*************/
void pumpeAN(){
  digitalWrite(10, LOW);  // Relais 1 anschalten
  digitalWrite(9, HIGH);  // Relais 2 ausschalten
  digitalWrite(8, LOW);   // Relais 3 immer an
  digitalWrite(11, LOW);  // Relais 4 (LED) anschalten
  Relaisstatus = 1; // Status der Pumpe, bzw. des Relais setzen
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
   if (T_KW_Pruef < 35 && T_B_Pruef > 40) {
     VorheizenFlag = 1;
   } else {
     VorheizenFlag = 0;
   }
   return VorheizenFlag;
 }

/*******************
 * Senden/Anzeigen *
 *******************/
void senden() {
  if ( T_KW != T_KW_temp ||
       T_B != T_B_temp ||
       nachricht_info != nachricht_info_temp ||
       zustand != zustand_temp ||
       Relaisstatus != Relaisstatus_temp ||
       (millis() - Heartbeat_time) >= Heartbeat )
       {

      // Temperaturen Anzeigen
      Serial.print ("Temperatur des Kuehlwassers: ");
      Serial.print (T_KW);
      Serial.println (" C");
      Serial.print ("Temperatur des Boilerwasser: ");
      Serial.print (T_B);
      Serial.println (" C");

      // Info
      switch (nachricht_info) {
        case 1:
          Serial.println ("Vorheizen ist nicht Notwendig");
          break;
        case 2:
          Serial.println ("Vorheizen kann begonnen werden");
          break;
        default:

          break;
      }

      // Phase
      switch (zustand) {
        case 1:
          Serial.println ("Startphase inaktiv");
          break;
        case 2:
          Serial.println ("Vorheizen des Kuehlwassers");
          break;
        case 3:
          Serial.println ("Wartephase");
          break;
        case 4:
          Serial.println ("Beheizen des Boilerwassers");
          break;
        case 5:
          Serial.println ("Manueller Betrieb -> Pumpe AN");
          break;
        case 6:
          Serial.println ("Manueller Betrieb -> Pumpe AUS");
          break;
      }

      // Pumpenstatus, bzw. Relaisstatus
      if (Relaisstatus == 1) {
        Serial.println ("Pumpe AN");
      } else {
        Serial.println ("Pumpe AUS");
      }

      // Warnung bei Ueberhitzung des Boilerwassers anzeigen
      if (T_B > 100) {
        Serial.println ("!!! Boilerwasser ueber 100 C !!!");
      }

      Serial.println();
      Serial.println();
      rxCAN1(); // Empfang von Daten
      txCAN1(KMS_Message_TX1); // Versenden von Daten

      // Werte zwischenspeichern
      T_KW_temp = T_KW;
      T_B_temp = T_B;
      nachricht_info_temp = nachricht_info;
      zustand_temp = zustand;
      Relaisstatus_temp = Relaisstatus;
      Heartbeat_time = millis();
     }
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
    message->msgEID.DLC = 4; // Frame Groesse
    message->data[0] = T_KW; // 1. Byte
    message->data[1] = T_B; // 2. Byte
    message->data[2] = Relaisstatus; // 3.Byte
    message->data[3] = zustand; // 4.Byte

    canMod1.updateChannel(CAN::CHANNEL0);
    canMod1.flushTxChannel(CAN::CHANNEL0);
  }

}

/* rxCAN Deklaration */
void
rxCAN1(void) {

  CAN::RxMessageBuffer * message;
  if (isCAN1MsgReceived == false) {
    //Serial.println("Keine gueltigen Frames empfangen");
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
