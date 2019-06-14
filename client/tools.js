function draw(pos, state, dispatch) {
    function drawPixel({x, y}, state) {
        let drawn = {x, y, type: state.type};
        dispatch({planet: state.planet.update([drawn])});
    }
    drawPixel(pos, state);
    return drawPixel;
}
