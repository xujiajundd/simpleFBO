//
//  GLRender.m
//  simpleFBO
//
//  Created by 徐家骏 on 16/10/17.
//
//

#import "GLRender.h"


GLfloat vertexData[] =
{
//    0.5f, 0.5f, 0.0f,    0.0f, 0.0f, 1.0f,
//    -0.5f, 0.5f, 0.0f,    0.0f, 0.0f, 1.0f,
//    0.5f, -0.5f, 0.0f,   0.0f, 0.0f, 1.0f,
//    -0.5f, -0.5f, 0.0f,   0.0f, 0.0f, 1.0f
    -1.0, -1.0,
    1.0, -1.0,
    -1.0, 1.0,
    1.0, 1.0
};

GLfloat texCoordData[] =
{
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f
};

@implementation GLRender

- (id)init
{
    self = [super init];
    if (self) {
        [self setupGL];
    }
    return self;
}

- (void)setupGL
{
    glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!glContext) {
        NSLog(@"Failed to create ES context");
    }
    
    [EAGLContext setCurrentContext:glContext];

    //编译和link shaders
    [self loadShaders];
    glUseProgram(_program);
    
    //投影矩阵
    mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, _modelViewProjectionMatrix);
    
    //顶点及数据
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    positionLoc = glGetAttribLocation(_program, "position");
    glEnableVertexAttribArray(positionLoc);
    glVertexAttribPointer(positionLoc, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    glGenBuffers(1, &_texCoordBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _texCoordBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(texCoordData), texCoordData, GL_STATIC_DRAW);
    // get text coord attribute index
    texCoordLoc = glGetAttribLocation(_program, "texCoord");
    glEnableVertexAttribArray(texCoordLoc);
    glVertexAttribPointer(texCoordLoc, 2, GL_FLOAT, GL_FALSE, 0, 0);
    // get sampler location
    uProjectionMatrix = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uSamplerLoc = glGetUniformLocation(_program, "uSampler");
    //    // to test texturing
//    GLubyte tex[] = {255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 128, 0, 255, 255, 128, 0};
//    glActiveTexture(GL_TEXTURE0);
//    glGenTextures(1, &texId);
//    glBindTexture(GL_TEXTURE_2D, texId);
//    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RG_EXT, 2, 2, 0, GL_RG_EXT, GL_UNSIGNED_BYTE, tex);
//    glUniform1i(uSamplerLoc, 0);
//    glBindTexture(GL_TEXTURE_2D, 0);
    
    CGImageRef spriteImage = [UIImage imageNamed:@"ziyan.jpg"].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image");
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);

    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &texId);
    glBindTexture(GL_TEXTURE_2D, texId);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    glUniform1i(uSamplerLoc, 0);
    free(spriteData);
    
    
    
    //设置uniform
    glUniformMatrix4fv(uProjectionMatrix, 1, GL_FALSE, _modelViewProjectionMatrix);

    
    //创建FBO
    fbo_width = 480;
    fbo_height = 640;
    //创建一个texture
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, // our empty IOSurface properties dictionary
                               NULL,
                               NULL,
                               0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                      1,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs,
                         kCVPixelBufferIOSurfacePropertiesKey,
                         empty);
    

    // for simplicity, lets just say the image is 640x480

    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, fbo_width, fbo_height,
                        kCVPixelFormatType_32BGRA,
                        attrs,
                        &renderTarget);
    // in real life check the error return value of course.
    if (err)
    {
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }

    
    CVOpenGLESTextureCacheRef textureCache;
    err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, glContext, NULL, &textureCache);
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
    }
    
    // first create a texture from our renderTarget
    // textureCache will be what you previously made with CVOpenGLESTextureCacheCreate
    CVOpenGLESTextureRef renderTexture;
    err = CVOpenGLESTextureCacheCreateTextureFromImage (
                                                  kCFAllocatorDefault,
                                                  textureCache,
                                                  renderTarget,
                                                  NULL, // texture attributes
                                                  GL_TEXTURE_2D,
                                                  GL_RGBA, // opengl format
                                                  fbo_width,
                                                  fbo_height,
                                                  GL_BGRA, // native iOS format
                                                  GL_UNSIGNED_BYTE,
                                                  0,
                                                  &renderTexture);
    // check err value
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    // set the texture up like any other texture
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture),
                  CVOpenGLESTextureGetName(renderTexture));

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // bind the texture to the framebuffer you're going to render to 
    // (boilerplate code to make a framebuffer not shown)
    glGenFramebuffers(1, &fboHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, fboHandle);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                           GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    
    // great, now you're ready to render to your image. 
 

/*
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &defaultFBO);
    
    glGenFramebuffers(1, &fboHandle);
    glGenTextures(1, &fboTex);
    glGenRenderbuffers(1, &depthBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, fboHandle);
    
    glBindTexture(GL_TEXTURE_2D, fboTex);
    glTexImage2D( GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 fbo_width, fbo_height,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 NULL);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fboTex, 0);
    
    glBindRenderbuffer(GL_RENDERBUFFER, depthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, fbo_width, fbo_height);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthBuffer);
*/
    
    // FBO status check
    GLenum status;
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    switch(status) {
        case GL_FRAMEBUFFER_COMPLETE:
            NSLog(@"fbo complete");
            break;
            
        case GL_FRAMEBUFFER_UNSUPPORTED:
            NSLog(@"fbo unsupported");
            break;
            
        default:
            /* programming error; will fail on all hardware */
            NSLog(@"Framebuffer Error");
            break;
    }
    
//    glBindFramebuffer(GL_FRAMEBUFFER, defaultFBO);

    
    
    glDisable(GL_DEPTH_TEST);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:glContext];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_texCoordBuffer);
    glDeleteFramebuffers(1, &fboHandle);
    //还需要把那个texture给delete了?

    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}


- (void)dealloc
{
    NSLog(@"GLRender dealloc");
    [self tearDownGL];
}


- (UIImage *)renderImage:(UIImage *)image
{
    UIImage *uiImage = nil;
    glViewport(0, 0, fbo_width, fbo_height);
    glClearColor(0.0f, 1.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFlush();
    
    
    if (kCVReturnSuccess == CVPixelBufferLockBaseAddress(renderTarget,
                                                         0)) {
        
//        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:renderTarget];
//        
//        CIContext *context = [CIContext contextWithOptions:nil];
//        CGImageRef myImage = [context
//                              createCGImage:ciImage
//                              fromRect:CGRectMake(0, 0,
//                                                  CVPixelBufferGetWidth(renderTarget),
//                                                  CVPixelBufferGetHeight(renderTarget))];
//        
//        uiImage = [UIImage imageWithCGImage:myImage];
        
        int w = CVPixelBufferGetWidth(renderTarget);
        int h = CVPixelBufferGetHeight(renderTarget);
        int r = CVPixelBufferGetBytesPerRow(renderTarget);
        int bytesPerPixel = r/w;
        
        unsigned char *buffer = CVPixelBufferGetBaseAddress(renderTarget);
        
        UIGraphicsBeginImageContext(CGSizeMake(w, h));
        
        CGContextRef c = UIGraphicsGetCurrentContext();
        
        unsigned char* data = CGBitmapContextGetData(c);
        if (data != NULL) {
            int maxY = h;
            for(int y = 0; y<maxY; y++) {
                for(int x = 0; x<w; x++) {
                    int offset = bytesPerPixel*((w*y)+x);
                    data[offset] = buffer[offset];     // R
                    data[offset+1] = buffer[offset+1]; // G
                    data[offset+2] = buffer[offset+2]; // B
                    data[offset+3] = buffer[offset+3]; // A
                }
            }
        }
        uiImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CVPixelBufferUnlockBaseAddress(renderTarget, 0);
    }
    else{
        NSLog(@"error...");
    }
    
    
    return uiImage;
}





- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"FragmentShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    
    //这个可以不bind，那么link的时候会自动分配一个slot //xujj
//    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
//    glBindAttribLocation(_program, ATTRIB_NORMAL, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
//    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
//    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}


static void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout)
{
    float r_l = right - left;
    float t_b = top - bottom;
    float f_n = far - near;
    float tx = - (right + left) / (right - left);
    float ty = - (top + bottom) / (top - bottom);
    float tz = - (far + near) / (far - near);
    
    mout[0] = 2.0f / r_l;
    mout[1] = 0.0f;
    mout[2] = 0.0f;
    mout[3] = 0.0f;
    
    mout[4] = 0.0f;
    mout[5] = 2.0f / t_b;
    mout[6] = 0.0f;
    mout[7] = 0.0f;
    
    mout[8] = 0.0f;
    mout[9] = 0.0f;
    mout[10] = -2.0f / f_n;
    mout[11] = 0.0f;
    
    mout[12] = tx;
    mout[13] = ty;
    mout[14] = tz;
    mout[15] = 1.0f;
}

@end
