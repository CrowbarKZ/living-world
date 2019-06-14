const cell_land = 0
const cell_water = 1


class Planet {
  constructor(width, height, cells) {
    this.width = width;
    this.height = height;
    this.cells = cells;
  }

  static empty(width, height, type) {
    let cells = new Array(width * height).fill(cell_land);
    return new Planet(width, height, cells);
  }

  cell(x, y) {
    return this.cells[x + y * this.width];
  }

  update(cells) {
    let copy = this.cells.slice();
    for (let {x, y, type} of cells) {
      copy[x + y * this.width] = type;
    }
    return new Planet(this.width, this.height, copy);
  }
}
