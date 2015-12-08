#include "RFduinoBLE.h"
//ref https://github.com/RFduino/RFduino
// """" Download Arduino 1.6.6 or newer. """""

void setup()
{
  Serial.begin(9600);
  RFduinoBLE.advertisementData = "myData"; // shouldnt be more than 10 characters long
  RFduinoBLE.deviceName = "myRFduino"; // name of your RFduino. Will appear when other BLE enabled devices search for it
  RFduinoBLE.begin(); // begin
}

void loop()
{
  RFduinoBLE.send(10); // send number 1 to connected BLE device
  delay(3000); // delay for 3 seconds
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

