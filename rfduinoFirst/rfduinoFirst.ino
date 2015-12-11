#include "RFduinoBLE.h"
//ref https://github.com/RFduino/RFduino
// """" Download Arduino 1.6.6 or newer. """""

int sv = 0;
int svf = 0.0f;

void setup()
{
  Serial.begin(9600);
  RFduinoBLE.advertisementData = "myData"; // shouldnt be more than 10 characters long
  RFduinoBLE.deviceName = "myRFduino"; // name of your RFduino. Will appear when other BLE enabled devices search for it

  //ref https://www.uuidgenerator.net/
  RFduinoBLE.customUUID = "9a444680-9fd8-11e5-8994-feff819cdc9f"; 
  RFduinoBLE.begin(); // begin
}

void loop()
{
  RFduinoBLE.send(sv);
  //RFduinoBLE.sendFloat(svf); It can not be taken yet from IOS
  delay(20); 
  sv++;
  svf += 0.1f;

  if(sv > 255) 
  {
    sv = 0;
    svf = 0.0f;
  } 
}

void RFduinoBLE_onReceive(char *data, int len)
{
  // display the first recieved byte
  for(int i = 0; i < len; i++)
  {
     Serial.print(data[i]);    
  }
  Serial.println();
}

