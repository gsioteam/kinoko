module.exports = function (baseObject) {
  let nCount, singleArgument, element
  for (nCount = 1; nCount < arguments.length; nCount++) {
    singleArgument = arguments[nCount]
    for (element in singleArgument) {
      if (Object.prototype.hasOwnProperty.call(singleArgument, element)) {
        baseObject[element] = singleArgument[element]
      }
    }
  }
  return baseObject
}
