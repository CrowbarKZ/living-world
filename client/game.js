class Game {
    constructor(planet) {
        var ws = new WebSocket("ws://localhost/backend/ws", "living-world-default")
        ws.binaryType = 'arraybuffer';

        let responseContainer = document.querySelector("textarea#response-container")
        let toolSelect = document.querySelector("select#tool-select")

        ws.onopen = event => {
            let command = {
                "name": "get_planet_data",
                "x": 0,
                "y": 0,
                "cellKind": "land",
            }
            ws.send(JSON.stringify(command));
            setInterval(() => {
                ws.send(JSON.stringify(command));
            }, 500);
        };
        ws.onmessage = event => {
            if (event.data instanceof ArrayBuffer) {
                let planet = Planet.fromBinary(event.data);
                app.canvas.syncState(planet);
            } else {
                let beauty = JSON.stringify(JSON.parse(event.data), null, 4)
                responseContainer.value = beauty;
            }
        }

        this.canvas = new PlanetCanvas(planet, pos => {
            let command_name = toolSelect.value
            let command = {
                "name": command_name,
                "x": pos.x,
                "y": pos.y,
                "cellKind": "land",
            }

            if (command_name = "change_cell") command["cellKind"] = "water"

            ws.send(JSON.stringify(command));

            // return on move func
            return pos => console.log("move", pos);
        });
        this.dom = elt("div", {}, this.canvas.dom);
    }
}
