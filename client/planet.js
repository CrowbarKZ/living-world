const cell_land = 0
const cell_water = 1

const grass_spawn_interval = 5;


class Planet {
    constructor(width, height, age, cells, entities) {
        this.width = width;
        this.height = height;
        this.cells = cells;
        this.entities = entities;
        this.age = age;
    }

    static empty(width, height) {
        let cells = new Array(width * height).fill(cell_land);
        let entities = new Array();
        return new Planet(width, height, 0, cells, entities);
    }

    static fromServer(cb) {
        var oReq = new XMLHttpRequest();
        oReq.open("GET", "/backend/planet/", true);
        oReq.responseType = "arraybuffer";

        oReq.onload = function (oEvent) {
          var arrayBuffer = oReq.response;
          if (arrayBuffer) {
            var byteArray = new Uint8Array(arrayBuffer);
            var data = msgpack.decode(byteArray);
            var planet = new Planet(data[0][0], data[0][1], data[1], data[2], data[3])
            cb(planet);
          }
        };
        oReq.send(null);
    }

    cell(x, y) {
        return this.cells[x + y * this.width];
    }

    process() {

    }
}
