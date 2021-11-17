# flutter_dapp

A runtime application plugin for flutter. Using [js_script](https://github.com/gsioteam/js_script) for logic script, and [xml_layout](https://github.com/gsioteam/xml_layout) for UI template.

## Usage

```dart
DApp(
    entry: '/main',
    fileSystems: [
        // A file wrap for reading script and template
        fileSystem,
    ],
)
```

