#include <glad/glad.h>
#include <windows.h>

PFNGLACTIVETEXTUREPROC glad_glActiveTexture = NULL;
PFNGLGENBUFFERSPROC glad_glGenBuffers = NULL;
PFNGLBINDBUFFERPROC glad_glBindBuffer = NULL;
PFNGLBUFFERDATAPROC glad_glBufferData = NULL;
PFNGLBUFFERSUBDATAPROC glad_glBufferSubData = NULL;
PFNGLDELETEBUFFERSPROC glad_glDeleteBuffers = NULL;
PFNGLGENVERTEXARRAYSPROC glad_glGenVertexArrays = NULL;
PFNGLBINDVERTEXARRAYPROC glad_glBindVertexArray = NULL;
PFNGLDELETEVERTEXARRAYSPROC glad_glDeleteVertexArrays = NULL;
PFNGLENABLEVERTEXATTRIBARRAYPROC glad_glEnableVertexAttribArray = NULL;
PFNGLVERTEXATTRIBPOINTERPROC glad_glVertexAttribPointer = NULL;
PFNGLCREATEPROGRAMPROC glad_glCreateProgram = NULL;
PFNGLCREATESHADERPROC glad_glCreateShader = NULL;
PFNGLSHADERSOURCEPROC glad_glShaderSource = NULL;
PFNGLCOMPILESHADERPROC glad_glCompileShader = NULL;
PFNGLGETSHADERIVPROC glad_glGetShaderiv = NULL;
PFNGLGETSHADERINFOLOGPROC glad_glGetShaderInfoLog = NULL;
PFNGLATTACHSHADERPROC glad_glAttachShader = NULL;
PFNGLLINKPROGRAMPROC glad_glLinkProgram = NULL;
PFNGLGETPROGRAMIVPROC glad_glGetProgramiv = NULL;
PFNGLGETPROGRAMINFOLOGPROC glad_glGetProgramInfoLog = NULL;
PFNGLUSEPROGRAMPROC glad_glUseProgram = NULL;
PFNGLDELETESHADERPROC glad_glDeleteShader = NULL;
PFNGLDELETEPROGRAMPROC glad_glDeleteProgram = NULL;
PFNGLGETUNIFORMLOCATIONPROC glad_glGetUniformLocation = NULL;
PFNGLUNIFORM1FPROC glad_glUniform1f = NULL;
PFNGLUNIFORM2FPROC glad_glUniform2f = NULL;
PFNGLUNIFORM3FPROC glad_glUniform3f = NULL;
PFNGLUNIFORM4FPROC glad_glUniform4f = NULL;
PFNGLUNIFORM1IPROC glad_glUniform1i = NULL;
PFNGLUNIFORMMATRIX3FVPROC glad_glUniformMatrix3fv = NULL;
PFNGLGENFRAMEBUFFERSPROC glad_glGenFramebuffers = NULL;
PFNGLBINDFRAMEBUFFERPROC glad_glBindFramebuffer = NULL;
PFNGLFRAMEBUFFERTEXTURE2DPROC glad_glFramebufferTexture2D = NULL;
PFNGLDELETEFRAMEBUFFERSPROC glad_glDeleteFramebuffers = NULL;

static HMODULE opengl32_module = NULL;

static void* get_proc(const char *name) {
    void *p = (void *)wglGetProcAddress(name);
    if(p == NULL || (p == (void*)0x1) || (p == (void*)0x2) || (p == (void*)0x3) || (p == (void*)-1)) {
        if(opengl32_module == NULL) {
            opengl32_module = LoadLibraryA("opengl32.dll");
        }
        p = (void *)GetProcAddress(opengl32_module, name);
    }
    return p;
}

int gladLoadGLLoader(GLADloadproc proc) {
    glad_glActiveTexture = (PFNGLACTIVETEXTUREPROC)proc("glActiveTexture");
    glad_glGenBuffers = (PFNGLGENBUFFERSPROC)proc("glGenBuffers");
    glad_glBindBuffer = (PFNGLBINDBUFFERPROC)proc("glBindBuffer");
    glad_glBufferData = (PFNGLBUFFERDATAPROC)proc("glBufferData");
    glad_glBufferSubData = (PFNGLBUFFERSUBDATAPROC)proc("glBufferSubData");
    glad_glDeleteBuffers = (PFNGLDELETEBUFFERSPROC)proc("glDeleteBuffers");
    glad_glGenVertexArrays = (PFNGLGENVERTEXARRAYSPROC)proc("glGenVertexArrays");
    glad_glBindVertexArray = (PFNGLBINDVERTEXARRAYPROC)proc("glBindVertexArray");
    glad_glDeleteVertexArrays = (PFNGLDELETEVERTEXARRAYSPROC)proc("glDeleteVertexArrays");
    glad_glEnableVertexAttribArray = (PFNGLENABLEVERTEXATTRIBARRAYPROC)proc("glEnableVertexAttribArray");
    glad_glVertexAttribPointer = (PFNGLVERTEXATTRIBPOINTERPROC)proc("glVertexAttribPointer");
    glad_glCreateProgram = (PFNGLCREATEPROGRAMPROC)proc("glCreateProgram");
    glad_glCreateShader = (PFNGLCREATESHADERPROC)proc("glCreateShader");
    glad_glShaderSource = (PFNGLSHADERSOURCEPROC)proc("glShaderSource");
    glad_glCompileShader = (PFNGLCOMPILESHADERPROC)proc("glCompileShader");
    glad_glGetShaderiv = (PFNGLGETSHADERIVPROC)proc("glGetShaderiv");
    glad_glGetShaderInfoLog = (PFNGLGETSHADERINFOLOGPROC)proc("glGetShaderInfoLog");
    glad_glAttachShader = (PFNGLATTACHSHADERPROC)proc("glAttachShader");
    glad_glLinkProgram = (PFNGLLINKPROGRAMPROC)proc("glLinkProgram");
    glad_glGetProgramiv = (PFNGLGETPROGRAMIVPROC)proc("glGetProgramiv");
    glad_glGetProgramInfoLog = (PFNGLGETPROGRAMINFOLOGPROC)proc("glGetProgramInfoLog");
    glad_glUseProgram = (PFNGLUSEPROGRAMPROC)proc("glUseProgram");
    glad_glDeleteShader = (PFNGLDELETESHADERPROC)proc("glDeleteShader");
    glad_glDeleteProgram = (PFNGLDELETEPROGRAMPROC)proc("glDeleteProgram");
    glad_glGetUniformLocation = (PFNGLGETUNIFORMLOCATIONPROC)proc("glGetUniformLocation");
    glad_glUniform1f = (PFNGLUNIFORM1FPROC)proc("glUniform1f");
    glad_glUniform2f = (PFNGLUNIFORM2FPROC)proc("glUniform2f");
    glad_glUniform3f = (PFNGLUNIFORM3FPROC)proc("glUniform3f");
    glad_glUniform4f = (PFNGLUNIFORM4FPROC)proc("glUniform4f");
    glad_glUniform1i = (PFNGLUNIFORM1IPROC)proc("glUniform1i");
    glad_glUniformMatrix3fv = (PFNGLUNIFORMMATRIX3FVPROC)proc("glUniformMatrix3fv");
    glad_glGenFramebuffers = (PFNGLGENFRAMEBUFFERSPROC)proc("glGenFramebuffers");
    glad_glBindFramebuffer = (PFNGLBINDBUFFERPROC)proc("glBindFramebuffer");
    glad_glFramebufferTexture2D = (PFNGLFRAMEBUFFERTEXTURE2DPROC)proc("glFramebufferTexture2D");
    glad_glDeleteFramebuffers = (PFNGLDELETEFRAMEBUFFERSPROC)proc("glDeleteFramebuffers");
    return 1;
}

int gladLoadGL(void) {
    return gladLoadGLLoader(get_proc);
}
