class Game {
    constructor(planet) {
        this.canvas = new PlanetCanvas(planet, pos => {
            console.log("down", pos);
            return pos => console.log("move", pos);
        });
        this.dom = elt("div", {}, this.canvas.dom);
    }
}
