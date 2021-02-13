//
//  quickjs_ext.c
//  quickjs_osx
//
//  Created by gen on 12/23/20.
//  Copyright © 2020 nioqio. All rights reserved.
//

#include "quickjs_ext.h"
#include "quickjs.c"


JS_BOOL JS_IsInt8Array(JSContext *ctx, JSValue value) {
    if (JS_IsObject(value)) {
        return JS_VALUE_GET_OBJ(value)->class_id == JS_CLASS_INT8_ARRAY;
    }
    return 0;
}
JS_BOOL JS_IsUint8Array(JSContext *ctx, JSValue value) {
    if (JS_IsObject(value)) {
        JSObject *p = JS_VALUE_GET_OBJ(value);
        return p->class_id == JS_CLASS_UINT8_ARRAY || p->class_id == JS_CLASS_UINT8C_ARRAY;
    }
    return 0;
}
JS_BOOL JS_IsInt16Array(JSContext *ctx, JSValue value) {
    if (JS_IsObject(value)) {
        return JS_VALUE_GET_OBJ(value)->class_id == JS_CLASS_INT16_ARRAY;
    }
    return 0;
}
JS_BOOL JS_IsUint16Array(JSContext *ctx, JSValue value) {
    if (JS_IsObject(value)) {
        return JS_VALUE_GET_OBJ(value)->class_id == JS_CLASS_UINT16_ARRAY;
    }
    return 0;
}
JS_BOOL JS_IsInt32Array(JSContext *ctx, JSValue value) {
    if (JS_IsObject(value)) {
        return JS_VALUE_GET_OBJ(value)->class_id == JS_CLASS_INT32_ARRAY;
    }
    return 0;
}
JS_BOOL JS_IsUint32Array(JSContext *ctx, JSValue value) {
    if (JS_IsObject(value)) {
        return JS_VALUE_GET_OBJ(value)->class_id == JS_CLASS_UINT32_ARRAY;
    }
    return 0;
}
JS_BOOL JS_IsInt64Array(JSContext *ctx, JSValue value) {
    if (JS_IsObject(value)) {
        return JS_VALUE_GET_OBJ(value)->class_id == JS_CLASS_BIG_INT64_ARRAY;
    }
    return 0;
}
JS_BOOL JS_IsUint64Array(JSContext *ctx, JSValue value) {
    if (JS_IsObject(value)) {
        return JS_VALUE_GET_OBJ(value)->class_id == JS_CLASS_BIG_UINT64_ARRAY;
    }
    return 0;
}

JS_BOOL JS_IsFloat32Array(JSContext *ctx, JSValue value) {
    if (JS_IsObject(value)) {
        return JS_VALUE_GET_OBJ(value)->class_id == JS_CLASS_FLOAT32_ARRAY;
    }
    return 0;
}
JS_BOOL JS_IsFloat64Array(JSContext *ctx, JSValue value) {
    if (JS_IsObject(value)) {
        return JS_VALUE_GET_OBJ(value)->class_id == JS_CLASS_FLOAT64_ARRAY;
    }
    return 0;
}

uint32_t JS_GetTypedArrayLength(JSContext *ctx, JSValue value) {
    JSValue val = js_typed_array_get_length(ctx, value);
    uint32_t ret = 0;
    if (JS_ToUint32(ctx, &ret, val) == 0) {
        return ret;
    }
    return 0;
}

JSValue js_array_foreach(JSContext *context, JSValueConst this_val, int argc, JSValueConst *argv, int magic, JSValue *func_data) {
    int64_t ptr;
    JS_ToBigInt64(context, &ptr, func_data[0]);
    JS_ForEachFunction func = (JS_ForEachFunction)ptr;
    JS_ToBigInt64(context, &ptr, func_data[1]);
    void *data = (void *)ptr;
    func(context, data, argc, argv);
    return JS_UNDEFINED;
}

void JS_ArrayForEach(JSContext *context, JSValue value, JS_ForEachFunction func, void *data) {
    JSValue params[2];
    params[0] = JS_NewBigInt64(context, (int64_t)func);
    params[1] = JS_NewBigInt64(context, (int64_t)data);
    JSValue cfunc = JS_NewCFunctionData(context, js_array_foreach, 1, 0, 2, params);
    js_array_every(context, value, 1, &cfunc, special_forEach);
    JS_FreeValue(context, cfunc);
    JS_FreeValue(context, params[0]);
    JS_FreeValue(context, params[1]);
}

JSValue JS_GetPromiseConstructor(JSContext *ctx) {
    return ctx->promise_ctor;
}


void *JS_GetOpaque3(JSValueConst obj) {
    JSObject *p;
    if (JS_VALUE_GET_TAG(obj) != JS_TAG_OBJECT)
        return NULL;
    p = JS_VALUE_GET_OBJ(obj);
    return p->u.opaque;
}

JSValue require_handler(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    JSValue ret = JS_UNDEFINED;
    if (argc > 0) {
        JSValue require_name = argv[0];
        if (JS_IsString(require_name)) {
            const char *filename = JS_ToCString(ctx, require_name);
            if (filename) {
                JSAtom atom = JS_GetScriptOrModuleName(ctx, 1);
                const char *base = JS_AtomToCString(ctx, atom);
                if (base) {
                    JSModuleDef *m = JS_RunModule(ctx, base, filename);
                    if (m) {
                        ret = JS_GetModuleDefault(ctx, m);
                    }
                    JS_FreeCString(ctx, base);
                }
                JS_FreeAtom(ctx, atom);
                JS_FreeCString(ctx, filename);
            }
        }
    }
    return ret;
}

void JS_AddIntrinsicRequire(JSContext *ctx) {
    JSValue global = JS_GetGlobalObject(ctx);
    JS_SetPropertyStr(ctx, global, "require", JS_NewCFunction(ctx, require_handler, "require", 1));
    JS_FreeValue(ctx, global);
}

JSValue JS_GetModuleDefault(JSContext *ctx, JSModuleDef *module) {
    JSValue value = js_get_module_ns(ctx, module);
    if (!JS_IsException(value)) {
        JSValue ret = JS_GetProperty(ctx, value, JS_ATOM_default);
        JS_FreeValue(ctx, value);
        if (!JS_IsException(ret)) {
            return ret;
        }
    }
    return JS_UNDEFINED;
}

int JS_GetLength(JSContext *ctx, JSValue value) {
    JSValue val = JS_GetPropertyStr(ctx, value, "length");
    int n = 0;
    JS_ToInt32(ctx, &n, val);
    JS_FreeValue(ctx, val);
    return n;
}