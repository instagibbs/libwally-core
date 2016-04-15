%module wallycore
%{
#include "../include/wally-core.h"
#include "../include/wally_bip39.h"

static void check_result(JNIEnv *jenv, int result) {
    if (!result)
        return;
    /* FIXME: Use result to determine exception type:
     * SWIG_JavaOutOfMemoryError, SWIG_JavaRuntimeException */
    SWIG_JavaThrowException(jenv, SWIG_JavaIllegalArgumentException, "Invalid argument");
}

static jobject create_obj(JNIEnv *jenv, void* p, long id) {

    jclass clazz = (*jenv)->FindClass(jenv, "com/blockstream/libwally/wallycore$obj");
    if (!clazz)
        return NULL;
    jmethodID ctor = (*jenv)->GetMethodID(jenv, clazz, "<init>", "(JJ)V");
    if (!ctor)
        return NULL;
    jobject obj = (*jenv)->NewObject(jenv, clazz, ctor, (long)p, id);
    return obj;
}

static void* get_obj(JNIEnv *jenv, jobject obj, long id) {

    if (!obj)
        return NULL;
    jclass clazz = (*jenv)->GetObjectClass(jenv, obj);
    if (!clazz)
        return NULL;
    jmethodID getter = (*jenv)->GetMethodID(jenv, clazz, "get_id", "()J");
    if (!getter || (*jenv)->CallLongMethod(jenv, obj, getter) != id)
        return NULL;
    getter = (*jenv)->GetMethodID(jenv, clazz, "get", "()J");
    return getter ? (void *)((*jenv)->CallLongMethod(jenv, obj, getter)) : NULL;
}
%}

%javaconst(1);
%ignore wally_free_string;
%ignore wally_bzero;

%pragma(java) jniclasscode=%{
    static {
        try {
            System.loadLibrary("wallycore");
        } catch (final UnsatisfiedLinkError e) {
            System.err.println("Native code library failed to load.\n" + e);
            System.exit(1);
        }
    }

    static private class obj {
        private transient long ptr;
        private final long id;
        protected obj(long ptr, long id) { this.ptr = ptr; this.id = id; }
        protected long get() { return ptr; }
        protected long get_id() { return ptr; }
    }
%}

/* Raise an exception whenever a function fails */
%exception {
  $action
  check_result(jenv, result);
}

/* Don't use our int return value except for exception checking */
%typemap(out) int %{
%}

/* Output parameters indicating how many bytes were written are converted
 * into return values. */
%typemap(in,noblock=1,numinputs=0) size_t *written(size_t sz) {
    sz = 0; $1 = ($1_ltype)&sz;
}
%typemap(argout,noblock=1) size_t* {
    $result = *$1;
}

/* Output strings are converted to native Java strings and returned */
%typemap(in,noblock=1,numinputs=0) char **output(char *temp = 0) {
  $1 = &temp;
}
%typemap(argout,noblock=1) (char **output) {
  if ($1) {
    $result = JCALL1(NewStringUTF, jenv, *$1);
    wally_free_string(*$1);
  } else
    $result = NULL;
}

/* Array handling */
%apply(char *STRING, size_t LENGTH) { (const unsigned char *bytes_in, size_t len) };
%apply(char *STRING, size_t LENGTH) { (unsigned char *bytes_out, size_t len) };
%apply(char *STRING, size_t LENGTH) { (unsigned char *bytes_in_out, size_t len) };

/* Opaque types are converted to/from an internal object holder class */
%define %java_opaque_struct(NAME, ID)
%typemap(in, numinputs=0) const struct NAME **output (const struct NAME * w) {
   w = 0; $1 = ($1_ltype)&w;
}
%typemap(argout) const struct NAME ** {
   $result = create_obj(jenv, *$1, ID);
}
%typemap (in) const struct NAME * {
    $1 = (struct NAME *)get_obj(jenv, $input, ID);
}
%typemap(jtype) const struct NAME * "Object"
%typemap(jni) const struct NAME * "jobject"
%enddef

/* Tell SWIG what uint32_t means */
typedef unsigned int uint32_t;

/* Change a functions return type to match its output type mapping */
%define %return_decls(FUNC, JTYPE, JNITYPE)
%typemap(jstype) int FUNC "JTYPE"
%typemap(jtype) int FUNC "JTYPE"
%typemap(jni) int FUNC "JNITYPE"
%enddef

%define %returns_void__(FUNC)
%return_decls(FUNC, void, void)
%enddef
%define %returns_size_t(FUNC)
%return_decls(FUNC, long, jlong)
%enddef
%define %returns_string(FUNC)
%return_decls(FUNC, String, jstring)
%enddef
%define %returns_struct(FUNC, STRUCT)
%return_decls(FUNC, Object, jobject)
%enddef

/* Our wrapped opaque types */
%java_opaque_struct(words, 1)

/* Our wrapped functions return types */
%returns_string(bip39_get_languages);
%returns_struct(bip39_get_wordlist, words);
%returns_string(bip39_get_word);
%returns_string(bip39_mnemonic_from_bytes);
%returns_size_t(bip39_mnemonic_to_bytes);
%returns_void__(bip39_mnemonic_validate);
%returns_size_t(bip39_mnemonic_to_seed);

%include "../include/wally-core.h"
%include "../include/wally_bip39.h"
