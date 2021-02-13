//
//  quickjs_ext.h
//  quickjs_osx
//
//  Created by gen on 12/23/20.
//  Copyright © 2020 nioqio. All rights reserved.
//

#ifndef quickjs_ext_h
#define quickjs_ext_h

#include "quickjs.h"

#ifdef __cplusplus
extern "C" {
#endif
JS_BOOL JS_IsInt8Array(JSContext *ctx, JSValue value);
JS_BOOL JS_IsUint8Array(JSContext *ctx, JSValue value);
JS_BOOL JS_IsInt16Array(JSContext *ctx, JSValue value);
JS_BOOL JS_IsUint16Array(JSContext *ctx, JSValue value);
JS_BOOL JS_IsInt32Array(JSContext *ctx, JSValue value);
JS_BOOL JS_IsUint32Array(JSContext *ctx, JSValue value);
JS_BOOL JS_IsInt64Array(JSContext *ctx, JSValue value);
JS_BOOL JS_IsUint64Array(JSContext *ctx, JSValue value);

JS_BOOL JS_IsFloat32Array(JSContext *ctx, JSValue value);
JS_BOOL JS_IsFloat64Array(JSContext *ctx, JSValue value);

uint32_t JS_GetTypedArrayLength(JSContext *ctx, JSValue value);

JSValue JS_GetPromiseConstructor(JSContext *ctx);

typedef void (*JS_ForEachFunction)(JSContext *ctx, void *data, int argc, JSValueConst *argv);

void JS_ArrayForEach(JSContext *ctx, JSValue value, JS_ForEachFunction func, void *data);

void *JS_GetOpaque3(JSValueConst obj);

void JS_AddIntrinsicRequire(JSContext *ctx);
void JS_AddIntrinsicWorker(JSContext *ctx);

JSValue JS_GetModuleDefault(JSContext *ctx, JSModuleDef *module);

int JS_GetLength(JSContext *ctx, JSValue value);

#ifdef __cplusplus
}
#endif

#endif /* quickjs_ext_h */
