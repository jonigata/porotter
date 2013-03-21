var io = null;
var connected = false;

function updateWatchingTimelines() {
    if (connected) {
        var posts = $('[timeline-id]');
        var targets = [];
        posts.each(function(i, e) {
            targets.push($(e).attr('timeline-id')-0);
        });
        io.push("watch", {targets: targets});
    }
}

function startWatch(callback) {
    io = new RocketIO().connect();
    io.on("connect", function(session) {
        connected = true;
        updateWatchingTimelines();
    });
    io.on("watch", function(data) {
        console.log(data);
        callback(data);
    });
}
