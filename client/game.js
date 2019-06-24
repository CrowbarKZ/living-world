class Game {
    constructor() {
        var ws = new WebSocket("ws://localhost/backend/ws", "living-world-default")
        ws.binaryType = 'arraybuffer';

        // state
        let paused = false;

        // ui refs
        let responseContainer = document.querySelector("textarea#response-container");
        let toolSelect = document.querySelector("select#tool-select");
        let btnPause = document.querySelector("#btn-pause");
        let btnUnpause = document.querySelector("#btn-unpause");

        // bind buttons events
        btnPause.onclick = () => {
            paused = true;
            let cmd = {name: "pause"};
            ws.send(JSON.stringify(cmd));
        }
        btnUnpause.onclick = () => {
            paused = false;
            let cmd = {name: "unpause"};
            ws.send(JSON.stringify(cmd));
        }

        // bind ws events
        ws.onopen = event => {
            let cmd = {name: "get_planet_data"};
            ws.send(JSON.stringify(cmd));
            setInterval(() => {
                if (!paused) ws.send(JSON.stringify(cmd));
            }, 100);
        };
        ws.onmessage = event => {
            let response = JSON.parse(event.data);
            if (response.type == "full_update") {
                this.canvas.syncState(response.data);
            } else {
                let beauty = JSON.stringify(response.data, null, 4)
                responseContainer.value = beauty;
            }
        }

        // create canvas and set mouse events
        this.canvas = new PlanetCanvas(pos => {
            let cmd = {"name": toolSelect.value, "x": pos.x, "y": pos.y}
            if (toolSelect.value == "change_cell") cmd["cellKind"] = 2
            ws.send(JSON.stringify(cmd));

            // return on move func
            return pos => console.log("move", pos);
        });
        this.dom = elt("div", {}, this.canvas.dom);
    }
}
