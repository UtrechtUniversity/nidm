import { Chart } from 'chart.js/dist/chart';

var charts = {};

function createChart(ctx, states) {

    let labels = [];
    let edges = [];
    let connects = [];
    let disconnects = [];
    let infected = [];

    states.forEach(function(item, index) {
        labels.push(index);
        edges.push(item.edges);
        connects.push(item.connects);
        disconnects.push(item.disconnects);
        infected.push(item.infected);
    });

    let myChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                { label: "edges", data: edges },
                { label: "connects", data: connects, borderColor: 'rgb(75, 192, 192)', 
                    backgroundColor: 'rgb(75, 192, 192, 0.2)' },
                { label: "disconnects", data: disconnects, borderColor: 'rgb(255, 99, 132)', 
                    backgroundColor: 'rgb(255, 99, 132, 0.2)' },
                { label: "infected x 10", data: infected, borderColor: 'rgba(153, 102, 255)',
                    backgroundColor: 'rgba(153, 102, 255, 0.2)' }
            ]
        },
        options: {
            responsive: false,
            scales: {
                y: {
                    beginAtZero: true,
                    suggestedMax: 100
                },
                x: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: "round",
                    }
                }
            }
        }
    })
    return myChart;
}


function initAdminChart(data) {
    for (const [id, states] of Object.entries(data)) {
        try {
            let ctx = document.getElementById("canvas-" + id);
            if (ctx != null) {
                charts[id] = createChart(ctx, states);
            }
        } catch(err) {
            console.log("could not add chart");
        }
    }
}

function updateAdminChart(data) {
    let chart = charts[data.network_id];

    if (chart.data.labels.length <= 0) {
        chart.data.labels.push(0);
    } else {
        let lastDigit = chart.data.labels[chart.data.labels.length - 1]
        chart.data.labels.push(lastDigit + 1);
    }
    chart.data.datasets[0].data.push(data.edges);
    chart.data.datasets[1].data.push(data.connects);
    chart.data.datasets[2].data.push(data.disconnects);
    chart.data.datasets[3].data.push(data.infected);

    // add  
    chart.update();
}

export { initAdminChart, updateAdminChart };



