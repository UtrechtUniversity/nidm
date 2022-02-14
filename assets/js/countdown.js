// countdown
function countdown(data) {
    var time = data.time;
    var i = 1;
    var radius = 40;
    var circumference = (2 * Math.PI * radius);

    var svg = document.getElementById('countdown-svg')
    // if elem has kids remove them
    svg.innerHTML = '';

    // create a new child
    var circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
    circle.setAttribute('cx', '50');
    circle.setAttribute('cy', '50');
    circle.setAttribute('r', '40');
    circle.setAttribute('stroke-width', '7');
    circle.setAttribute('stroke', '#ddd');
    circle.setAttribute('fill', 'none');
    circle.setAttribute('stroke-linecap', 'round');
    circle.setAttribute('id', 'circle');
    circle.setAttribute('stroke-dasharray', circumference);
    
    // add to svg
    svg.appendChild( circle );
    /* Need initial run as interval hasn't yet occured... */
    circle.setAttribute("stroke-dashoffset", circumference-(1*(circumference/time)));
    circle.setAttribute('transition', 'all 1s linear');
    
    var interval = setInterval(function() {
		if (i == time) {  	
            clearInterval(interval);
			return;
        }
        circle.setAttribute('stroke-dashoffset', circumference-((i+1)*(circumference/time)));
        i++;
    }, 1000);
}

export { countdown };