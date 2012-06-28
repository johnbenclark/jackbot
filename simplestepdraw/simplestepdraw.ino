
#define m1ena 7
#define m1dir 6
#define m1stp 5

#define m2ena 10
#define m2dir 11
#define m2stp  9

#define debug true

long m1Cur = 0;
long m2Cur = 0;

long m1Des = 0;
long m2Des = 0;

void setup() {                
  // initialize the digital pin as an output.
  pinMode(m1ena, OUTPUT);
  pinMode(m1dir, OUTPUT);
  pinMode(m1stp, OUTPUT);

  pinMode(m2ena, OUTPUT);
  pinMode(m2dir, OUTPUT);
  pinMode(m2stp, OUTPUT);

  digitalWrite(m1ena, LOW);
  digitalWrite(m2ena, LOW);

  digitalWrite(m1dir, LOW);
  digitalWrite(m2dir, LOW);
  
  Serial.begin(115200);
}


int loopDelay = 1;
boolean doM1 = false;
boolean doM2 = false;
void actuateSteppers() {
  if(doM1)
    digitalWrite(m1stp, HIGH);
    
  if(doM2)
    digitalWrite(m2stp, HIGH);
    
  if(doM1 || doM2)
    delay(loopDelay);
  
  if(doM1)
    digitalWrite(m1stp, LOW);
  
  if(doM2)
    digitalWrite(m2stp, LOW);
  
  if(doM1 || doM2)
    delay(loopDelay);
    
  doM1 = false;
  doM2 = false;
}

void loop() {
  if(m1Des < m1Cur) {
    digitalWrite(m1dir, LOW);
    doM1 = true;
    m1Cur--;
  }
  if(m1Des > m1Cur) {
    digitalWrite(m1dir, HIGH);
    doM1 = true;
    m1Cur++;
  }
  if(m2Des < m2Cur) {
    digitalWrite(m2dir, LOW);
    doM2 = true;
    m2Cur--;
  }
  if(m2Des > m2Cur) {
    digitalWrite(m2dir, HIGH);
    doM2 = true;
    m2Cur++;
  }
  
  actuateSteppers();
  
  if(doM1 && m1Des == m1Cur) {
    Serial.println("d1");
  }
  if(doM2 && m2Des == m2Cur) {
    Serial.println("d2");
  }
}


char serialBuffer[256];
int serialBufferIndex = 0;

void handleSerial() {
  while(Serial.available() > 0) {
    char newChar = Serial.read();
    
    if(newChar = 10) {
      serialBuffer[serialBufferIndex] = 0;
      handleCommand(serialBuffer);
      serialBufferIndex = 0;
    } else {
      serialBuffer[serialBufferIndex] = newChar;
      serialBufferIndex++;
    }
  }
}

void handleCommand(char* cmdLine) {
  char cmdCode[3];
  char cmdParm[17];
  
  strncpy(cmdCode, cmdLine, 2);
  strncpy(cmdParm, cmdLine+2, 16);
  
  if(!strcmp(cmdCode, "m1")) {
    if(strlen(cmdParm) > 0)
      m1Des = atol(cmdParm);
    Serial.println(m1Des);
    
  } else if(!strcmp(cmdCode, "m2")) {
    if(strlen(cmdParm) > 0)
      m2Des = atol(cmdParm);
    Serial.println(m2Des);
    
  } else if(!strcmp(cmdCode, "i1")) {
    if(strlen(cmdParm) > 0)
      m1Cur = atol(cmdParm);
    Serial.println(m1Cur);
    
  } else if(!strcmp(cmdCode, "i2")) {
    if(strlen(cmdParm) > 0)
      m2Cur = atol(cmdParm);
    Serial.println(m2Cur);
    
  } else if(!strcmp(cmdCode, "ld")) {
    if(strlen(cmdParm) > 0)
      loopDelay = atoi(cmdParm);
    Serial.println(loopDelay);
  }
}







