import netP5.*;
import oscP5.*;
import java.util.List;
import java.util.LinkedHashMap;

OscP5 oscP5;
NetAddress remote;

//MelodyMatrix matrix;
Instrument selectedInstrument;

LinkedHashMap<Character, Instrument> instruments;

// CONSTANTS
int CHUNK_SIZE = 16;
int GRID_WIDTH = 64;
int GRID_HEIGHT = 32;
color BG_COLOR = color(0, 0, 0, 50);
color eraserColor = color(240, 20, 20);
int TOOLBAR_HEIGHT = 150;

int startTime = 0;
float timeLineX = 0;
int tempo = 300; // bpm 

boolean isDraggingSlider= false;

List<DrawnNote> drawnNotes = new ArrayList<>();
List<ParticleEffect> particleEffects = new ArrayList<>();

boolean isErasing = false;
PFont light, heavy;

void setup() {
  oscP5 = new OscP5(this, 6001); // Receive messages from MAX (waveform value snapshots) 
  remote = new NetAddress("127.0.0.1", 6000); // Send values to MAX (which notes to play)
  //matrix = new MelodyMatrix();
  
  colorMode(HSB, 365, 100, 100);

  instruments = new LinkedHashMap<>();
  instruments.put('s', new Instrument("Synth", "synth1", color(282, 100, 100), Shape.LINE, 1));
  instruments.put('b', new Instrument("Bass", "bass", color(228, 100, 85), Shape.LINE, 1));
  instruments.put('p', new Instrument("Piano", "piano", color(180, 100, 100), Shape.LINE, 1));
  instruments.put('k', new Instrument("Kick Drum", "kick", color(0, 60, 100), Shape.SQUARE, 1));
  instruments.put('h', new Instrument("High Hat", "highhat", color(49, 100, 100), Shape.RECT, 1));
  instruments.put('d', new Instrument("Snare Drum", "snare", color(120, 100, 100), Shape.SQUARE, 1));
  
  selectedInstrument = instruments.get('s'); // default to synth 1
  
  light = createFont("light.ttf", 24);
  heavy = createFont("heavy.ttf", 18);

  size(16*64, 16*32 + 150); // each 12x12 chunk of pixels on screen will correspond to one entry in our pixels[][] matrix.
  rectMode(CENTER);
  
  background(0);
  
  //selectInput("Select a file to process", "fileSelected");
  
  startTime = millis();
}

color bgColor = color(200, 80, 100, 0);
int bgColorHue = 200;
int drawCount = 0;
  
void draw() {
  fill(bgColor);
  rect(0, 0, width, height-TOOLBAR_HEIGHT);
  
  textFont(light);
  strokeWeight(1);
  noFill();
  stroke(0, 0, 25);
  for (int i = 0; i < GRID_WIDTH; i++) {
    for (int j = 0; j < GRID_HEIGHT; j++) {
      if (i % 4 == 0) fill(0, 0, 100, 40);
      else noFill();
      square(i * CHUNK_SIZE, j * CHUNK_SIZE, CHUNK_SIZE); 
    }
  } 

  float biggestKickProxMultiplier = 0; // only adjust background color by the kick which was most recently played.
  drawTimeLine();
  
  noStroke();
  rectMode(CENTER);
  for (DrawnNote note : drawnNotes) {
    // every time the time line passes the drawn note, rotate slightly.
    float x = (note.location.x + 0.5) * CHUNK_SIZE; 
    float y = (note.location.y + 0.5) * CHUNK_SIZE;
    
    // when timeline hits the note
    if (timeLineX >= x) {
      // If we haven't played this note yet, play it. 
      if (!note.hasPlayed) {
        note.rotation += (random(0.1) - 0.05) * PI;
        note.hasPlayed = true;
        playNote(note);
      
        
        particleEffects.add(new ParticleEffect(new Point(x, y), color(note.instrument.color_), note.instrument.particleSize)); // spawn a particle effect when playedd
      }
    }
 
     switch (note.instrument.shape) {
        case SQUARE: 
          pushMatrix();
          float timeLineProximityMultiplier = timeLineProximityCurve(x, 0.6f, 0.6f, 0.05f);
          fill(lerpColor(note.instrument.color_, color(0, 0, 255), timeLineProximityMultiplier - 1f));
          
          translate(x, y); // set origin of rotation to middle of square
          rotate(note.rotation);
          square(0, 0, 30 * timeLineProximityMultiplier);
          
          if (timeLineProximityMultiplier > biggestKickProxMultiplier&& note.instrument.mspIdentifier.equals("kick")) {
            biggestKickProxMultiplier = timeLineProximityMultiplier;
          }
          popMatrix();
          break;
        case RECT:
          timeLineProximityMultiplier = timeLineProximityCurve(x, 0.6f, 0.6f, 0.05f);
          fill(lerpColor(note.instrument.color_, color(255), timeLineProximityMultiplier - 2f));
          rect(x, y, 35 * timeLineProximityMultiplier, 10 * timeLineProximityMultiplier);
          break;
        case LINE:
          timeLineProximityMultiplier = timeLineProximityCurve(x, 1.5f, 0.1f, 0.1f); // value from 1-2 indicating how close this chunk is to the timeline
          fill(lerpColor(note.instrument.color_, color(0, 0, 255), (timeLineProximityMultiplier - 1f)/(1.5f)));
          square(x, y, CHUNK_SIZE * timeLineProximityMultiplier);
          break;
        default: 
          continue;
    }
  }
  
  // draw particle effects
  List<ParticleEffect> completedEffects = new ArrayList<>();
  for (ParticleEffect effect: particleEffects) {
    effect.draw(); 
    if (effect.isComplete()) {
      completedEffects.add(effect);
    }
  }
  // after drawing all effects, remove remaining ones
  particleEffects.removeAll(completedEffects); 
  
  // when kicks are hit, flash background color
  float kickProxM = max(biggestKickProxMultiplier, 1) - 1;
  bgColor = color(bgColorHue, saturation(bgColor), 15+18*kickProxM);
  if (drawCount % 3 == 0) bgColorHue++;
  if (bgColorHue > 360) bgColorHue-=360;
  
  // For line-type instruments, liten to mousePressed in draw() so we can draw continuous lines
  if ((isErasing && mousePressed) || (mousePressed && selectedInstrument.shape == Shape.LINE && mouseY < height - TOOLBAR_HEIGHT)) {
    drawNote();
  }
  
  rectMode(CORNER);
  fill(BG_COLOR);
  rect(0, height-TOOLBAR_HEIGHT, width, TOOLBAR_HEIGHT);
  fill(0, 0, 255);
  textFont(heavy);
  text("Instrument: ", 15, height-110);
  fill(isErasing ? eraserColor :selectedInstrument.color_);
  text(isErasing ? "Eraser" : selectedInstrument.name.toUpperCase(), 165, height-110);
  fill(0, 0, 100);
  textFont(light);
  drawInstrumentSelectorAndSliders();
  fill(0, 0, 100);
  text("CLEAR", 15, height-65);
  if (isErasing) fill(eraserColor);
  text("ERASER (e)", 15, height-25);
  
  drawCount++;
}

void drawTimeLine() {
  stroke(0, 0, 100);
  strokeWeight(4);
  
  float bps = (float) tempo / 60; // frequency
  float spb = 1. / bps; // seconds per beat (period)
  float mspb = 1000 * spb; // ms per beat 
  float widthPerBeat = (float)width / 16; 
  float timeElapsed = millis() - startTime;
  timeLineX = timeElapsed / mspb * widthPerBeat;
  
  // After every "measure", wrap around the timeline and reset hasPlayed to false for each note. 
  if (timeLineX >= width) {
    timeLineX -= width; // wrap around
    
    for (DrawnNote note: drawnNotes) {
      note.hasPlayed = false; 
    }
    startTime = millis();
  }
  
  line(timeLineX, 0, timeLineX, height - TOOLBAR_HEIGHT);
  
  noStroke();
}

void drawInstrumentSelectorAndSliders() {
   int xStart = width/2 + 30;
  text("Click or type key to select instrument: ", xStart - 70, height-TOOLBAR_HEIGHT+30);
  textAlign(CENTER);
  text("V\nO\nL\nU\nM\nE", xStart -25, height-TOOLBAR_HEIGHT+85);
  textFont(light);
  for (HashMap.Entry<Character, Instrument> entry : instruments.entrySet()) {
    Instrument instrument = entry.getValue();
    instrument.eqSlider.draw(xStart);
    
    textFont(heavy);
    if (instrument.mspIdentifier.equals(selectedInstrument.mspIdentifier)) {
      fill(instrument.color_); 
    } else {
      fill(0, 0, 100);
    }
    text(entry.getKey(), xStart + instrument.eqSlider.sliderWidth/2, height-90);
    // detect clicks on letters to switch letter
    if (mousePressed && xStart < mouseX && mouseX < xStart + instrument.eqSlider.sliderWidth && mouseY > height-90-18 && mouseY < height-90) {
      selectedInstrument = instrument;
      isErasing = false;
    }
    xStart = xStart + 15 + instrument.eqSlider.sliderWidth;
  } 
    textAlign(LEFT);

}

//// Select instruments based on key pressed.
void keyPressed() {
  if (key == 'e') {
    isErasing = true; 
    return;
  }
  if (!instruments.containsKey(key)) {
     return;
   }
   
   Instrument instrument = instruments.get(key); 
   isErasing = false;
   selectedInstrument = instrument;
}

// When drawing non-line notes (notes that are not bound to the MelodyMatrix), listen to clicks
// to store them in to the `drawnNotes`
void mousePressed() { 
   for (HashMap.Entry<Character, Instrument> entry : instruments.entrySet()) {
    entry.getValue().eqSlider.onMousePressed();
  }
  if (mouseY < height - TOOLBAR_HEIGHT && !isErasing) {
    if (selectedInstrument.shape == Shape.LINE) return; 
    drawNote();
  } else if (mouseY > (height - TOOLBAR_HEIGHT + 55) && mouseX < 145) {
    // clicked clear button 
    if (mouseY < height - 55) {
      drawnNotes.clear();
      isErasing = false;
    } else {
      isErasing = !isErasing; 
    }
  }
}

void mouseReleased() {
  for (HashMap.Entry<Character, Instrument> entry : instruments.entrySet()) {
    entry.getValue().eqSlider.onMouseReleased();
  }
}

void mouseDragged() {
  OscMessage myMessage = new OscMessage("/eq");
 
  for (HashMap.Entry<Character, Instrument> entry : instruments.entrySet()) {
    entry.getValue().eqSlider.onMouseDragged();
    myMessage.add(entry.getValue().eqSlider.value);
  }
  
  if (isDraggingSlider) {
    oscP5.send(myMessage, remote);
  }
}

void drawNote() {
  if (isDraggingSlider) return; 
  
  float x = (mouseX) / CHUNK_SIZE;
  float y = (mouseY) / CHUNK_SIZE;
  
  if (x < 0 || x > GRID_WIDTH - 1) return;
  if (y < 0 || y > GRID_HEIGHT - 1) return;
  
  // Make sure that this note has not already been drawn 
  for (DrawnNote note : drawnNotes) {
    boolean locMatches = note.location.x == x && note.location.y == y;
    if (isErasing && locMatches) {
      drawnNotes.remove(note);
      return;
    } 
    // Drawing a note with an instrument that already has been drawn, skip.
    else if (!isErasing && locMatches && note.instrument.mspIdentifier == selectedInstrument.mspIdentifier) {
      return;
    }
  }
  if (isErasing) return; // erased on nothing, do nothing.
    
  Point p = new Point(x, y); 
  drawnNotes.add(new DrawnNote(p, selectedInstrument));
}

float timeLineProximityCurve(float posX, float maxMultiplier, float growthRate, float decayRate) {
  if (timeLineX > posX) {
    return (float) (1 + maxMultiplier * Math.exp(-decayRate*(timeLineX-posX)));
  } else {
    return (float) (1 + maxMultiplier * Math.exp(growthRate*(timeLineX-posX)));
  }
}

void playNote(DrawnNote note) {
   OscMessage myMessage = new OscMessage("/play");
   myMessage.add(note.instrument.mspIdentifier);
   myMessage.add(note.location.y);
   oscP5.send(myMessage, remote);
}
