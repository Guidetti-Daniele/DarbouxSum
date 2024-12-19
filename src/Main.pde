import java.text.DecimalFormat; //<>//

// Constants for colors
final color AXIS_COLOR = color(255);
final color FUNCTION_COLOR = color(255, 0, 0);
final color TEXT_COLOR = color(255);
final color GRID_COLOR = color(255, 255, 255, 50);
final color LIMITS_COLOR = color(0, 255, 0); // it will be removed
final color LOWER_RECTANGLE_COLOR = color(0, 255, 0, 80);
final color UPPER_RECTANGLE_COLOR = color(128, 0, 128, 160);
final color INFO_TEXT_COLOR = color(0, 255, 255);

// Constants for text
final int ZOOM_TEXT_SIZE = 15;
final int LEGEND_TEXT_SIZE = 12;
final int DARBOUX_TEXT_SIZE = 15;

final int LEGEND_TEXT_OFFSET = 15;

// Variables to manage unit of measurementunit and zoom
float unit = 50; // it means that 1 unit corresponds to 50px on the screen
DecimalFormat unitFormatter;
int unitDecimalPlaces = 0;

float zoom = 1.0;
float zoomAmount = 0.1;

// Variables to manage drag
ScreenLimits screenLimits;

float dragSensibility = 0.1;
PVector dragPivotPoint;

enum Direction {
  UP_RIGHT,
    UP_LEFT,
    DOWN_RIGHT,
    DOWN_LEFT
}

Direction dragDirection;

// Variables to implement Darboux's sum
int n = 10;
float lowerBound = 0;
float upperBound = 40;

final char plusButton = '+';
final char minusButton = '-';

float myFunction(float x) {
  return -0.1*pow(x, 2)+5*x+3;
}

void moveToOrigin() {
  pushMatrix();
  PVector origin = screenLimits.getOrigin();
  translate(origin.x, origin.y);
}

void drawAxis() {
  stroke(AXIS_COLOR);

  PVector origin = screenLimits.getOrigin();
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

  float unitValue = 1.0f;
  float[] ratios = {0.5, 0.2};
  float multiplier = 0.1f;

  if (zoom < 1) {
    ratios[0] = 2f;
    ratios[1] = 5f;
    multiplier = 10f;
    numberOfTimesHalved = abs(numberOfTimesHalved);
  }

  unitValue = (numberOfTimesHalved % 3 != 0) ? ratios[(numberOfTimesHalved % 3)-1] * pow(multiplier, numberOfTimesHalved / 3) : pow(multiplier, numberOfTimesHalved / 3);

  return unitValue;
}

String generateFormatterPattern() {

  if (unitDecimalPlaces <= 0) return "#";

  String pattern = "#.";

  for (int i=0; i < unitDecimalPlaces; i++)
    pattern += "#";

  return pattern;
}

void drawXLegend(int numberOfUnits, float xStartingPixels, float yStartingPixels, float yEndingPixels, float unitPixels, float unitValue, float verticalTextPosition) {
  // Setting text parameters
  textSize(LEGEND_TEXT_SIZE);
  textAlign(LEFT);

  for (int i=0; i < numberOfUnits/unitValue; i++) {
    float barlinePosition = xStartingPixels + unitPixels*unitValue*i;
    String barlineText = unitFormatter.format(barlinePosition / unitPixels);

    if (barlineText.equals("-0") || barlineText.equals("0") ) continue;

    //Drawing the barline
    stroke(GRID_COLOR);
    line(barlinePosition, yStartingPixels, barlinePosition, yEndingPixels);

    // Drawing the barline text
    fill(TEXT_COLOR);
    text(barlineText, barlinePosition-textWidth(barlineText)/2, verticalTextPosition);
  }
}


void drawYLegend(int numberOfUnits, float yStartingPixels, float xStartingPixels, float xEndingPixels, float unitPixels, float unitValue, float horizontalTextPosition) {
  // Setting text parameters
  textSize(LEGEND_TEXT_SIZE);
  textAlign(LEFT);

  for (int i=0; i < numberOfUnits/unitValue; i++) {
    float barlinePosition = yStartingPixels + unitPixels*unitValue*i;
    String barlineText = unitFormatter.format(-barlinePosition / unitPixels);

    if (barlineText.equals("-0") || barlineText.equals("0") ) continue;

    //Drawing the barline
    stroke(GRID_COLOR);
    line(xStartingPixels, barlinePosition, xEndingPixels, barlinePosition);

    // Drawing the barline text
    fill(TEXT_COLOR);
    text( barlineText, (horizontalTextPosition < 0) ? horizontalTextPosition - textWidth(barlineText) : horizontalTextPosition, barlinePosition+(LEGEND_TEXT_SIZE/4) );
  }
}

float roundToTheNextMultiple(float number, float base) {
  float previousMultiple = number - (number % base);
  float nextMultiple = previousMultiple + (number>0 ? base : -base);

  return nextMultiple;
}

void drawLegend() {
  moveToOrigin();

  // I set up some parameters for the text in order to draw it correctly
  float xAxisTextPosition = LEGEND_TEXT_OFFSET;
  float yAxisTextPosition = LEGEND_TEXT_OFFSET;

  // I make the position of the legend sticky if the axis aren't in view
  if (screenLimits.left > 0)
    yAxisTextPosition += screenLimits.left;
  else if (screenLimits.right < 0)
    yAxisTextPosition = -yAxisTextPosition + screenLimits.right;

  if (screenLimits.up < 0)
    xAxisTextPosition += -screenLimits.up;
  else if (screenLimits.down > 0)
    xAxisTextPosition = -xAxisTextPosition - screenLimits.down;

  // Now I get how many units I can draw into the screen

  float zoomedUnit = unit*zoom;
  int xBarlinesCount = ceil(width/zoomedUnit);
  int yBarlinesCount = ceil(height/zoomedUnit);

  // I get the value of the unit
  float unitValue = getUnitValue(xBarlinesCount);

  // I set the formatting of the legend
  String pattern = generateFormatterPattern();
  unitFormatter.applyPattern(pattern);

  // Calculanting the starting and the ending values for each axis
  float xStartingPixels = roundToTheNextMultiple(screenLimits.left, zoomedUnit*unitValue);
  float xEndingPixels = roundToTheNextMultiple(screenLimits.right, zoomedUnit*unitValue);

  float yStartingPixels = -roundToTheNextMultiple(screenLimits.up, zoomedUnit*unitValue);
  float yEndingPixels = -roundToTheNextMultiple(screenLimits.down, zoomedUnit*unitValue);

  // Drawing grid
  drawXLegend(xBarlinesCount+2, xStartingPixels, yStartingPixels, yEndingPixels, zoomedUnit, unitValue, xAxisTextPosition);
  drawYLegend(yBarlinesCount+2, yStartingPixels, xStartingPixels, xEndingPixels, zoomedUnit, unitValue, yAxisTextPosition);

  popMatrix();
}

void drawZoomText() {
  String text = String.format("Zoom: %d %%", round(100*zoom));
  fill(TEXT_COLOR);
  textSize(ZOOM_TEXT_SIZE);
  text(text, 40, 40);
}

// This function was used to debug
//void drawScreenLimitsText() {
//  fill(LIMITS_COLOR);
//  text(screenLimits.left, 0, height/2);
//  text(screenLimits.right, width-50, height/2);
//  text(screenLimits.up, width/2, 10);
//  text(screenLimits.down, width/2, height-10);
//}

void drawMyFunction() {
  moveToOrigin();

  stroke(FUNCTION_COLOR);
  noFill();

  float zoomedUnit = unit*zoom;

  beginShape();
  for ( float x = screenLimits.left/zoomedUnit; x <= screenLimits.right/zoomedUnit; x += 1/zoomedUnit)
    vertex(x*zoomedUnit, -myFunction(x)*zoomedUnit);
  endShape();

  popMatrix();
}

float[] getMinAndMaxInInterval(float a, float b) {
  float max = Float.NEGATIVE_INFINITY;
  float min = Float.POSITIVE_INFINITY;

  for (float x=a; x <= b; x += 1/(unit*zoom)) {
    float y = myFunction(x);

    if (y > max)
      max = y;

    if (y < min)
      min = y;
  }

  return new float[] {min, max};
}

void drawDarbouxSum() {
  float rectWidth = (upperBound-lowerBound)/n;
  
  float lowerArea = 0f;
  float upperArea = 0f;
  float min = 0f;
  float max = 0f;

  moveToOrigin();

  float zoomedUnit = unit*zoom;

  // Default rect mode is CORNER, so I have to specify the upperLeft corner for each rectangle
  for (float i=0; i<n; i++) {
    // Getting the bounds of the interval
    float a = lowerBound+rectWidth*i;
    float b = a + rectWidth;

    // Getting the min and max values for y in the interval
    float[] minAndMax = getMinAndMaxInInterval(a, b);
    min = minAndMax[0];
    max = minAndMax[1];

    stroke(UPPER_RECTANGLE_COLOR);
    fill(UPPER_RECTANGLE_COLOR);
    rect(a*zoomedUnit, -max*zoomedUnit, rectWidth*zoomedUnit, max*zoomedUnit);
    upperArea += rectWidth * max;

    stroke(LOWER_RECTANGLE_COLOR);
    fill(LOWER_RECTANGLE_COLOR);
    rect(a*zoomedUnit, -min*zoomedUnit, rectWidth*zoomedUnit, min*zoomedUnit);
    lowerArea += rectWidth * min;
  }

  // Drawing all the info
  fill(INFO_TEXT_COLOR);
  textSize(DARBOUX_TEXT_SIZE);
  String text = String.format("n = %d \nArea somma inferiore = %f \nArea somma superiore = %f", n, lowerArea, upperArea);
  text(text, (upperBound*zoomedUnit)+10, -(max*zoomedUnit+10));

  popMatrix();
}

void drawView() {
  background(0);

  drawZoomText();
  //drawScreenLimitsText();
  drawAxis();
  drawLegend();
  drawDarbouxSum();
  drawMyFunction();
}

void setup() {
  size(1000, 600);
  screenLimits = new ScreenLimits();
  unitFormatter = new DecimalFormat();

  drawView();
}

void draw() {

  if (mousePressed) {
    dragPivotPoint = new PVector(mouseX, mouseY);
  }
}

void mouseWheel(MouseEvent event) {

  if (event.getCount() > 0) // the wheel goes down
    zoom = (zoom-zoomAmount) < zoomAmount ? zoomAmount : (zoom-zoomAmount);
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
