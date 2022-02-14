/*
// https://noozo.medium.com/integrating-vis-js-with-phoenix-live-view-91aaae4b3b03
*/

import { DataSet, Network } from 'vis-network/standalone';

var nodes;
var edges; 
var network;
var defaultBorderColor = '#808080';
var defaultBorderWidth = 1;
var defaultNodeColor = '#eee';
var infectedNodeColor = '#ff9999';
var recoveredNodeColor = '#90EE90';

var meBorderColor = 'purple';
var meBorderWidth = 5;

var defaultEdgeColor = '#eee';
var friendEdgeColor = '#191970';
var defaultEdgeWidth = 1;
var friendEdgeWidth = 3;

function getOptions() {
    // Return vis.js options here, like layout, physics, etc
    // Ommited for brevity
    return {
        //autoResize: true,
        height: '100%',
        width: '100%',

        interaction: {
            dragNodes: true,
            navigationButtons: true,
            selectable: true,
            selectConnectedEdges: true,
            hoverConnectedEdges: true
        },
        physics: {
            enabled: false
        }
    }
}

function createNode(id, currentNode) {
    let node = {
      id: id,
      label: id,
      shape: "circle",
      borderWidthSelected: 5,
      color: {
          background: defaultNodeColor
      },
      margin: 7,
      font: {
        size: 18,
        align: 'center'
      },
    }
    if (id == currentNode) {
        node.shape = "box";
        node.margin = 12;
        node.font.size = 20;
    }
    return node
}

function createEdge(id, start_id, end_id, dashes=false) {
    let edge = {
        id: id,
        from: start_id,
        to: end_id,
        physics: true,
        dashes: dashes,
        width: defaultEdgeWidth,
        selectionWidth: function (width) {return width*2;},
        color: {
            color: defaultEdgeColor
        }
    }
    return edge
}

function collectAllNodes(data, me) {
    let collection = data.map(function(node, index) {
        return createNode(node, me)
    })
    return collection;
}

function collectAllEdges(data) {
    let collection = data.map(function(edge, index) {
        return createEdge(edge.id, edge.from, edge.to)
    })
    return collection;
}
  

function initGraph(data) {
    // Setup data
    nodes = collectAllNodes(data.nodes, data.me)
    nodes = new DataSet(nodes)
    // Setup edges
    edges = collectAllEdges(data.edges)
    edges = new DataSet(edges)
    // Setup graph
    let container = document.getElementById("graph")
    let graphData = { nodes: nodes, edges: edges }
    network = new Network(container, graphData, getOptions())
}

function paintGraph(data) {

    let newNodes = nodes.map(function(node, index) {

        let status = data.health[node.id]
        switch(status) {
            case 'susceptible':
                node.color.background = defaultNodeColor;
                break;
            case 'infected':
                node.color.background = infectedNodeColor;
                break;
            case 'recovered':
                node.color.background = recoveredNodeColor;
        }

        if (node.shape == "box") {
            node.borderWidth = 5;
            node.color.border = "#29a8a4"
        } else if (data.friends.includes(node.id)) {
            node.borderWidth = 3;
            node.color.border = "#00004d";
        } else if (data.introductions.includes(node.id)) {
            node.borderWidth = 3;
            node.color.border = 'darkblue'
        } else {
            node.color.border = 'grey'
            node.borderWidth = defaultBorderWidth;
        }

        node.color.highlight = {
            background: "orange",
            border: "orange"
        };

        return node;
    })

    let newEdges = edges.map(function(edge, index) {
        if (edge.to == data.me || edge.from == data.me) {
            edge.color.color = "#00004d";
            edge.width = friendEdgeWidth;
        } else if ((data.friends.includes(edge.to) && data.friends.includes(edge.from))) {
            edge.color.color = "#00004d";
            edge.width = defaultEdgeWidth;
        } else {
            edge.color.color = defaultEdgeColor;
            edge.width = defaultEdgeWidth;
        }
        edge.color.highlight = "orange";
        return edge;
    })

    nodes.update(newNodes);
    edges.update(newEdges);
    network.unselectAll();
}


function generateId(to, from) {
    return (from < to)? from + "-" + to : to + "-" + from
}


function proposedEdges(data) {

    let me = data.me;
    let myFriends = network.getConnectedNodes(me);
    let requests = data.requests;
    let oldIntros = data.old_introductions;
    let highLight = []
    let unHighLight = []

    for (const [node, receivedRequests] of Object.entries(requests)) {

        if (receivedRequests.length == 0 && oldIntros.includes(node)) {
            // un-highlight the node if it was part of old_introductions
            //unHighLight.push(node);
        } else {
            receivedRequests.forEach(request => {
                let to = request.to;
                let from = request.from;
                let id = generateId(to, from);
                // remove this edge by default, if it's a connect it will just
                // bounce, all disconnects must be removed
                edges.remove({ id: id })
    
                // if this is something in my neighbourhood
                if (request.to == me || request.from == me) {
                    let otherNode = (request.to == me)? request.from : request.to;

                    let type = request.type;

                    // this is for un/highlighting the -nodes- later on 
                    if (type == "disconnect") {
                        //unHighLight.push(otherNode);
                    } else {
                        highLight.push(otherNode);
                    }

                    // this is for the edges
                    // if this is a disconnect I might have to un-highlight connections 
                    // from this node to my friends
                    if (type == "disconnect") {
                        // main edge is already removed, remove highlighted edges
                        let hisFriends = network.getConnectedEdges(otherNode);
                        // update edges, make sure they are not highlighted
                        hisFriends.forEach((edgeId) => {
                            // get the edge
                            let curEdge = edges.get(edgeId)
                            // so if this edge is going to one of my friends it should be a regular edge
                            if (myFriends.includes(curEdge.to) || myFriends.includes(curEdge.from)) {
                                edges.updateOnly({ id: edgeId, width: defaultEdgeWidth, color: { color: defaultEdgeColor}});
                            }
                        })
                    } else {
                        // edge is already removed to make sure
                        try {
                            let edge = null;
                            if (request.accepted == true && edges.get(id) == null) {
                                edge = createEdge(id, from, to, [10, 10]);
                                edge['arrows'] = "to;from";
                                edge.color.color = '#29a8a4';
                            } else {
                                edge = createEdge(from + "->" + to, from, to, [10, 10]);
                                edge['arrows'] = "to";
                                edge.color.color = '#29a8a4';
                            }
                            if (edge != null) {
                                edge.width = friendEdgeWidth;
                                edges.add(edge);
                            }
                        } catch(err) { console.log(err); }
                    }
                }
            })
        }
    }

    // this isn't nice: but it works. I have collected all the
    // highlighted nodes that need unhighlighting, but it turns out
    // I need to be sure and unhighlight all
    // The only nodes that DONT needs highlighting are the ones that 
    // are connected to me, or want to connect with me
    // retrace my current friends. I also dont want to mess with myself
    myFriends = network.getConnectedNodes(me);
    nodes.forEach(function(node, index) {
        if (highLight.includes(node.id) || node.id == me || myFriends.includes(node.id)) {
            // do nothing
            true
        } else {
            node.color.border = 'grey'
            node.borderWidth = defaultBorderWidth;
            unHighLight.push(node)
        }
    })

    // and highlighting the people that want to become friends with me
    highLight = nodes.get(highLight).map(function(node, index) {
        node.borderWidth = 3;
        node.color.border = 'darkblue'
        return node;
    })
    // update combination
    nodes.update(unHighLight.concat(highLight));
}


function updateEdges(data) {
    // just remove all edges
    edges.clear();
    // Setup links
    let newEdges = collectAllEdges(data.edges);
    edges.update(newEdges);
}


export { initGraph, proposedEdges, updateEdges, paintGraph };