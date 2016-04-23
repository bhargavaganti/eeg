import processing.serial.*;

import org.firmata.*;
import cc.arduino.*;

import oscP5.*;
import netP5.*;

// Set up communication with Arduino
Arduino arduino;
int motorPin = 9; // Motor output to pin 9
int command = 0;

OscP5 oscP5;

NetAddress myRemoteLocation;

void setup() {
  size(320, 568);
  background(0);
  
  oscP5 = new OscP5(this, 4000);
  
  // Listen at port 4000 on localhost
  myRemoteLocation = new NetAddress("127.0.0.1", 4000);
  
  //println(Arduino.list());
  arduino = new Arduino(this, "/dev/tty.usbmodem1411");
  arduino.pinMode(motorPin, Arduino.OUTPUT);
}


void draw() {
  // If receiving a 1, turn on motor
  if (command == 1) {
    arduino.analogWrite(motorPin, 255/8);
  }
  // If receiving a 0, turn off motor
  else {
    arduino.analogWrite(motorPin, Arduino.LOW);
  }
}

// Receive and get value of OSC message
void oscEvent(OscMessage OscMsg) {
  String addr = OscMsg.addrPattern();
  command = OscMsg.get(0).intValue();
  
  print("OSC Message Received: ");
  print(command);
  print(" ");
  println(addr);
}




