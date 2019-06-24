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
