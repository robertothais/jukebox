#include <Adafruit_NeoPixel.h>

#define PIN 6
#define lightCount 60
#define INPUT_SIZE 3

Adafruit_NeoPixel strip = Adafruit_NeoPixel(lightCount, PIN, NEO_GRB + NEO_KHZ800);

const int maxChange = 2;
const float velocity = 10.0; // in leds per second
const int wait = 3; // in milliseconds
const int maxBeats = 15;
const int numSlots = strip.numPixels() / 2;

float beats[maxBeats] = {};
int beatRepeats[maxBeats] = {};
uint32_t beatColors[maxBeats] = {};
uint32_t oldBeatColor;
int mostRecentBeat = 0;

void setTargetColor(uint32_t targetColor) {

  oldBeatColor = beatColors[mostRecentBeat];

  int currentRepetitionCount = beatRepeats[mostRecentBeat];

  mostRecentBeat = ( mostRecentBeat + 1 ) % maxBeats;

  // set beat location and beatcolors
  beats[mostRecentBeat] = 0;
  beatColors[mostRecentBeat] = targetColor;

  // track how many times this color has repeated
  if(beatColors[mostRecentBeat] == oldBeatColor) {
    beatRepeats[mostRecentBeat] = currentRepetitionCount + 1;
  }
  else {
    beatRepeats[mostRecentBeat] = 0;
  }
}


void receiveBeat() {
  uint8_t raw[INPUT_SIZE];

  int amount = Serial.readBytes(raw, INPUT_SIZE);

  uint32_t red = (256L * raw[0]) * 256L;
  uint16_t green = (256 * raw[1]);
  uint8_t  blue  = raw[2];

  uint32_t fullColor = red+green+blue;

  setTargetColor(fullColor);
}

void setup() {
  Serial.begin(9600);
  strip.begin();

  for(int x = 0; x < lightCount; x++ ){
    strip.setPixelColor(x, strip.Color(0,0,0));
  }

  strip.show(); // Initialize all pixels to 'off'
}

uint8_t splitColor (uint32_t c, char value) {
  switch ( value ) {
    case 'r': return (uint8_t)(c >> 16);
    case 'g': return (uint8_t)(c >>  8);
    case 'b': return (uint8_t)(c >>  0);
    default:  return 0;
  }
}

void loop() {

  // read in commands
  if (Serial.available() > 0) {
    receiveBeat();
  }

  // move the beats at specified velocity
  for( int x = 0; x < maxBeats; x++ ) {
    beats[x] += velocity * wait / 100.0;
  }

  // set colors on the strip
  // start in the center and proceed outward
  int currentBeatIndex = mostRecentBeat;

  for( int k = 0; k < numSlots; k++ ) {
    // choose the relevant beatindex based on the beat locations and current location on the strip
    if( k > beats[currentBeatIndex] ) {
      int newBeatIndex = ( currentBeatIndex - 1 + maxBeats ) % maxBeats;

      if( newBeatIndex == mostRecentBeat ) {
        break;
      }

      currentBeatIndex = newBeatIndex;
    }

    // calculate intensity for the color at this pixel
    float intrabeatTrailOff = constrain((25.0 - ( beats[currentBeatIndex] - k ))/25.0,0,1.0); // beat trails off after initial hit
    float distanceTrailOff = constrain(0.8 * float(5 + numSlots - k)/float(numSlots),0.0,1.0); // intensity goes down with distance from center
    float repetitionTrailOff = constrain(float((4.0 - beatRepeats[currentBeatIndex]) / 4.0),0.3,1.0); // lessen intensity for repeated chords.  puts more emphasis on chord changes

    float intensity = intrabeatTrailOff * distanceTrailOff * repetitionTrailOff;

    uint32_t c = beatColors[currentBeatIndex];

    // set color based on the color for this beat and the intensity
    // could probably be done in a bitwise fashion on the unified color
    strip.setPixelColor(k + numSlots, (splitColor(c, 'r') * intensity), (splitColor(c, 'g') * intensity), (splitColor(c, 'b') * intensity));
    strip.setPixelColor(numSlots - k, (splitColor(c, 'r') * intensity), (splitColor(c, 'g') * intensity), (splitColor(c, 'b') * intensity));
  }

  strip.show();

  delay(wait);
}
