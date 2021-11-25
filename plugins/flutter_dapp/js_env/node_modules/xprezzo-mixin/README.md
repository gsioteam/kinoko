# xprezzo-mixin

An implementation of setting the prototype of an instianted object.

## usage


```
$ npm install --save xprezzo-mixin
```

```javascript
var mixin = require('xprezzo-mixin')

var obj = {}
mixin(obj, {
  foo: function () {
    return 'bar'
  }
})
obj.foo() // bar
```

## People

Xprezzo and related projects are maintained by [Ben Ajenoui](mailto:info@seohero.io) and sponsored by [SEO Hero](https://www.seohero.io).

# License

[MIT](LICENSE)
