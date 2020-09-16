
module.exports = function(object) {
    if (typeof object === 'function') {
        return glib.Callback.fromFunction(object);
    } else {
        throw new Error("Unsupport object " + object);
    }
};
