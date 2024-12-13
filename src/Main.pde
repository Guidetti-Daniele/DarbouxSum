// Variables to manage zoom
float zoom = 1.0;
float zoomAmount = 0.1;

// Variables to manage drag
ScreenLimits screenLimits;

float dragSensibility = 0.1;
Point2D dragPivotPoint;

enum Direction {
  UP_RIGHT,
  UP_LEFT,
  DOWN_RIGHT,
  DOWN_LEFT
}

// Variables to implement Rienmann's sum
int n = 10;
float lowerBound = 0;
float upperBound = 10;

final char plusButton = '+';
final char minusButton = '-';

float myFunction(float x) {
  return x*x;
}

void drawAxis() {  
  stroke(255);
  
  Point2D origin = screenLimits.getOrigin();
  // y-axis
  line(origin.x,0,origin.x,height);
  // x-axis
  line(0,origin.y,width,origin.y);
}

void drawZoomText() {
  String text = String.format("Zoom: %d %%", round(100*zoom));
  fill(255);
  text(text, 40, 40);
}

void drawScreenLimitsText() {
fill(0,255,0);
text(screenLimits.left, 0, height/2);
text(screenLimits.right, width-50, height/2);
text(screenLimits.up, width/2, 10);
text(screenLimits.down, width/2, height-10);
}

void drawMyFunction() {
  pushMatrix();
  Point2D origin = screenLimits.getOrigin();
  translate(origin.x,origin.y);
  
  stroke(255,0,0);
  noFill();

  beginShape();
  for( float x = screenLimits.left/zoom; x <= screenLimits.right/zoom; x+= (1/zoom))
    vertex(x*zoom, -myFunction(x)); //<>//
  endShape();
  
  popMatrix();
}

void drawRienmannSum() {
  float rectWidth = (upperBound-lowerBound)/n;
  float lowerRectHeight = 0;
  float upperRectHeight = 0;
  
  float lowerArea = 0;
  float upperArea = 0;
  
  pushMatrix();
  Point2D origin = screenLimits.getOrigin();
  translate(origin.x,origin.y);
  
  noStroke();
  rectMode(CENTER);
  
  for(float i=0; i<n; i++) {
    float middleX = ((lowerBound+(rectWidth*i))+rectWidth/2);
    
    fill(128,0,128);
    float bottomRightX = lowerBound+(rectWidth*(i+1));
    upperRectHeight = myFunction(bottomRightX);
    rect(middleX*zoom, (-upperRectHeight)/2,rectWidth*zoom,upperRectHeight);
    upperArea += rectWidth * upperRectHeight;

    fill(0,255,0);
    float bottomLeftX = lowerBound+(rectWidth*i);
    lowerRectHeight = myFunction(bottomLeftX);
    rect(middleX*zoom,(-lowerRectHeight)/2,rectWidth*zoom,lowerRectHeight);
    lowerArea += rectWidth * lowerRectHeight;

  }
  
  println("Upper area: ", upperArea);
  println("Lower area: ",lowerArea);
  
  String text = String.format("n=%d",n);
  fill(255);
  text(text, (upperBound*zoom)+10, -(lowerRectHeight+10));
  
  popMatrix();
}

void drawView() {
  background(0);
  
  drawZoomText();
  drawScreenLimitsText();
  drawAxis();
  drawMyFunction();
  drawRienmannSum();
}

void setup() {
  size(1000,600);
  screenLimits = new ScreenLimits();
  
  drawView();
}

void draw() {
  
  if(mousePressed) {
      dragPivotPoint = new Point2D(mouseX,mouseY);
  }
  
}

void mouseWheel(MouseEvent event) {
  
  if(event.getCount() > 0) // the wheel goes down
    zoom = (zoom-zoomAmount) < 0 ? 0 : (zoom-zoomAmount);
   else
    zoom += zoomAmount;
      
  drawView();  
}

Direction getDirection(float offsetX, float offsetY) {
  
  if(offsetX >= 0 && offsetY >= 0)
    return Direction.UP_LEFT;
    
  if(offsetX >= 0 && offsetY < 0)
    return Direction.DOWN_LEFT;
    
  if(offsetX < 0 && offsetY >= 0)
    return Direction.UP_RIGHT;
  
  return Direction.DOWN_RIGHT;
}

void mouseDragged() {
    
    if(dragPivotPoint == null) return;
  
    float offsetX = mouseX - dragPivotPoint.x;
    float offsetY = mouseY - dragPivotPoint.y;
    
    Direction direction = getDirection(offsetX,offsetY);
    offsetX = abs(offsetX);
    offsetY = abs(offsetY);
    
    if(direction == Direction.UP_RIGHT){
      screenLimits.incrementX(offsetX);
      screenLimits.incrementY(offsetY);
    }
        
    if(direction == Direction.UP_LEFT){
      screenLimits.decrementX(offsetX);
      screenLimits.incrementY(offsetY);
    }    
    
    if(direction == Direction.DOWN_RIGHT){
      screenLimits.incrementX(offsetX);
      screenLimits.decrementY(offsetY);
    }    
    
    if(direction == Direction.DOWN_LEFT){
      screenLimits.decrementX(offsetX);
      screenLimits.decrementY(offsetY);
    }
        
    drawView();
}

void keyPressed() {
  
  if( key == plusButton) {
    n++;
    drawView();
  } else if( key == minusButton && n!= 1) {
    n--;
    drawView();
  }
    
}
