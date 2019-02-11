float[][] kernel = { { -1, -1, -1 }, 
  { -1, 8, -1 }, 
  { -1, -1, -1 } };

class Cell {
  float value;
  int predecessor_col;

  Cell(float value, int predecessor_col) {
    this.value = value;
    this.predecessor_col = predecessor_col;
  }
}

PImage src;
PImage dest;

void setup() {
  size(1428, 968);
  src = loadImage("tower.jpg");
  frameRate(15);
}

void draw() {
  clear();
  remove_seam();
  if (dest.width < 5) noLoop();
}

void remove_seam() {
  image(src, 0, 0);
  float[][] energy_values = new float[src.width-2][src.height-2];
  Cell[][] energy_memoization = new Cell[src.width-2][src.height-2];
  // loop through all (x, y) pairs in src image
  for (int x = 1; x < src.width - 1; x++) {
    for (int y = 1; y < src.height -1; y++) {
      // GRADIENT ENERGY CALCULATION
      float Rx = red(src.get(x+1, y)) - red(src.get(x-1, y));
      float Gx = green(src.get(x+1, y)) - green(src.get(x-1, y));
      float Bx = blue(src.get(x+1, y)) - blue(src.get(x-1, y));

      float horiz_gradient = Rx * Rx + Gx * Gx + Bx * Bx;

      Rx = red(src.get(x, y+1)) - red(src.get(x, y-1));
      Gx = green(src.get(x, y+1)) - green(src.get(x, y-1));
      Bx = blue(src.get(x, y+1)) - blue(src.get(x, y-1));

      float vert_gradient = Rx * Rx + Gx * Gx + Bx * Bx;

      // SOBEL CALCULATION (deprecated)
      /*float energy = 0;
       for (int kx = 0; kx < 3; kx++) {
       for (int ky = 0; ky < 3; ky++) {
       energy += kernel[kx][ky] * brightness(src.get(x-kx-1,y-ky-1));
       }
       }*/
      // set energy value at corresponding position in array
      energy_values[x-1][y-1] = horiz_gradient + vert_gradient;
      // show energy values on screen
      //set(x,y,color(map(energy_values[x-1][y-1], 0, 10000, 0, 255)));
    }
  }

  // initialize first row of memoization array
  for (int col = 0; col < energy_values.length; col++) {
    energy_memoization[col][0] = new Cell(energy_values[col][0], -1);
  }

  // compute memoization table using energy values
  for (int row = 1; row < energy_values[0].length; row++) {
    for (int col = 0; col < energy_values.length; col++) {
      float up_left = col-1 >= 0 ? energy_values[col-1][row-1] : 1000000;
      float up_center = energy_values[col][row-1];
      float up_right = col+1 < energy_values.length ? energy_values[col+1][row-1] : 1000000;

      // look at 2 or 3 above and pick smallest, then set
      Cell thisone;
      float lowest_above = min(up_left, up_center, up_right);
      if (lowest_above == up_left) thisone = new Cell(lowest_above + energy_memoization[col-1][row-1].value, col-1);
      else if (lowest_above == up_center) thisone = new Cell(lowest_above + energy_memoization[col][row-1].value, col);
      else thisone = new Cell(lowest_above + energy_memoization[col+1][row-1].value, col+1);
      energy_memoization[col][row] = thisone;
    }
  }

  // find shortest path by moving from bottom to top, accumulate columns into an array
  int[] seam = new int[src.height-2];
  // find starting point (lowest energy)
  int row = energy_memoization[0].length-1;
  int smallest = 0;
  for (int col = 0; col < energy_memoization.length; col++) {
    //print(energy_memoization[col][row].value + ", ");
    if (energy_memoization[col][row].value < energy_memoization[smallest][row].value) {
      smallest = col;
    }
  }
  //println("SMALLEST IS AT " + smallest + " WITH VALUE OF " + energy_memoization[smallest][row].value);
  seam[row] = smallest;
  // move upwards, adding to seam
  for (row = energy_memoization[0].length-2; row >= 0; row--) {
    int previous_col = seam[row+1];
    seam[row] = energy_memoization[previous_col][row+1].predecessor_col;
  }

  // color the seam
  for (int i = 0; i < seam.length; i++) {
    set(seam[i], i+1, color(255, 0, 0));
  }

  // create new image buffer to store width-modified image
  dest = createImage(src.width-1, src.height, RGB);
  // remove the seam
  for (int x = 0; x < src.width; x++) {
    for (int y = 1; y < dest.height-2; y++) {
      int breakpoint = seam[y];
      if (x < breakpoint) dest.set(x, y, src.get(x, y));
      else if (x == breakpoint) continue;
      else dest.set(x-1, y, src.get(x, y));
    }
  }
  src = dest;
}
