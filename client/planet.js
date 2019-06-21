class Vector2 {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }

    static fromArray(coords) {
        return new Vector2(coords[0], coords[1]);
    }
}


class Planet {
    constructor(dimensions, age, cells, entities) {
        this.dimensions = dimensions;
        this.cells = cells.map(e => e[0]);
        this.entities = entities.map(e => Entity.fromArray(e));
        this.age = age;
    }

    static empty(dimensions) {
        let cells = new Array(dimensions.x * dimensions.y).fill(0);
        let entities = new Array();
        return new Planet(dimensions, 0, cells, entities);
    }

    static fromBinary(arrayBuffer) {
        let byteArray = new Uint8Array(arrayBuffer);
        let data = msgpack.decode(byteArray);
        return new Planet(Vector2.fromArray(data[0]), data[1], data[2], data[3])
    }

    cell(x, y) {
        return this.cells[x + y * this.dimensions.x];
    }
}


class Entity {
    constructor(kind, position, direction, energy) {
        this.kind = kind;
        this.position = position;
        this.direction = direction;
        this.energy = energy;
    }

    static fromArray(arr) {
        return new Entity(arr[0], Vector2.fromArray(arr[1]), Vector2.fromArray(arr[2]), arr[3])
    }
}
