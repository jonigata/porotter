var watchees = {};
var io = null;
var connected = false;

function clearWatchees() {
    if (0 < watchees.length) {
        watchees = {};
        sendWatchees();
    }
}

function watchTimeline(timelineId) {
    watchees[timelineId] = timelineId;
    sendWatchees();
}

function unwatchTimeline(timelineId) {
    delete watchees[timelineId];
    sendWatchees();
}

function sendWatchees() {
    if (connected) {
        var targets = [];
        for(var k in watchees) {
            targets.push(k);
        }
        io.push("watch", {targets: targets});
    }
}

function startWatch() {
    io = new RocketIO().connect();
    io.on("connect", function(session) {
        connected = true;
        if (0 < watchees.length) {
            sendWatchees();
        }
    });
    io.on("watch", function(data) {
        console.log(data);
    });
}
