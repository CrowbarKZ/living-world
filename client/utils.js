function elt(type, props, ...children) {
    let dom = document.createElement(type);
    if (props) Object.assign(dom, props);
        for (let child of children) {
            if (typeof child != "string") dom.appendChild(child);
            else dom.appendChild(document.createTextNode(child));
        }
    return dom;
}


function get_cell(planet, x, y) {
    return planet.cells[x + y * planet.dimensions.x];
}


function pointerPosition(pos, domNode) {
    let rect = domNode.getBoundingClientRect();
    return {
        x: Math.floor((pos.clientX - rect.left) / scale),
        y: Math.floor((pos.clientY - rect.top) / scale)
    };
}


function samePlanets(p1, p2) {
    if (p1 == null || p2 == null) return false;

    let arr1 = p1.cells;
    let arr2 = p2.cells;
    for (let i = 0; i < arr1.length; i++) {
        if (arr1[i] != arr2[i]) return false;
    }
    return true;
}
