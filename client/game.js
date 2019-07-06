class Game {
    // encapsulates main clinet side logic
    // client polls server for the world data every pollInterval seconds
    // but in order to make the game feel smoother
    // render loop tries to be real time with requestAnimationFrame();
    // and we interpolate the positions of moving objects;

    constructor(token) {
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

        // bind buttons and window events
        btnPause.onclick = () => {
            paused = true;
            let cmd = {name: "pause"};
            ws.send(JSON.stringify(cmd));
        };
        btnUnpause.onclick = () => {
            paused = false;
            let cmd = {name: "unpause"};
            ws.send(JSON.stringify(cmd));
        };
        window.onbeforeunload = (e) => {
            let cmd = {name: "signout", token: token, data: null};
            ws.send(JSON.stringify(cmd));
        };

        // bind ws events
        ws.onopen = event => {
            console.log(token);
            let cmd = {name: "get_planet_data", token: token, data: null};
            ws.send(JSON.stringify(cmd));
            setInterval(() => {
                if (!paused) ws.send(JSON.stringify(cmd));
            }, pollInterval);
        };
        ws.onmessage = event => {
            let response = JSON.parse(event.data);
            if (response.kind == "full_update") {
                this.msSinceUpdate = 0;
                this.planet = this.newPlanet;
                this.newPlanet = response.data;
                if (!samePlanets(this.planet, this.newPlanet)) this.redrawBackground = true;

                if (this.planet && this.planet.tracked) {
                    responseContainer.value = JSON.stringify(this.planet.tracked, null, 4);
                }
            } else {
                let beauty = JSON.stringify(response.data, null, 4)
                responseContainer.value = beauty;
            }
        };

        // set mouse events
        this.canvasEntity.onmousedown = e => {
            responseContainer.value = "";
            let pos = pointerPosition(e, this.canvasEntity);
            console.log(pos);
            let idx = pos.x + pos.y * this.planet.dimensions.x;
            let data = {idx:  idx}
            if (toolSelect.value == "change_cell") data["kind"] = 2
            if (toolSelect.value == "create_entity") data["kind"] = 1
            let cmd = {name: toolSelect.value, token: token, data: data}
            ws.send(JSON.stringify(cmd));
        };
    }

    startRenderLoop() {
        let app = this;
        let prevUpdate = Date.now();
        function draw(start) {
            let dt = Date.now() - prevUpdate;
            app.msSinceUpdate += dt;

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
                        cxb.fillStyle = getCellColor(newPlanet, x, y);
                        cxb.fillRect(x * scale, y * scale, scale, scale);
                    }
                }
                app.redrawBackground = false;
            }

            let canvasEntity = app.canvasEntity;
            let cxe = canvasEntity.getContext("2d");
            canvasEntity.width = planet.dimensions.x * scale;
            canvasEntity.height = planet.dimensions.y * scale;

            for (let y = 0; y < newPlanet.dimensions.y; y++) {
                for (let x = 0; x < newPlanet.dimensions.x; x++) {
                    let organism = getOrganism(newPlanet, x, y);
                    if (!organism) continue;
                    cxe.drawImage(entity_images[organism], Math.round(x * scale), Math.round(y * scale));
                }
            }

            prevUpdate = Date.now();
            window.requestAnimationFrame(draw);
        }
        window.requestAnimationFrame(draw);
    }
}
