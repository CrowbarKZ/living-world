function getCellColor(planet, x, y) {
    let height = planet.heights[x + y * planet.dimensions.x];
    if (height < planet.waterLevelHeight) return "#20b6ea";
    return "#ead76e";
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
