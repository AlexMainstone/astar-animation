// Constants
final int CellCount = 22; // Map width & height
final int CellSize = 32; // Size of  cellse in pixels
final int Frames = 13; // Number of Files to load

// World Map
int[][] Map;

// Mouse position on grid
int CursorX, CursorY;

// Start & End
int StartX, StartY;
int Endx, EndY;

// True if start has been set but not end
boolean HasSetStart;

// True if path found
boolean CompletedPath;

// True if hovering over next button
boolean NextButtonHover;

// True if the path is being drawn
boolean DrawPath;

// Determines if the user can create environments
boolean FreeMode;

// Astar sets
ArrayList<Node> openset;
ArrayList<Node> closedset;

// Start & end node
Node start;
Node end;

// The current animation position
int CurrentStep;

// The current character printed
int CurrentChar;

// Does the next frame idle = 0, run = 1 or step?
int StepType;

// Current Text to print
String CurrentText;

// Wait Timer
boolean TimerStart;
int StartTime;

// Map Node class
class Node {
    public Node parent;
    public float heuristic;
    public int cost;
    public float total;
    public int x, y;

    void calculateHeuristic(float x, float y, float goal_x, float goal_y) {
        heuristic = sqrt(pow(x - goal_x, 2) + pow(y - goal_y, 2));
    }
}

void setup() {
    // Create window 
    size(1280, 720);
    Map = new int[CellCount][CellCount];

    // Set start & end offscreen
    StartX = StartY = Endx = EndY = -1;
    StepType = 0;

    CurrentStep = 1;
    CurrentChar = 0;
    loadMap("res/" + CurrentStep + ".txt");

    // Init booleans
    HasSetStart = true;
    NextButtonHover = false;
    FreeMode = false;
    TimerStart = false;
}

void draw() {
    // Clear
    clear();

    drawGrid();

    // Draw Start & End
    fill(0, 255, 0);
    rect(StartX * CellSize, StartY * CellSize, CellSize, CellSize);
    fill(255, 0, 0);
    rect(Endx * CellSize, EndY * CellSize, CellSize, CellSize);

    // Draw Next Button
    if (NextButtonHover) {
        fill(200, 200, 200);
    } else {
        fill(255, 255, 255);
    }
    rect(width - 200, height - 40, 200, 40);
    fill(0, 0, 0);
    textSize(32);
    text("Next", width - 140, height - 10);

    // astar
    if ((StepType == 1 || FreeMode) && DrawPath) {
        astarStep();
        astarDraw();
    } else if(StepType > 1) {
        astarDraw();
    }

    if(CurrentStep > Frames) {
        return;
    }
    textSize(16);
    fill(255, 255, 255);
    text(CurrentText.substring(0, CurrentChar), CellSize * CellCount + 10, 60, 500, 600);
    if(CurrentChar < CurrentText.length()) {
       CurrentChar++;
    } else if (!TimerStart && CompletedPath) {
        TimerStart = true;
        StartTime = millis();
    } else if (millis() - StartTime > 5000 && CompletedPath) {
        CurrentStep++;
        loadMap("res/" + CurrentStep + ".txt");
    }
    // Draw a mouse Cursor
    // rect(CursorX * CellSize, CursorY * CellSize, CellSize, CellSize);
}

// Draw the background grid
void drawGrid() {
    stroke(0, 0, 0);
    for (int x = 0; x < CellCount; x++) {
        for (int y = 0; y < CellCount; y++) {
            // Set colour depending on if wall
            if (Map[x][y] == 1) {
                fill(60, 60, 60);
            } else {
                fill(255, 255, 255);
            }
            rect(x * CellSize, y * CellSize, CellSize, CellSize);
        }
    }
}

void mouseMoved() {
    // Get mouse position on grid
    CursorX = mouseX / CellSize;
    CursorY = mouseY / CellSize;

    // If hovering over button
    if (mouseX > width - 200 && mouseY > height - 40) {
        NextButtonHover = true;
    } else {
        NextButtonHover = false;
    }
}

void mouseClicked() {
    // Stop drawing and pathing
    if (NextButtonHover) { 
        // Next button pressed
        astarSetup();
        DrawPath = true;
        return;
    }

    if(!FreeMode) {
        return;
    }
    DrawPath = false;
    
    if (mouseButton == RIGHT) { 
        // Place wall
        Map[CursorX][CursorY] = (Map[CursorX][CursorY] == 0) ? 1 : 0;
    } else if (HasSetStart) {
        // Set start
        Endx = CursorX;
        EndY = CursorY;
        HasSetStart = false;
    } else {
        // Set end
        StartX = CursorX;
        StartY = CursorY;
        HasSetStart = true;
    }
}

void loadMap(String path) {
    if(CurrentStep > Frames) {
        FreeMode = true;
        StepType = 1;
        DrawPath = false;
        StartX = StartY = Endx = EndY = -1;
        for(int x = 0; x < CellCount; x++) {
            for(int y = 0; y < CellCount; y++) {
                Map[x][y] = 0;
            }
        }
        return;
    }
    String[] file = loadStrings(path);
    for(int x = 0; x < CellCount; x++) {
        for(int y = 0; y < CellCount; y++) {
            char c = file[x].charAt(y);
            if(c == '0') {
                Map[x][y] = 0;
            } else if(c == '1') {
                Map[x][y] = 1;
            } else if(c == '2') {
                Map[x][y] = 0;
                StartX = x;
                StartY = y;
            } else if(c == '3') {
                Map[x][y] = 0;
                Endx = x;
                EndY = y;
            }
        }
    }

    TimerStart = false;
    StartTime = 0;
    CurrentChar = 0;
    CurrentText = file[22];
    StepType = int(file[23]);
    CompletedPath = false;

    astarSetup();
    DrawPath = true;

    if(StepType != 1) {
        CompletedPath = true;
    } 

    if(StepType > 1) {
        for(int i = 0; i < StepType-1; i++) {
            astarStep();
        }
    }
}

// void saveMap() {
//     String[] save = new String[CellCount];
//     for(int x = 0; x < CellCount; x++) {
//         save[x] = "";
//         for(int y = 0; y < CellCount; y++) {
//             if(x == StartX && y == StartY) {
//                 save[x] += 2;
//             } else if(x == Endx && y == EndY) {
//                 save[x] += 3;
//             } else {
//                 save[x] += Map[x][y];
//             }
//         }
//     }
//     saveStrings("res/1.txt", save);
// }

Node getNode(int map_x, int map_y) {
    // If out of bounds return null
    if (map_x < 0 || map_x >= CellCount || map_y < 0 || map_y >= CellCount) {
        return null;
    }

    // If walkable tile
    if (Map[map_x][map_y] == 0) {
        // Create node object for tile
        Node node = new Node();
        node.calculateHeuristic(map_x, map_y, Endx, EndY);
        node.cost = 1;
        node.total = node.cost + node.heuristic;
        node.x = map_x;
        node.y = map_y;
        return node;
    }
    return null;
}

// Setup astar 
void astarSetup() {
    // Init variables
    openset = new ArrayList<Node> ();
    closedset = new ArrayList<Node> ();

    start = getNode(StartX, StartY);
    end = getNode(Endx, EndY);

    // Add start to openset
    openset.add(start);
}

// Draw a node with all its data
void drawNode(Node node) {
    // Draw Values
    fill(50, 50, 50);
    text(round(node.cost), node.x * CellSize + 2, node.y * CellSize + 12);
    text(round(node.heuristic), node.x * CellSize + 2, node.y * CellSize + CellSize - 2);

    // Get center of node
    int center_x, center_y;
    center_x = node.x * CellSize + (CellSize / 2);
    center_y = node.y * CellSize + (CellSize / 2);

    // if node has no parent return
    if (node.parent == null) {
        return;
    }

    // Get direction of parent
    int dir_x, dir_y;
    dir_x = dir_y = 0;
    if (node.x > node.parent.x) {
        dir_y = center_y;
        dir_x = center_x - CellSize;
    } else if (node.y > node.parent.y) {
        dir_y = center_y - CellSize;
        dir_x = center_x;
    } else if (node.x < node.parent.x) {
        dir_y = center_y;
        dir_x = center_x + CellSize;
    } else if (node.y < node.parent.y) {
        dir_y = center_y + CellSize;
        dir_x = center_x;
    }
    // Draw a line to the parent
    strokeWeight(4);
    line(center_x, center_y, dir_x, dir_y);
    strokeWeight(1);

    // draw a circle at the node center
    fill(255, 255, 255);
    circle(center_x, center_y, 4);
    fill(0, 0, 0);
}

// draw a representation of the algorithm
void astarDraw() {
    textSize(12);

    // draw stats
    fill(255, 255, 255);
    text("open set: " + openset.size(), CellSize * CellCount, 15);
    text("closed set: " + closedset.size(), CellSize * CellCount, 35);

    // Draw bars to represent the open and closed set
    fill(0, 255, 0);
    rect(CellSize * CellCount, 15, openset.size(), 10);
    fill(255, 0, 0);
    rect(CellSize * CellCount, 35, closedset.size(), 10);


    // Render closed set
    for (Node node: closedset) {
        if (node == null) {
            continue;
        }

        // Draw node
        fill(255, 0, 0);
        rect(node.x * CellSize, node.y * CellSize, CellSize, CellSize);
        drawNode(node);
    }

    // Render open set
    for (Node node: openset) {
        if (node == null) {
            continue;
        }

        // Draw node
        fill(0, 255, 0);
        rect(node.x * CellSize, node.y * CellSize, CellSize, CellSize);
        drawNode(node);

        // highlight path from start to end
        if (node.x == end.x && node.y == end.y) {
            Node path = node;
            while (path.parent != null) {
                fill(255, 255, 0, 150);
                rect(path.x * CellSize, path.y * CellSize, CellSize, CellSize);
                path = path.parent;
            }
        }
    }
}

// add all neighbors to list
ArrayList<Node> getNeighbors(int x, int y) {
    ArrayList<Node> out = new ArrayList<Node> ();
    out.add(getNode(x - 1, y));
    out.add(getNode(x + 1, y));
    out.add(getNode(x, y - 1));
    out.add(getNode(x, y + 1));
    return out;
}

// Check if node is in list
boolean containsNode(Node n, ArrayList<Node> list) {
    for (Node current: list) {
        if (current.x == n.x && current.y == n.y) {
            return true;
        }
    }
    return false;
}

// Take a step in the algorithm
void astarStep() {
    if (openset.size() > 0) {
        // get lowest index
        int lowestindex = 0;
        for (int i = 0; i < openset.size(); i++) {
            if (openset.get(i) == null) {
                continue;
            }
            if (openset.get(i).total < openset.get(lowestindex).total) {
                lowestindex = i;
            }
        }

        Node current = openset.get(lowestindex);

        // If current node is  the end node
        if (current.x == end.x && current.y == end.y) {
            CompletedPath = true;
            return;
        }

        // Move to closed set
        openset.remove(lowestindex);
        closedset.add(current);

        // iterate through neighbors
        for (Node node: getNeighbors(current.x, current.y)) {
            if (node == null) {
                continue;
            }
            if (containsNode(node, closedset)) {
                continue;
            }

            node.cost = current.cost + 1;
            node.total = node.cost + node.heuristic;
            node.parent = current;

            if (!containsNode(node, openset)) {
                openset.add(node);
            } else {
                continue;
            }
        }
    }
}