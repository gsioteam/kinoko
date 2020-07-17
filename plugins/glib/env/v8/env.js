
function calculatePath(base_path, path) {
    let base_arr = base_path.split('/');
    base_arr.pop();
    let arr = path.split('/');
    for (let i = 0, t = arr.length; i < t; ++i) {
        let seg = arr[i];
        if (seg === '.' || seg.length === 0) {
        } else if (seg === '..') {
            base_arr.pop();
        }else {
            base_arr.push(seg);
        }
    }
    return base_arr.join('/');
}

function loadSubscript(path, file_dir) {
    function require(n) {
        let path;
        if (n[0] === '.') {
            path = calculatePath(file_dir, n)
        }else if (n[0] === '/') {
            path = n;
        } else {
            path = calculatePath(file_dir, n);
        }
        return loadSubscript(path, path.replace(/\/[^\/]+$/, ''))
    }

    return _loadScript(path, require);
}
function make_string(arguments) {
    let arr = [];;
    for (let i = 0, t = arguments.length; i < t; ++i) {
        let o = arguments[i];
        if (typeof o === 'undefined') {
        } else {
            arr.push(arguments[i].toString());
        }
    }
    return arr;
}

(function (file_path) {
    function require(n) {
        let path;
        if (n[0] === '.') {
            path = calculatePath(file_path, n)
        }else if (n[0] === '/') {
            path = n;
        } else {
            path = calculatePath(libs_path, n);
        }
        return loadSubscript(path, path.replace(/\/[^\/]+$/, ''));
    }
    this.require = require;
    this.console = {
        log() {
            _print(1, make_string(arguments).join('\n'));
        },
        warn() {
            _print(2, make_string(arguments).join('\n'));
        },
        error() {
            _print(3, make_string(arguments).join('\n'));
        }
    };
});