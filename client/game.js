const scale = 12;
const pollInterval = 500;  // ms

const cell_colors = {
    "desert": "#b75800",
    "land": "#ead76e",
    "water": "#20b6ea"
};

let sheepImg = new Image(); sheepImg.src = "/assets/Sheep_001.svg";
let grassImg = new Image(); grassImg.src = "/assets/Grass_001.svg"
const entity_images = {
    "grass": grassImg,
    "sheep": sheepImg,
}


class Game {
    constructor() {
        var ws = new WebSocket("ws://localhost/backend/ws", "living-world-default")
        ws.binaryType = 'arraybuffer';

        // state
        this.redrawBackground = true;
        this.planet = null;  // current state
        this.newPlanet = null;  // new state we want to transition to
        this.msSinceUpdate = 0;
        let paused = false;



        // ui refs
        let responseContainer = document.querySelector("textarea#response-container");
        let toolSelect = document.querySelector("select#tool-select");
        let btnPause = document.querySelector("#btn-pause");
        let btnUnpause = document.querySelector("#btn-unpause");
        this.canvasBg = document.querySelector("canvas#background-layer");
        this.canvasEntity = document.querySelector("canvas#entity-layer");

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
            }, pollInterval);
        };
        ws.onmessage = event => {
            let response = JSON.parse(event.data);
            if (response.type == "full_update") {
                this.msSinceUpdate = 0;
                this.planet = this.newPlanet;
                this.newPlanet = response.data;
                if (!samePlanets(this.planet, this.newPlanet)) this.redrawBackground = true;
            } else {
                let beauty = JSON.stringify(response.data, null, 4)
                responseContainer.value = beauty;
            }
        }

        // set mouse events
        this.canvasEntity.onmousedown = e => {
            let pos = pointerPosition(e, this.canvasEntity);
            let cmd = {"name": toolSelect.value, "x": pos.x, "y": pos.y}
            if (toolSelect.value == "change_cell") cmd["cellKind"] = 2
            ws.send(JSON.stringify(cmd));
        }
    }

    startRenderLoop() {
        let app = this;
        let prevUpdate = Date.now();
        function draw(start) {
            let dt = Date.now() - prevUpdate;
            app.msSinceUpdate += dt;
            console.log(app.msSinceUpdate);

            let planet = app.planet;
            let newPlanet = app.newPlanet;
            if (!planet) {
                requestAnimationFrame(draw);
                return;
            }

            if (app.redrawBackground) {
                console.log("redrawing background!")
                let canvasBg = app.canvasBg;
                let cxb = canvasBg.getContext("2d", { alpha: false });
                canvasBg.width = newPlanet.dimensions.x * scale;
                canvasBg.height = newPlanet.dimensions.y * scale;

                for (let y = 0; y < newPlanet.dimensions.y; y++) {
                    for (let x = 0; x < newPlanet.dimensions.x; x++) {
                        cxb.fillStyle = cell_colors[get_cell(newPlanet, x, y)];
                        cxb.fillRect(x * scale, y * scale, scale, scale);
                    }
                }
                app.redrawBackground = false;
            }

            let canvasEntity = app.canvasEntity;
            let cxe = canvasEntity.getContext("2d");
            canvasEntity.width = planet.dimensions.x * scale;
            canvasEntity.height = planet.dimensions.y * scale;

            for (let e of newPlanet.entities) {
                // let x = lerp(newEntity.x, oldEntity.x, Math.max(app.msSinceUpdate, pollInterval));
                cxe.drawImage(entity_images[e.kind], e.position.x * scale, e.position.y * scale);
            }

            prevUpdate = Date.now();
            window.requestAnimationFrame(draw);
        }
        window.requestAnimationFrame(draw);
    }
}
