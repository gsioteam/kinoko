
global.console = {
    log() {
        _printInfo.apply(this, arguments);
    },
    warn() {
        _printWarn.apply(this, arguments);
    },
    error() {
        _printError.apply(this, arguments);
    }
};

global.glib = require('./glib');

global.PageURL = require('./page_url');