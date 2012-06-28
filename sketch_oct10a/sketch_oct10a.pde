
PImage b;
int s = 12; // size of the density blocks
final int OVERSAMPLE = 1;
final float F_CONST = 2.3; // bigger -> lower frequency
final float A_CONST = 0.65;
int nx, ny; // size of image in density blocks
 
void setup() {
  //b = loadImage("intranet-picture.gif");
  //String dir = "C:\\Users\\john.blasdell\\Pictures\\sketch_oct07b\\";
  //String file;
  //file = "blank.jpg";
  //file = "new-york-city-skyline.jpg";
  //file = "portrait.jpg";
  //file = "japanwave.jpg";
  //file = "oilrig.jpg";
  
  b = loadImage(selectInput());
  
  // basic setups
  frameRate(20);
  size(b.width, b.height);
  colorMode(RGB, 255);
  background(255);
  smooth();
  strokeWeight(3);
  
  // draw semitransparent image on bg
  tint(255, 15);
  //image(b, 0, 0);
  
  
  (new File("pointlist.txt")).delete();
  cachedSavePoint(0, 0);
}

void mouseClicked() {
  SimpleDateFormat sdf = new SimpleDateFormat("'_'yyyy-MM-dd_HH-mm-ss");
  String fileName = getClass().getSimpleName() + sdf.format(new Date());
  
  println(fileName);
  
  save(dataPath(fileName + ".png"));
  
  cachedSavePointFlush();
  (new File("pointlist.txt")).renameTo(new File(dataPath(fileName + "_cart.txt")));
}

float pixelAvgBright(PImage img, int x1, int y1, int x2, int y2) {
  float acc = 0;
  for(int i = x2 - 1; i >= x1; i--) {
    for(int j = y2 - 1; j >= y1; j--) {
      int index = i + j*img.width;
      if(index > img.pixels.length) {
        println(i + " " + j);
      }
      acc += brightness(img.pixels[i + j*img.width]);
    }
  }
  
  return acc / ((x2 - x1) * (y2 - y1));
}

float[] calcLinearW(int y, int h) {
  float[] vals = new float[width];
  int xl, xr;
  
  
  for(int x = 0; x < width; x++) {
    xl = x - h/2;
    xr = x + h/2;
    if(xl < 0) xl = 0;
    if(xr >= width) xr = width - 1;
    vals[x] = (float)(255 - pixelAvgBright(b, x, y, x+s, y+h)) / 255;
  }
  
  return vals;
}

int row = 0;

void draw() {
  row += s;
  boolean ltr = ((row / s) % 2 == 1) ? true : false;
  
  if(row <= height - s - s) {
    drawLine(calcLinearW(row, s), row, ltr);
  }
}

int x1 = 0;
int y1 = 0;
int x2, y2;
float rawX2, rawY2;

void drawLine(float[] ws, int y, boolean ltr) {
  float theta = 0;
  int os = OVERSAMPLE; // oversample
  
  for(int j=0; j < width*os; j++) {
    int k = ltr ? j : (width*os - j - 1);
    
    float f = PI * (ws[k/os]) / F_CONST;
    float a = ws[k/os] * A_CONST;
    
    theta += f / os;
    
    rawX2 = ((float)k)/os;
    rawY2 = y + s * (0.5 + a*sin(theta));
    
    x2 = round(rawX2);
    y2 = round(rawY2);
    
    //println("x2: " + x2 + " y2: " + y2);
    cachedSavePoint(rawX2, rawY2);
    
    line(x1, y1, x2, y2);
    
    // store as last point
    x1 = x2; y1 = y2;
  }
}


int savePointBuffSize = 4096;
float[] xs = new float[savePointBuffSize];
float[] ys = new float[savePointBuffSize];
int cacheIndex = 0;

void cachedSavePoint(float x, float y) {
  xs[cacheIndex] = x;
  ys[cacheIndex] = y;
  
  if(cacheIndex == (savePointBuffSize - 1)) {
    savePoints(xs, ys, cacheIndex + 1);
    cacheIndex = 0;
  } else {
    cacheIndex++;
  }
  
}

void cachedSavePointFlush() {
  savePoints(xs, ys, cacheIndex + 1);
  cacheIndex = 0;
}

void savePoints(float[] xs, float[] ys, int pointLength) {
  String outFileName = "pointlist.txt";
  
  BufferedWriter bw = null;
  try 
  {
    FileWriter fw = new FileWriter(outFileName, true); // true means: "append"
    bw = new BufferedWriter(fw);
    for(int i = 0; i < pointLength; i++) {
      bw.write(xs[i] + "," + ys[i] + "\r\n");
    }
  } 
  catch (IOException e) 
  {
    // Report problem or handle it
    // or not.
  }
  finally
  {
    if (bw != null)
    {
      try { bw.close(); } catch (IOException e) {}
    }
  }
}

// return a random value in the range [0..1] with normal distribution around 0.
// Implements the Marsaglia Polar Method, as described in wikipedia, but only returns one of the values.
float randomNormal()
{
  float x = 1.0, y = 1.0,
        s = 2.0; // s = x^2 + y^2
  while(s >= 1.0)
  {
    x = random(-1.0f, 1.0f);
    y = random(-1.0f, 1.0f);
    s = x*x + y*y;
  }
  return x * sqrt(-2.0f * log(s)/s);
}

