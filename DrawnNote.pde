class DrawnNote {
  Point location; 
  Instrument instrument;
  float rotation;
  
  // Has this note been played on this cycle?
  boolean hasPlayed;
  
  public DrawnNote(Point loc, Instrument instrument) {
    this.location = loc; 
    this.instrument = instrument;
    this.rotation = 0;
    this.hasPlayed = false;
  }
}
