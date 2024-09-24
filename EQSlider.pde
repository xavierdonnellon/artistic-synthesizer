class EQSlider {
  int handleHeight = 25;
  float value = 0.5;
  int top;
  int bottom;
  int sliderHeight = 65;
  int sliderWidth = 35;
  int vertPadding = 10;
  
  Instrument instrument;
  
  boolean isDragging = false;
  int xStart; 
  int xEnd;
  
  
  public EQSlider(Instrument instrument) {
    bottom = height - vertPadding/2;
    top = bottom - sliderHeight;
    
    this.instrument = instrument;
  }
  
  void draw(int xStart) {
    this.xStart = xStart;
    xEnd = xStart + sliderWidth;
    fill(0, 0, 40); // light gray background
    rect(xStart, top, sliderWidth, sliderHeight);
    
    fill(hue(instrument.color_), saturation(instrument.color_), brightness(instrument.color_));
    rect(xStart, top + (sliderHeight * (1-value)), sliderWidth, sliderHeight * value);
  }
  
  // check if we're grabbing the handle
  public void onMousePressed() {
    if (xStart < mouseX && mouseX < xStart+sliderWidth) {
      println("within width. bottom: " + bottom);
       if (mouseY < bottom && mouseY > top) {
         isDragging = true;
         isDraggingSlider = true;
       }
    }
  }
  
  public void onMouseReleased() {
    isDragging = false; 
    isDraggingSlider = false; 
  }
  
  public void onMouseDragged() {
    if (isDragging) {
      
      this.value = constrain((float)(bottom-mouseY) / sliderHeight, 0, 1);
      selectedInstrument = instrument;
      println(value);
    }
  }
  
}
