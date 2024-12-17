import java.text.DecimalFormat; //<>//

// Constants for colors
final color AXIS_COLOR = color(255);
final color FUNCTION_COLOR = color(255, 0, 0);
final color TEXT_COLOR = color(255);
final color GRID_COLOR = color(255, 255, 255, 50);
final color RECTANGULAR_COLOR = color(0, 255, 0);
final color LIMITS_COLOR = color(0, 255, 0); // it will be removed

// Variables to manage unit of measurementunit and zoom
float unit = 50; // it means that 1 unit corresponds to 50px on the screen
DecimalFormat unitFormatter;
int unitDecimalPlaces = 0;

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

Direction dragDirection;

// Variables to implement Rienmann's sum
int n = 10;
float lowerBound = 0;
float upperBound = 10;

final char plusButton = '+';
final char minusButton = '-';

float myFunction(float x) {
  return x*x;
}

void moveToOrigin() {
  pushMatrix();
  Point2D origin = screenLimits.getOrigin();
  translate(origin.x, origin.y);
}

void drawAxis() {
  stroke(AXIS_COLOR);

  Point2D origin = screenLimits.getOrigin();
  // y-axis
  line(origin.x, 0, origin.x, height);
  // x-axis
  line(0, origin.y, width, origin.y);
}

float getUnitValue(float numberOfZoomedUnits) {

  int numberOfUnitsWithNoZoom = ceil(width/unit);
  int numberOfTimesHalved = floor( log(numberOfZoomedUnits/numberOfUnitsWithNoZoom) / log(0.5) );
  unitDecimalPlaces = numberOfTimesHalved;

  if (numberOfTimesHalved == 0) return 1.0;

  float unitValue = 1.0;
  float[] ratios = {0.5, 0.2};

  unitValue = (numberOfTimesHalved % 3 != 0) ? ratios[(numberOfTimesHalved % 3)-1] * pow(0.1, numberOfTimesHalved / 3) : pow(0.1, numberOfTimesHalved / 3);

  return unitValue;
}

String generateFormatterPattern() {
  String pattern = "#.";

  for (int i=0; i < unitDecimalPlaces; i++)
    pattern += "#";

  return pattern;
}

void drawXLegend(int numberOfUnits, float xStartingPixels, float yStartingPixels, float yEndingPixels, float unitPixels, float unitValue, float textSize, float verticalTextPosition) {
  // Setting text parameters
  textSize(textSize);
  textAlign(LEFT);

  for (int i=0; i < numberOfUnits; i++) {
    float barlinePosition = xStartingPixels + unitPixels*i;
    String barlineText = unitFormatter.format(barlinePosition / unitPixels);

    if (barlineText.equals("0")) continue;

    //Drawing the barline
    stroke(GRID_COLOR);
    line(barlinePosition, yStartingPixels, barlinePosition, yEndingPixels);

    // Drawing the barline text
    fill(TEXT_COLOR);
    text(barlineText, barlinePosition-textWidth(barlineText)/2, verticalTextPosition);
  }
}


void drawYLegend(int numberOfUnits, float yStartingPixels, float xStartingPixels, float xEndingPixels, float unitPixels, float unitValue, float textSize, float horizontalTextPosition) {
  // Setting text parameters
  textSize(textSize);
  textAlign(LEFT);

  for (int i=0; i < numberOfUnits; i++) {
    float barlinePosition = yStartingPixels + unitPixels*i;
    String barlineText = unitFormatter.format(barlinePosition / unitPixels);

    if (barlineText.equals("0")) continue;

    //Drawing the barline
    stroke(GRID_COLOR);
    line(xStartingPixels, barlinePosition, xEndingPixels, barlinePosition);

    // Drawing the barline text
    fill(TEXT_COLOR);
    text( barlineText, (horizontalTextPosition < 0) ? horizontalTextPosition - textWidth(barlineText) : horizontalTextPosition, barlinePosition+(textSize/4) );
  }
}

float roundToTheNextMultiple(float number, float base) {
  float previousMultiple = number - (number % base);
  float nextMultiple = previousMultiple + (number>0 ? base : -base);
  
  return nextMultiple;
}

void drawLegend() {
  moveToOrigin();

  /*
    I set up some parameters for the text in order to draw it correctly
   */
  final float textSize = 12f;
  final float textDistance = 15f;
  float xAxisTextPosition = textDistance;
  float yAxisTextPosition = textDistance;

  if (screenLimits.left > 0)
    yAxisTextPosition += screenLimits.left;
  else if (screenLimits.right < 0)
    yAxisTextPosition = -yAxisTextPosition + screenLimits.right;

  if (screenLimits.up < 0)
    xAxisTextPosition += -screenLimits.up;
  else if (screenLimits.down > 0)
    xAxisTextPosition = -xAxisTextPosition - screenLimits.down;

  /*
   Now I get how many units I can draw into the screen
   */
  float zoomedUnit = unit*zoom;
  int xBarlinesCount = ceil(width/zoomedUnit);
  int yBarlinesCount = ceil(height/zoomedUnit);

  float unitValue = getUnitValue(xBarlinesCount);

  String pattern = (unitDecimalPlaces != 0) ? generateFormatterPattern() : "#";
  unitFormatter.applyPattern(pattern);


  /*
    I know how many barlines I have to draw on the two axis,
   but I have to get the values of the bounds.
   */
  //float xDisplacement = (screenLimits.right-width/2) / zoomedUnit;
  //float maxX = ceil((xBarlinesCount/2)+xDisplacement);
  //float minX = maxX - xBarlinesCount - 1;

  /*
    Now I have to do the same for the y axis,
   but I have to INVERT THE SIGN
   */
  //float yDisplacement = (screenLimits.up-height/2) / zoomedUnit;
  //float maxY = ceil((yBarlinesCount/2)+yDisplacement);
  //float minY = maxY - yBarlinesCount - 1;

  // Calculanting the starting and the ending values for each axis
  float xStartingPixels = roundToTheNextMultiple(screenLimits.left, zoomedUnit);
  float xEndingPixels = roundToTheNextMultiple(screenLimits.right, zoomedUnit);
  
  float yStartingPixels = -roundToTheNextMultiple(screenLimits.up, zoomedUnit);
  float yEndingPixels = -roundToTheNextMultiple(screenLimits.down, zoomedUnit);

  println("xStart: ", xStartingPixels / zoomedUnit, "xEnd: ", xEndingPixels / zoomedUnit);
  println("yStart: ", yStartingPixels  / zoomedUnit, "End: ", yEndingPixels  / zoomedUnit);

  // Drawing grid
  drawXLegend(xBarlinesCount+2, xStartingPixels, yStartingPixels, yEndingPixels, zoomedUnit, unitValue, textSize, xAxisTextPosition);
  drawYLegend(yBarlinesCount+2, yStartingPixels, xStartingPixels, xEndingPixels, zoomedUnit, unitValue, textSize, yAxisTextPosition);

  //for (float i = minX; i <= maxX; i+= incrementer) {
  //  String formatted = unitFormatter.format(i);
  //  float formattedNumber = Float.valueOf( formatted.replace(',','.') );

  //  if (formattedNumber == 0.0) continue;

  //  float x = zoomedUnit * formattedNumber;
  //  stroke(GRID_COLOR);
  //  line(x, -(zoomedUnit * maxY), x, -zoomedUnit*minY);

  //  fill(TEXT_COLOR);
  //  text(formatted, x-textWidth(formatted)/2, xAxisTextPosition);
  //}

  //for (float i = minY; i <= maxY; i+= incrementer) {
  //  String formatted = unitFormatter.format(i);
  //  float formattedNumber = Float.valueOf( formatted.replace(',','.') );

  //  if (formattedNumber == 0.0) continue;

  //  float y = zoomedUnit*formattedNumber;
  //  stroke(GRID_COLOR);
  //  line(zoomedUnit*minX, -y, zoomedUnit*maxX, -y);

  //  fill(TEXT_COLOR);
  //  text(formatted, (yAxisTextPosition<0) ? yAxisTextPosition-textWidth(formatted) : yAxisTextPosition, -y+(textSize/4));
  //}

  popMatrix();
}

void drawZoomText() {
  String text = String.format("Zoom: %d %%", round(100*zoom));
  fill(TEXT_COLOR);
  text(text, 40, 40);
}

void drawScreenLimitsText() {
  fill(LIMITS_COLOR);
  text(screenLimits.left, 0, height/2);
  text(screenLimits.right, width-50, height/2);
  text(screenLimits.up, width/2, 10);
  text(screenLimits.down, width/2, height-10);
}

void drawMyFunction() {
  moveToOrigin();

  stroke(FUNCTION_COLOR);
  noFill();

  float zoomedUnit = unit*zoom;

  beginShape();
  for ( float x = screenLimits.left/zoomedUnit; x <= screenLimits.right/zoomedUnit; x+= (1/zoomedUnit))
    vertex(x*zoomedUnit, -myFunction(x)*zoomedUnit);
  endShape();

  popMatrix();
}

void drawRienmannSum() {
  float rectWidth = zoom*(upperBound-lowerBound)/n;
  float rectHeight = 0;

  moveToOrigin();

  noStroke();
  fill(RECTANGULAR_COLOR);
  rectMode(CENTER);

  for (float i=lowerBound*zoom; i <= upperBound*zoom; i+= rectWidth) {
    float middleX = i+(rectWidth/2);
    rectHeight = myFunction(i/zoom);
    rect(middleX, (-rectHeight)/2, rectWidth, rectHeight);
  }

  String text = String.format("n=%d", n);
  fill(255);
  text(text, (upperBound*zoom)+10, -(rectHeight+10));

  popMatrix();
}

void drawView() {
  background(0);

  drawZoomText();
  drawScreenLimitsText();
  drawAxis();
  drawLegend();
  drawMyFunction();
  //drawRienmannSum();
}

void setup() {
  size(1000, 600);
  screenLimits = new ScreenLimits();
  unitFormatter = new DecimalFormat();

  drawView();
}

void draw() {

  if (mousePressed) {
    dragPivotPoint = new Point2D(mouseX, mouseY);
  }
}

void mouseWheel(MouseEvent event) {

  if (event.getCount() > 0) // the wheel goes down
    zoom = (zoom-zoomAmount) < 1 ? 1 : (zoom-zoomAmount);
  else
    zoom += zoomAmount;

  drawView();
}

Direction getDirection(float offsetX, float offsetY) {

  if (offsetX >= 0 && offsetY >= 0)
    return Direction.UP_LEFT;

  if (offsetX >= 0 && offsetY < 0)
    return Direction.DOWN_LEFT;

  if (offsetX < 0 && offsetY >= 0)
    return Direction.UP_RIGHT;

  return Direction.DOWN_RIGHT;
}

void mouseDragged() {

  if (dragPivotPoint == null) return;

  cursor(MOVE);

  float offsetX = mouseX - dragPivotPoint.x;
  float offsetY = mouseY - dragPivotPoint.y;

  dragDirection = getDirection(offsetX, offsetY);
  offsetX = abs(offsetX);
  offsetY = abs(offsetY);

  if (dragDirection == Direction.UP_RIGHT) {
    screenLimits.incrementX(offsetX);
    screenLimits.incrementY(offsetY);
  }

  if (dragDirection == Direction.UP_LEFT) {
    screenLimits.decrementX(offsetX);
    screenLimits.incrementY(offsetY);
  }

  if (dragDirection == Direction.DOWN_RIGHT) {
    screenLimits.incrementX(offsetX);
    screenLimits.decrementY(offsetY);
  }

  if (dragDirection == Direction.DOWN_LEFT) {
    screenLimits.decrementX(offsetX);
    screenLimits.decrementY(offsetY);
  }

  drawView();
}

void mouseReleased() {
  cursor(ARROW);
}

void keyPressed() {

  if ( key == plusButton) {
    n++;
    drawView();
  } else if ( key == minusButton && n!= 1) {
    n--;
    drawView();
  }
}
