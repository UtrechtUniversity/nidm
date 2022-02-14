// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"


// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

// vis-shit
import { initGraph, updateEdges, paintGraph, proposedEdges } from "./graph";

// my hooks
let Hooks = {}

Hooks.Graph = {
    mounted() {
        this.handleEvent("init-graph", (data) => initGraph(data))
        this.handleEvent("update-edges", (data) => updateEdges(data))
        this.handleEvent("paint-graph", (data) => paintGraph(data))
        this.handleEvent("add-proposed-edges", (data) => proposedEdges(data))
    }, 
    // This hook doesn't update, I don't want it to update, otherwise the 
    // network visual disappears
    updated() {
        console.log("updated")
    }
}

// countdown-clock
import { countdown } from "./countdown";

Hooks.Countdown = {
    mounted() {
        this.handleEvent("countdown", (time) => countdown(time))
    },
    updated() {
        console.log("updated")
    }
}

// admin chart
import { initAdminChart, updateAdminChart } from "./chart";

Hooks.AdminCharts = {
    mounted() {
        this.handleEvent("init-admin-chart", (data) => initAdminChart(data))
        this.handleEvent("update-admin-chart", (data) => updateAdminChart(data))
    },
    updated() {
        console.log("updated");
    }
}

Hooks.InitModal = {
    mounted() {
    }
}


// don't forget to add the hooks to the socket
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
    hooks: Hooks, 
    params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket