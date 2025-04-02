PShape terrain;
PImage texture;
PShader shader;

float camX = -130;
float camY = -185;
float camZ = -125;
float dirX = PI/4;
float dirY = PI/4;
float dirZ = 0;

boolean pressForward = false;
boolean pressBehind = false;
boolean pressRight = false;
boolean pressLeft = false;
boolean pressUP = false;
boolean pressDOWN = false;
boolean pressRightCam = false;
boolean pressLeftCam = false;
boolean pressUpCam = false;
boolean pressDownCam = false;

boolean togglePylones = true;
boolean toggleTerrain = true;
boolean toggleCables = true;

ArrayList<PShape> Pylones;
int heightP = 5; // Pour chacun des pylones
float widthP = heightP / 18.0; 
int N = 25; // Nombre de pylones demandés

ArrayList<PShape> Cables;
ArrayList<PVector> pointsDattache; // Pour les cables 


void setup() {
    size(1000, 800, P3D);
    
    terrain = loadShape("hypersimple.obj");
    texture = loadImage("StAuban_texture.jpg");
    shader = loadShader("myFragmentShader.glsl", "myVertexShader.glsl");
    terrain.setTexture(texture);
   
    Pylones = new ArrayList<PShape>();
    Cables = new ArrayList<PShape>();
    pointsDattache = new ArrayList<PVector>(); 
    
    placePylones(20, 100, 40, -115, N);  // Place N pylones entre les points spécifiés
}


void draw() {
    background(255);
    translate(width/2, height/2, 0);
    camera(camX, camY, camZ, camX + 270 * sin(dirX), camY + 270 * cos(dirY), dirZ - 190, 0, 0, -1); 
    perspective(PI/3, width/height, 1, 1000);
    
    drawAxes();
    movementSettings();
    
    if (toggleTerrain) {
        shader(shader);
        shader.set("texture", texture);
        shape(terrain);
        resetShader();
    }
    
    if (togglePylones) 
      for (PShape p : Pylones) 
        shape(p);
        
    if (toggleCables)
      for (PShape c : Cables) 
          shape(c);
}


void drawAxes() {
    translate(0, 0, -175);
    
    // Axe X
    stroke(255, 0, 0);
    line(0, 0, 0, 10, 0, 0);
    
    // Axe Y
    stroke(0, 255, 0);
    line(0, 0, 0, 0, 10, 0);
    
    // Axe Z
    stroke(0, 0, 255);
    line(0, 0, 0, 0, 0, 10);
}


    ////////////////////////
    //                    //
    //   PARTIE PYLONES   //
    //                    //
    ////////////////////////

// Création d'un pylône à une coordonnée donnée 
void createPylone(PShape py, float x, float y, float z) {
      int precisionCyl = 13; // Précision "circulaire" du pylône (pour la formation du poteau par des QUADS)
      float hauteurBras = heightP - widthP; 
    
      py.beginShape(QUADS); 
      py.translate(x, y, z); 
    
      // Support du pylone (cylindre)
      for (int i = -precisionCyl; i <= precisionCyl; i++) {
          float th1 = (i * PI) / precisionCyl;
          float th2 = ((i + 1) * PI) / precisionCyl;
          float cosTheta1 = cos(th1) * widthP;
          float sinTheta1 = sin(th1) * widthP;
          
          float cosTheta2 = cos(th2) * widthP;
          float sinTheta2 = sin(th2) * widthP;
    
          // Chaque rectangle (tenant debout) qui va former le poteau 
          // une fois définit precisionCyl fois sur un cercle
          py.vertex(cosTheta1, sinTheta1, heightP);
          py.vertex(cosTheta1, sinTheta1, 0);
          py.vertex(cosTheta2, sinTheta2, 0);
          py.vertex(cosTheta2, sinTheta2, heightP);
          
          py.fill(51, 51, 51);
      }
    
      // "bras" du pylone supportant les lignes
      py.vertex(heightP/3,  widthP, hauteurBras);
      py.vertex(heightP/3,  widthP, hauteurBras - widthP);
      py.vertex(-heightP/3, widthP, hauteurBras - widthP);
      py.vertex(-heightP/3, widthP, hauteurBras);
    
      py.noStroke(); 
      py.endShape();
      
      // On ajoute les points d'attache aux bras gauche et droit
      pointsDattache.add(new PVector(x - heightP/3, y, hauteurBras + z)); // Côté gauche 
      pointsDattache.add(new PVector(x + heightP/3, y, hauteurBras + z)); // Côté droit
    
}

// Fonction cherchant la "bonne" altitude z du modèle pour un x,y donné
float findAltitudeZ(float x, float y) {
    PVector closestVertex = null; // Va contenir les coordonnées du sommet le plus proche
    float closestDistance = Float.MAX_VALUE; // Plus grande valeur possible

    // Tous les triangles du modèle
    for (int t = 0; t < terrain.getChildCount(); t++) {
        PShape triangle = terrain.getChild(t);
        
        // Tous ses sommets (du triangle courant) 
        for (int s = 0; s < triangle.getVertexCount(); s++) {
            PVector vertex = triangle.getVertex(s);
            float distance = dist(x, y, vertex.x, vertex.y); // Distance entre (x, y) et le sommet
            
            // Si c'est la plus courte distance trouvée jusqu'à présent, on met à jour 
            if (distance < closestDistance) {
                closestDistance = distance;
                closestVertex = vertex;
            }
        }
    }
    return (closestVertex == null) ? 0 : closestVertex.z; // Retourne z du vertex le plus proche (0 si rien trouvé)
}


// S'occupe de l'alignement des pylones sur un axe donné
void placePylones(float startX, float startY, float endX, float endY, int nbPylones) {
    // Soient l'écart qu'il y a entre les pylones 
    float ecartX = (endX - startX) / (nbPylones - 1);  
    float ecartY = (endY - startY) / (nbPylones - 1);
  
    for (int i = 0; i < nbPylones; i++) {
        // Pour chacun, on se place à un écart de plus qu'à l'itération précédente
        float x = startX + i * ecartX;
        float y = startY + i * ecartY;
        float z = findAltitudeZ(x, y);
        
        PShape pylone = createShape();
        createPylone(pylone, x, y, z);
        Pylones.add(pylone);
    }
    // On rejoint tous les cables entre eux, après avoir placé 
    // .. tous les pylones
    joinCables();
}


    ////////////////////////
    //                    //
    //   PARTIE CABLES    //
    //                    //
    ////////////////////////
    
    
// Création d'un cable, en soi
PShape createCable(PVector start, PVector end) {
    PShape cable = createShape();
    cable.beginShape();
    
    cable.stroke(0, 0, 0);
    cable.strokeWeight(2); 
    cable.noFill();

    // Calcul du fléchissement
    float distance = PVector.dist(new PVector(start.x, start.y), new PVector(end.x, end.y));
    float curve = -0.05 * distance; // Facteur négatif pour la gravité

    float controlX = (start.x + end.x) / 2;
    float controlY = (start.y + end.y) / 2;
    
    // On considère le point Z le moins haut entre les deux pylones
    // .. et les câbles doivent fléchir vers le bas
    float controlZ = min(start.z, end.z) + curve; 

    // On lie l'ancre de départ à celui de l'arrivée, en fléchissant via deux points de contrôles
    cable.vertex(start.x, start.y, start.z);
    cable.bezierVertex(controlX, controlY, controlZ, controlX, controlY, controlZ, end.x, end.y, end.z);
    cable.endShape();

    return cable;
}


// Ajout d'une paire de cables entre tous les points d'attache (par paire)
void joinCables() {
    for (int i = 0; i < pointsDattache.size() - 3; i += 2) {
        PVector startLeft = pointsDattache.get(i);
        PVector endLeft = pointsDattache.get(i + 2); // Comme ils sont ajoutés dans l'ordre : startLeft, startRight, endLeft, ...
        
        PVector startRight = pointsDattache.get(i + 1);  
        PVector endRight = pointsDattache.get(i + 3);
        
        PShape cableLeft = createCable(startLeft, endLeft);
        PShape cableRight = createCable(startRight, endRight);

        Cables.add(cableLeft);
        Cables.add(cableRight);
    }
}

    ////////////////////////
    //                    //
    //  PARTIE MOUVEMENTS //
    //                    //
    //////////////////////// 
    
void movementSettings() {
    // MOUVEMENTS
    if (pressForward) { camX += 3 * sin(dirX); camY += 3 * cos(dirY); }
    if (pressBehind)  { camX -= 3 * sin(dirX); camY -= 3 * cos(dirY); }
    if (pressRight)   { camX -= 3 * cos(dirY); camY += 3 * sin(dirX); }
    if (pressLeft)    { camX += 3 * cos(dirY); camY -= 3 * sin(dirX); } 
    
    // VERTICALE
    if (pressUP)   { camZ += 2; dirZ += 2; }
    if (pressDOWN) { camZ -= 2; dirZ -= 2; }
    
    // CAMERA
    if (pressUpCam)    { dirZ += 7; }
    if (pressDownCam)  { dirZ -= 7; }
    if (pressRightCam) { dirY -= PI/100; dirX -= PI/100; }
    if (pressLeftCam)  { dirY += PI/100; dirX += PI/100; }
}

    ////////////////////////
    //                    //
    //   PARTIE KEYBIND   //
    //                    //
    //////////////////////// 

void keyPressed() {
  switch(key) {
    case 'z' : case 'Z' : pressForward = true; break;
    case 's' : case 'S' : pressBehind  = true; break; 
    case 'd' : case 'D' : pressRight   = true; break; 
    case 'q' : case 'Q' : pressLeft    = true; break;
    
    case ' ' : pressUP = true; break; // HAUT 
    
    case 'p' : case 'P' : togglePylones = !togglePylones; break;
    case 't' : case 'T' : toggleTerrain = !toggleTerrain; break;
    case 'c' : case 'C' : toggleCables  = !toggleCables; break;
    
    case CODED : switch(keyCode) {
                    case RIGHT : pressRightCam = true; break;
                    case LEFT  : pressLeftCam  = true; break;
                    case UP    : pressUpCam    = true; break;
                    case DOWN  : pressDownCam  = true; break;
            
                    case SHIFT : pressDOWN     = true; break; // BAS 

                    default    : break;  
    }
    default : break;
  }
}

void keyReleased() { 
  switch(key) {
    case 'z' : case 'Z' : pressForward = false; break;
    case 's' : case 'S' : pressBehind  = false; break; 
    case 'd' : case 'D' : pressRight   = false; break; 
    case 'q' : case 'Q' : pressLeft    = false; break;

    case ' ' : pressUP = false; break; // HAUT 
 
    case CODED : switch(keyCode) {
                    case RIGHT : pressRightCam = false; break;
                    case LEFT  : pressLeftCam  = false; break;
                    case UP    : pressUpCam    = false; break;
                    case DOWN  : pressDownCam  = false; break;
                    
                    case SHIFT : pressDOWN     = false; break; // BAS 
                     
                    default    : break;
                  }
    default : break;
    }
}
