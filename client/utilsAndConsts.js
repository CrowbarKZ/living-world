const scale = 12;
const pollInterval = 500;  // ms

let sheepImg = new Image(); sheepImg.src = "/assets/Sheep_001.svg";
let grassImg = new Image(); grassImg.src = "/assets/Grass_001.svg"
const entity_images = {
    "grass": grassImg,
    "sheep": sheepImg,
}

// terrain
const landMaxHeight = 10000
const landSnowyHeight = 7000
const landSoilRGB = [255, 223, 163]
const landRockyRGB = [171, 91, 0]
const landLowSnowRGB = [230,230,230]
const landHighSnowRGB = [255, 255, 255]
const waterShallowRGB = [150, 227, 224]
const waterDeepRGB = [0, 66, 110]


// Interpolates two [r,g,b] colors and returns an [r,g,b] of the result
// Taken from the awesome ROT.js roguelike dev library at
// https://github.com/ondras/rot.js
function interpolateColor(color1, color2, height) {
  let factor = height / landMaxHeight;
  let result = color1.slice();
  for (let i = 0; i < 3; i++) {
    result[i] = Math.round(result[i] + factor*(color2[i]-color1[i]));
  }
  return result;
}


function getCellColor(planet, x, y) {
    let result, factor, color1, color2;
    let height = planet.heights[x + y * planet.dimensions.x];

    if (height <= planet.waterLevelHeight) {
        factor = height / planet.waterLevelHeight;
        color1 = [...waterDeepRGB];
        color2 = [...waterShallowRGB];
    } else if (height <= landSnowyHeight) {
        factor = (height - planet.waterLevelHeight) / (landSnowyHeight - planet.waterLevelHeight);
        color1 = [...landSoilRGB];
        color2 = [...landRockyRGB];
    } else {
        factor = (height - landSnowyHeight) / (landMaxHeight - landSnowyHeight);
        console.log(factor);
        color1 = [...landLowSnowRGB];
        color2 = [...landHighSnowRGB];
    }

    result = color1;
    for (let i = 0; i < 3; i++) {
        result[i] = Math.round(result[i] + factor*(color2[i]-color1[i]));
    }

    return `rgb(${result[0]}, ${result[1]}, ${result[2]})`;
}


function getOrganism(planet, x, y) {
    return planet.organisms[x + y * planet.dimensions.x];
}



function pointerPosition(pos, domNode) {
    // pixel pos to grid pos
    let rect = domNode.getBoundingClientRect();
    return {
        x: Math.floor((pos.clientX - rect.left) / scale),
        y: Math.floor((pos.clientY - rect.top) / scale)
    };
}


function samePlanets(p1, p2) {
    // check if 2 planets have same cells to decide if we need to
    // redraw them
    if (p1 == null || p2 == null) return false;

    let arr1 = p1.heights;
    let arr2 = p2.heights;
    for (let i = 0; i < arr1.length; i++) {
        if (arr1[i] != arr2[i]) return false;
    }
    return true;
}


function lerpPosition(pos1, pos2, coef) {
    // linear interpolation of position vectors
    // coef should be between 0 and 1
    return {
        x: pos1.x + coef * (pos2.x - pos1.x),
        y: pos1.y + coef * (pos2.y - pos1.y)
    }
}


function postData(url = '', data = {}) {
  // Default options are marked with *
    return fetch(url, {
        method: 'POST', // *GET, POST, PUT, DELETE, etc.
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data), // body data type must match "Content-Type" header
    })
    .then(response => response.json()); // parses JSON response into native JavaScript objects
}
