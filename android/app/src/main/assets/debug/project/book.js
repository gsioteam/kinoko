
class BookCollection extends glib.Collection {

    reload(cb) {
        
    }
}

module.exports = function(data) {
    let col = BookCollection.new(data);
    return col;
};