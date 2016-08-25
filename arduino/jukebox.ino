#include <StandardCplusplus.h>
#include <vector>
#include <Adafruit_NeoPixel.h>

#define PIN 6
#define INPUT_SIZE 200
//std::vector< std::vector<uint32_t> > palettes;
const int segments = 1;
const int segmentSize = 60;
float offset = 0.0;
float lastBeatTransition = 1.0; // percentage from 0 to 100% - pulse with the beat
float lastPaletteTransition = 1.0; // percentage from 0 to 100% - interpolate between palettes
float lastPaletteFadeDown = 1.0; // percentage from 0 to 100% - brighten and fade after palette transition
int thisPalette = 0; // index
int lastPalette = -1;
float activeMode = 0.0;
float activeModeTransitionRate = 0.02;
float ambientModePulseCycle = 700;

int i = 0;

const int numPalettes = 6;
const int paletteSize = 5;
const uint8_t palettes[numPalettes][paletteSize][3] = {
   { //vive
     { 49,51,204 },
     { 53,162,255},
     { 233,233,255 },
     { 255,164,81 },
     { 204,76,13 }
   },
   { //gecko
     { 0,171,255 },
     { 0,232,193 },
     { 0,255,78 },
     { 62,232,0 },
     { 233,255,0 }
   },
   { //richard
     { 255,202,0 },
     { 232,141,4 },
     { 255,95,14 },
     { 232,24,10 },
     { 255,4,184 }
   },
   { //drank
    { 255,9,167 },
    { 161,10,232 },
    { 62,24,255 },
    { 18,91,232 },
    { 11,216,255 }
   },
  { //moorhead
    { 255,255,227 },
    { 162,242,255 },
    { 24,21,204 },
    { 204,0,58 },
    { 255,171,123 }
  },
  { //altj
    { 254,255,17 },
    { 232,142,12 },
    { 255,0,0 },
    { 108,12,232 },
    { 13,170,255 }
  }
};

float baseBrightness = 0.5;
float maxBeatBrightness = 0.7;
float maxPaletteTransitionBrightness = 1.0;
float rampUp = 0.12; // percentage of pulse to get to maximum brightness
float intraChordAttenuation = 0;
float intraChordAttenuationMax = 0.50;
float intraChordAttenuationRate = 0.10;
double offsetProgressRate = 0.005;
double beatTransitionRate = 0.04;
double paletteTransitionRate = 0.20;
double paletteFadeDownRate = 0.08;
float activeTransHead;
float activeTransIntensity;
float activeTransTrailLength;
float ambientIntensity;

Adafruit_NeoPixel strip = Adafruit_NeoPixel(segments * segmentSize, PIN, NEO_GRB + NEO_KHZ800);

void processCommands() {
  byte size = Serial.read();

  if( size == 'i' ) {
    activeMode = 0.0;
    return;
  }
  else if( size == 'a' ) {
    activeMode = 0.001;
    return;
  }

  int newPalette = size % numPalettes;

  if( newPalette == thisPalette ) {
    lastBeatTransition = 0.0;
    intraChordAttenuation = std::min(intraChordAttenuationRate + intraChordAttenuation, intraChordAttenuationMax);
  }
  else {
    lastPalette = thisPalette;
    thisPalette = newPalette % numPalettes;
    lastPaletteTransition = 0.0;
    intraChordAttenuation = 0;
  }
}

void setRowColor(int k, uint32_t pixelColor) {
  for( int segment = 0; segment < segments; segment++ ) {
    if ( segment % 2 == 0 ) {
      strip.setPixelColor(segment * segmentSize + k,pixelColor);
    } else {
      strip.setPixelColor(segment * segmentSize + segmentSize - 1 - k,pixelColor);
    }
  }
}

void setPalette(int paletteIdx, float offsetPct, float beatTransition, int prevPalette, float prevPaletteTransition, float prevPaletteFadeDown) {
  int colorSpacing = floor(segmentSize / paletteSize );
  float offsetSlots = offsetPct * segmentSize;

  float brightness;
//  float whiteness;
//  float baseWhiteness = 0.0;

  // calculate brightness
  if ( prevPaletteTransition < 1.0 ) {
    brightness = ( baseBrightness + ( maxPaletteTransitionBrightness - baseBrightness ) * prevPaletteTransition );
  }
  else if ( prevPaletteFadeDown < 1.0 ) {
    brightness = ( baseBrightness + ( maxPaletteTransitionBrightness - baseBrightness ) * ( maxPaletteTransitionBrightness - prevPaletteFadeDown ) );
  }
  else if ( beatTransition < rampUp ) {
    brightness = ( maxBeatBrightness - baseBrightness ) / rampUp * beatTransition + baseBrightness;
  }
  else if ( beatTransition < 1.0 ) {
    brightness = ( baseBrightness - maxBeatBrightness ) / ( 1 - rampUp ) * beatTransition + ( maxBeatBrightness - rampUp * baseBrightness ) / ( 1 - rampUp );
  }
  else {
    brightness = baseBrightness;
  }

  brightness *= (1 - intraChordAttenuation);

//  Serial.println(brightness);

//  uint8_t white = std::min(255 * (brightness + 0.1),255.0);
//
//  // calculate whiteness
//  if( beatTransition < rampUp ) {
//    // go from base level whiteness to 100% for { 0 < beatTransition < rampUp }
//    whiteness = ( 1.0 - baseWhiteness ) / rampUp * beatTransition + baseWhiteness;
//  }
//  else {
//    // go from 100%  whiteness back to base level for { rampUp < beatTransition < 100% }
//    whiteness = ( baseWhiteness - 1 ) / ( 1 - rampUp ) * beatTransition + ( 1 - rampUp * baseWhiteness ) / ( 1 - rampUp );
//  }


  int loc1, loc2;
  uint8_t r1,g1,b1,r2,g2,b2,r,g,b,r1Prev,g1Prev,b1Prev,r2Prev,g2Prev,b2Prev,rPrev,gPrev,bPrev;
  float interpPctGradient;

  float kOffset;
  for( int k = 0; k < segmentSize; k++ ) {
    kOffset = fmod(k + offsetSlots,segmentSize);

    loc1 = floor(kOffset / colorSpacing);
    loc2 = floor(kOffset / colorSpacing) + 1;
    r1 = palettes[paletteIdx][loc1 % paletteSize][0];
    g1 = palettes[paletteIdx][loc1 % paletteSize][1];
    b1 = palettes[paletteIdx][loc1 % paletteSize][2];

    r2 = palettes[paletteIdx][loc2 % paletteSize][0];
    g2 = palettes[paletteIdx][loc2 % paletteSize][1];
    b2 = palettes[paletteIdx][loc2 % paletteSize][2];

    // interpolate between palette colors on strip
    interpPctGradient = ( kOffset - floor( kOffset / colorSpacing ) * colorSpacing ) / colorSpacing;
    //    interpPctGradient = -0.5*cos(interpPctGradient * PI) + 0.5;  // sinusoidal interpolation

    // calculate base colors along strip
    r = ((r2 - r1)*interpPctGradient + r1)*brightness;
    g = ((g2 - g1)*interpPctGradient + g1)*brightness;
    b = ((b2 - b1)*interpPctGradient + b1)*brightness;

//    // apply whiteness for pulsing beat
//    r = ( white - r ) * whiteness + r;
//    g = ( white - g ) * whiteness + g;
//    b = ( white - b ) * whiteness + b;

    // mix in new palette if we're in the midst of a palette transition
    if( prevPaletteTransition < 1.0 ) {
      r1Prev = palettes[prevPalette][loc1 % paletteSize][0];
      g1Prev = palettes[prevPalette][loc1 % paletteSize][1];
      b1Prev = palettes[prevPalette][loc1 % paletteSize][2];

      r2Prev = palettes[prevPalette][loc2 % paletteSize][0];
      g2Prev = palettes[prevPalette][loc2 % paletteSize][1];
      b2Prev = palettes[prevPalette][loc2 % paletteSize][2];

      rPrev = ((r2Prev - r1Prev)*interpPctGradient + r1Prev)*brightness;
      gPrev = ((g2Prev - g1Prev)*interpPctGradient + g1Prev)*brightness;
      bPrev = ((b2Prev - b1Prev)*interpPctGradient + b1Prev)*brightness;

      r = ( r - rPrev ) * prevPaletteTransition + rPrev;
      g = ( g - gPrev ) * prevPaletteTransition + gPrev;
      b = ( b - bPrev ) * prevPaletteTransition + bPrev;
    }

    // add in cool sweep effect if we're transitioning to active mode
    if( activeMode < 1.0 ) {
      activeTransTrailLength = 20.0;
      activeTransHead = ( segmentSize + activeTransTrailLength ) * activeMode;

      if( k > activeTransHead ) {
        r = 0;
        g = 0;
        b = 0;
      }
      else {
        activeTransIntensity = std::max((20.0 - activeTransHead + k ) / 20.0,0.0);

        r = r+(255-r)*activeTransIntensity;
        g = g+(255-g)*activeTransIntensity;
        b = b+(255-b)*activeTransIntensity;
      }
    }

    setRowColor(k,strip.Color(r,g,b));
  }
}

void setup() {
  Serial.begin(9600);

  // set all pixels to off
  strip.begin();
  for( int k = 0; k < strip.numPixels(); k++ ) {
    strip.setPixelColor(k,strip.Color(0,0,0));
  }
  strip.show();
}

void loop() {
  // read in commands
  if (Serial.available() > 0) {
    processCommands();
  }

  if( activeMode > 0 ) {
    setPalette(thisPalette,offset,lastBeatTransition,lastPalette,lastPaletteTransition,lastPaletteFadeDown);
    strip.show();

    // increment offset, and progress through beat and palette transitions
    offset = fmod(offset + offsetProgressRate,1.0);

    if ( lastBeatTransition < 1.0 ) {
      lastBeatTransition = std::min(lastBeatTransition + beatTransitionRate, 1.0 );
    }

    if ( lastPaletteFadeDown < 1.0 ) {
      lastPaletteFadeDown = std::min(lastPaletteFadeDown + paletteFadeDownRate, 1.0 );
    }

    if ( lastPaletteTransition < 1.0 ) {
      lastPaletteTransition = std::min( lastPaletteTransition + paletteTransitionRate, 1.0 );

      if( lastPaletteTransition == 1.0 ) {
        lastPaletteFadeDown = 0.0;
      }
    }

    if( activeMode < 1.0 ) {
      activeMode = std::min( activeMode + activeModeTransitionRate, float(1.0) );
    }
  }
  else {
    // ambient mode
    ambientIntensity = cos((i % int(ambientModePulseCycle))/ambientModePulseCycle*2*PI)*0.5+0.5;

    for( int k = 0; k < segmentSize; k++ ) {
      setRowColor(k,strip.Color(50*ambientIntensity,50*ambientIntensity,50*ambientIntensity));
    }
    strip.show();
  }

  i+=1;
  delay(1);
}
