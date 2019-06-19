const scale = 15;
const cell_colors = {
    0: "#EAD76E",    // land
    1: "#20B6EA",    // water
    2: "#FFFD5C"     // desert
};

const entity_colors = {
    0: "#5abc28",    // grass
    1: "#f6f7f4",    // sheep
};


class PlanetCanvas {
    constructor(planet, pointerDown) {
        this.dom = elt("canvas", {
            onmousedown: event => this.mouse(event, pointerDown),
            ontouchstart: event => this.touch(event, pointerDown)
        });
        this.syncState(planet);
    }

    syncState(planet) {
        if (this.planet == planet) return;
        this.planet = planet;
        drawPlanet(this.planet, this.dom, scale);
    }
}

function drawPlanet(planet, canvas, scale) {
    canvas.width = planet.dimensions.x * scale;
    canvas.height = planet.dimensions.y * scale;
    let cx = canvas.getContext("2d");

    for (let y = 0; y < planet.dimensions.y; y++) {
        for (let x = 0; x < planet.dimensions.x; x++) {
            cx.fillStyle = cell_colors[planet.cell(x, y)];
            cx.fillRect(x * scale, y * scale, scale, scale);
        }
    }

    for (let e of planet.entities) {
        cx.beginPath();
        cx.arc(e.position.x * scale + scale / 2, e.position.y * scale + scale / 2, scale / 2, 0, 2 * Math.PI, false);
        cx.fillStyle = entity_colors[e.kind];
        cx.fill();

        cx.lineWidth = 1;
        cx.strokeStyle = 'black';
        cx.stroke();
    }
}


function pointerPosition(pos, domNode) {
    let rect = domNode.getBoundingClientRect();
    return {x: Math.floor((pos.clientX - rect.left) / scale),
                    y: Math.floor((pos.clientY - rect.top) / scale)};
}


PlanetCanvas.prototype.mouse = function(downEvent, onDown) {
    if (downEvent.button != 0) return;
    let pos = pointerPosition(downEvent, this.dom);
    let onMove = onDown(pos);
    if (!onMove) return;
    let move = moveEvent => {
        if (moveEvent.buttons == 0) {
            this.dom.removeEventListener("mousemove", move);
        } else {
            let newPos = pointerPosition(moveEvent, this.dom);
            if (newPos.x == pos.x && newPos.y == pos.y) return;
            pos = newPos;
            onMove(newPos);
        }
    };
    this.dom.addEventListener("mousemove", move);
};


PlanetCanvas.prototype.touch = function(startEvent, onDown) {
    let pos = pointerPosition(startEvent.touches[0], this.dom);
    let onMove = onDown(pos);
    startEvent.preventDefault();
    if (!onMove) return;
    let move = moveEvent => {
        let newPos = pointerPosition(moveEvent.touches[0],
                                                                 this.dom);
        if (newPos.x == pos.x && newPos.y == pos.y) return;
        pos = newPos;
        onMove(newPos);
    };
    let end = () => {
        this.dom.removeEventListener("touchmove", move);
        this.dom.removeEventListener("touchend", end);
    };
    this.dom.addEventListener("touchmove", move);
    this.dom.addEventListener("touchend", end);
};
