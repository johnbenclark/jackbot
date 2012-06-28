import processing.serial.*;

final float INITIAL_RL = 38.0;
final float INITIAL_RR = 38.5;

// 8.5 x 11
//final float HORZ_OFFSET = 29.0;
//final float VERT_OFFSET = 20.0;

//
final float HORZ_OFFSET = 23.0;
final float VERT_OFFSET = 17.0;

final boolean DEBUG_SERIAL = false;
final boolean DEBUG_POSITION = false;
final int RESPONSE_TIMEOUT = 5000;
final int MOTOR_LOOP_DELAY = 150;

PFont myFont;     // The display font:


void setup() {
  size(400,200);
  // Make your own font. It's fun!
  myFont = createFont("Arial", 18);
  textFont(myFont, 18);
  // List all the available serial ports:
  println(Serial.list());
  
  setupSerial();
}


void draw() {
  background(0);
  text("current position: " + posIndex, 10,50);
  doCSM();
}

String showInputDialog(String msg) {
  return javax.swing.JOptionPane.showInputDialog(msg);
}

float teethPerInch = 5; // 20XLHDF
float teethPerRevolution = 20;
float fractionsPerStep = 8; // eighth (1/8) steps
float stepsPerRevolution = 2 * 100; // MOONS 23 5618S-05D MS W0233611

float frameWidthInches = 64;
float frameWidthTeeth = frameWidthInches * teethPerInch;
float frameWidthRevolutions = frameWidthTeeth / teethPerRevolution;
float frameWidthSteps = frameWidthRevolutions * stepsPerRevolution;
float frameWidthFractions = frameWidthSteps * fractionsPerStep;
float frameWidthPixels = -1;

float fractionsPerPixel = -1;
float fractionsPerInch = frameWidthFractions / frameWidthInches;

float verticalOffset = VERT_OFFSET / frameWidthInches;
float horizontalPercentage = (frameWidthInches - (HORZ_OFFSET * 2)) / frameWidthInches;

int posIndex = 0;
String posFile[] = null;
int posFileLength = -1;
int posFileWidth = 0;

void loadPosFile() {
    posFile = loadStrings(selectInput());
    frameWidthPixels = float(showInputDialog("Input the file width")) / horizontalPercentage;
    fractionsPerPixel = frameWidthFractions / frameWidthPixels;
    
    println("frameWidthFractions: " + frameWidthFractions);
    println("frameWidthPixels: " + frameWidthPixels);
    println("fractionsPerPixel: " + fractionsPerPixel);
    println("fractionsPerInch: " + fractionsPerInch);
    println("horizontalPercentage: " + horizontalPercentage);
    println("verticalOffset: " + verticalOffset);
}

CoordPlot getPos() {
  if(posFile == null) {
    loadPosFile();
  }
  
  String posFileLine = trim(posFile[posIndex]);
  String posFileParms[] = split(posFileLine, ",");
  float x = float(posFileParms[0]) + (frameWidthPixels * (1 - horizontalPercentage) / 2);
  float y = float(posFileParms[1]) + frameWidthPixels * verticalOffset;
  
  if(DEBUG_POSITION)
    println("x: " + x + ", y: " + y);
  
  CoordImag imagPos = new CoordImag(x, y);
  CoordPlot plotPos = imagPos.convert();
  
  if(DEBUG_POSITION)
    println("RL: " + plotPos.getRL() + ", RR: " + plotPos.getRR());
  
  return plotPos;
}

boolean incPos() {
  if(posFileLength < 0) {
    posFileLength = posFile.length;
  }
  
  if(posIndex < (posFileLength - 1)) {
    posIndex++;
    return true;
  } else {
    return false;
  }
  
}


public class CoordPlot {
  private int _RL;
  private int _RR;
  
  CoordPlot(int RL, int RR) {
    _RL = RL;
    _RR = RR;
  }
  
  int getRL() {
    return _RL;
  }
  
  int getRR() {
    return _RR;
  }
}

public class CoordImag {
  private float _x;
  private float _y;
  
  CoordImag(float x, float y) {
    _x = x;
    _y = y;
  }
  
  CoordPlot convert() {
    float RR = fractionsPerPixel * sqrt(sq(frameWidthPixels - _x) + sq(_y));
    float RL = fractionsPerPixel * sqrt(sq(_x) + sq(_y));
    return new CoordPlot(int(RL), int(RR));
  }
}

final char CSM_INIT = 44;
final char CSM_SEND = 45;
final char CSM_RECV = 46;
char csm = CSM_INIT;

void doCSM() {
  switch(csm) {
    case CSM_INIT:
      csm = initCSM();
      break;
    case CSM_SEND:
      csm = sendCSM();
      break;
    case CSM_RECV:
      csm = recvCSM();
      break;
  }
}

char initCSM() {
  sendMessage("i1" + int(INITIAL_RL * fractionsPerInch));
  sendMessage("i2" + int(INITIAL_RR * fractionsPerInch));
  sendMessage("ld" + MOTOR_LOOP_DELAY);
  return CSM_RECV;
}

char sendCSM() {
  CoordPlot pos = getPos();
  sendMessage("m1" + pos.getRL());
  sendMessage("m2" + pos.getRR());
  m1Done = m2Done = false;
  recvTimeoutMillis = millis() + RESPONSE_TIMEOUT;
  return CSM_RECV;
}

int recvTimeoutMillis;
boolean m1Done = false;
boolean m2Done = false;
char recvCSM() {
  String msg = recvMessage();
  if(msg == null) {
    if(millis() > recvTimeoutMillis) {
      return CSM_SEND;
    } else {
      // this is the tight loop, so delay
      delay(0);
      return CSM_RECV;
    }
  } else {
    if(match(msg, "LD") != null) {
      return CSM_SEND;
    }
    
    if(match(msg, "D1") != null) {
      m1Done = true;
    } else if(match(msg, "D2") != null) {
      m2Done = true;
    }
    
    if(m1Done && m2Done) {
      if(posIndex == 0) {
        javax.swing.JOptionPane.showMessageDialog(null, "Press 'OK' to continue...");
      }
      incPos();
      return CSM_SEND;
    } else {
      return CSM_RECV;
    }
  }
}


Serial plotPort;  // The serial port:
final char EOL = 0x0A;
final int BUFF_SIZE = 255;

void setupSerial() {
  plotPort = new Serial(this, Serial.list()[1], 115200);
  plotPort.bufferUntil(BUFF_SIZE);
}

void sendMessage(String msg) {
  plotPort.write(msg);
  plotPort.write(EOL);
  
  if(DEBUG_SERIAL)
    println("Sending: " + msg);
}

String recvMessage() {
  if(plotPort.available() > 0) {
    String msg = plotPort.readStringUntil(EOL);
    
    if(msg != null) {
      if(DEBUG_SERIAL)
        println("Received: " + msg);
        
      return msg;
    }
  }
  return null;
}

void serialEvent(Serial p) {
  if(p == plotPort) {
    println("Buffer filled up!!!");
    println("Clearing buffer...");
    p.clear();
  }
}
