//
//  GLRender.h
//  simpleFBO
//
//  Created by 徐家骏 on 16/10/17.
//
//

#import <Foundation/Foundation.h>
//#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface GLRender : NSObject
{
    GLuint _program;

//    GLKMatrix4 _modelViewProjectionMatrix;
    GLfloat _modelViewProjectionMatrix[16];
    float _rotation;

    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _texCoordBuffer;

    int uProjectionMatrix;
    int uSamplerLoc;
    int positionLoc;
    int texCoordLoc;


    // FBO variables
    GLuint fboHandle;
    GLuint depthBuffer;
    GLuint fboTex;
    int fbo_width;
    int fbo_height;

    // test
    GLuint texId;

    // GL context
    EAGLContext *glContext;

    GLint defaultFBO;
    
    CVPixelBufferRef renderTarget;
}

- (UIImage *)renderImage:(UIImage *)image;
@end
