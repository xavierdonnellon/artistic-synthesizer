class Instrument {
  String name; 
  String mspIdentifier;
  color color_;
  Shape shape; 
  float particleSize;
  EQSlider eqSlider; 
  
  public Instrument(String name, String identifier, color c, Shape s, float particleSize) {
    this.name = name; 
    this.mspIdentifier = identifier; 
    this.color_ = c; 
    this.shape = s;
    this.particleSize = particleSize;
    
    eqSlider = new EQSlider(this);
  }
}

enum Shape {
 LINE,
 SQUARE,
 RECT;
}
