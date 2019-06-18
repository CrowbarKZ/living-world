class Game {
    constructor(planet) {
        var ws = new WebSocket("ws://localhost/backend/ws", "living-world-default")
        ws.binaryType = 'arraybuffer';

        ws.onopen = event => {
            ws.send("get_planet_data");
            setInterval(() => {
                ws.send("get_planet_data");
            }, 1000);
        };
        ws.onmessage = event => {
            if (event.data instanceof ArrayBuffer) {
                let planet = Planet.fromBinary(event.data);
                app.canvas.syncState(planet);
                // console.log(planet);
            } else {
                console.log(event.data);
            }
        }

        this.canvas = new PlanetCanvas(planet, pos => {
            console.log("down", pos);
            ws.send("get_cell_data:" + pos.x + ":" + pos.y);

            // return on move func
            return pos => console.log("move", pos);
        });
        this.dom = elt("div", {}, this.canvas.dom);
    }
}
