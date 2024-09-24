class ParticleEffect {
  Point location;
  
  List<Particle> particles; 
  
  int prevTime;
  
  float COLOR_FADE_RATE = 0.965;
  
  float noiseTime = 0;
  float decel = 0.94; // decay rate
  
  boolean complete = false;
  
  public ParticleEffect(Point location, color baseColor, float size) {
    this.location = location; 
    this.particles = new ArrayList<>();
    
    for (int i = 3 + (int)random(3); i < 5; i++) {
      PVector v = new PVector((125-random(250)), (125-random(250))); // pixels per second
      color c = color(hue(baseColor) + (10 - random(20)), saturation(baseColor) - random(50), brightness(baseColor) + random(60));
      Particle particle = new Particle(c, v, (int)(size* (1 + random(4))));
      particles.add(particle);
    }
    prevTime = millis();
  }
  
  void draw() {
    noStroke();
    for (Particle p : particles) {
      fill(p.color_);
      if (p.square) {
        square(p.loc.x, p.loc.y, p.size*4); 
      } else {
        circle(p.loc.x, p.loc.y, p.size*4);
      }
    }
    update(); 
  }
  
 void update() {
   int dt = millis() - prevTime;
   for (Particle p : particles) {
      p.loc.x += p.velocity.x * ((float)dt / 1000);
      p.loc.y += p.velocity.y * ((float)dt / 1000);
      
      p.velocity.x *= decel;
      p.velocity.y *= decel;
      p.velocity.y += ((float)dt / 1000) * 50;
      
      p.color_ = color(hue(p.color_), saturation(p.color_), brightness(p.color_), alpha(p.color_) * COLOR_FADE_RATE);
      
      if (alpha(p.color_) < 0.05) {
        this.complete = true; 
      }
    }
    prevTime = millis();
    
    noiseTime += 0.5;
  }
  
  class Particle {
    Point loc;
    color color_;
    PVector velocity; 
    int size;
    boolean square; // square or circle?
    
    private Particle(color c, PVector velocity, int size) {
      this.color_ = c;
      this.velocity = velocity;
      this.loc = new Point(location.x, location.y);
      this.size = size;
      this.square = random(1) > 0.5;
    }
  }
  
  boolean isComplete() {
    return complete; 
  }
}
