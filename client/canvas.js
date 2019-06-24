const scale = 12;
const cell_colors = {
    "desert": "#b75800",
    "land": "#ead76e",
    "water": "#20b6ea"
};

let sheepImg = new Image();
sheepImg.src = "/assets/Sheep_001.svg";

let grassImg = new Image();
grassImg.src = "/assets/Grass_001.svg"

const entity_images = {
    "grass": grassImg,
    "sheep": sheepImg,
}

const entity_colors = {
    "grass": "#0c9b1d",
    "sheep": "#ffffff",
}


class PlanetCanvas {
    constructor(pointerDown) {
        this.dom = elt("canvas", {
            onmousedown: event => this.mouse(event, pointerDown),
            ontouchstart: event => this.touch(event, pointerDown)
        });
        this.planet = null;
    }

    syncState(planet) {
        this.planet = planet;
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
        let newPos = pointerPosition(moveEvent.touches[0], this.dom);
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
