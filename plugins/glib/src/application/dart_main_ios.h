

#ifdef __cplusplus
extern "C" {
#endif

typedef void * DartPtr;

typedef void (*CallClass)(DartPtr cls, const char *name, DartPtr params, int length, DartPtr result);
typedef void (*CallInstance)(DartPtr cls, const char *name, DartPtr params, int length, DartPtr result);
typedef int (*CreateFromNative)(DartPtr cls, DartPtr ins);
typedef void (*OnSendSignal)(void);

void setupLibrary(CallClass call_class, CallInstance call_instance, CreateFromNative from_native, OnSendSignal on_send_signal);
void destroyLibrary(void);
void postSetup(const char *path);
void setCacertPath(const char *path);
void runOnMainThread(void);

void setDebugPath(const char *debug_path);

#ifdef __cplusplus
}
#endif
