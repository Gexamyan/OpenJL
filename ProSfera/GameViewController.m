//
//  GameViewController.m
//  ProSfera
//
//  Created by Seryozha Movsisyan on 7/27/16.
//  Copyright © 2016 Seryozha Movsisyan. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    NUM_ATTRIBUTES
};
 //GLfloat array[45];
int globalcount =48000;

GLfloat gCubeVertexData[48000];// =
//{
//    ///////1////////
//    0.0f, 0.0f, 0.0f,
//    1.0f, 0.0f, 0.0f,
//    1.0f, 1.0f, 0.0f,
//    
//    ///////2////////
//
//    1.0f, 1.0f, 0.0f,
//    0.0f, 1.0f, 0.0f,
//    0.0f, 0.0f, 0.0f,
//    
//    ///////3////////
//
//    0.0f, 0.0f, 0.0f,
//    1.0f, 0.0f, 0.0f,
//    1.0f, 0.0f, 1.0f,
//    
//    ///////4////////
//
//    1.0f, 0.0f, 1.0f,
//    0.0f, 0.0f, 1.0f,
//    0.0f, 0.0f, 0.0f,
//    
//    ///////5////////
//
//    0.0f, 1.0f, 0.0f,
//    0.0f, 1.0f, 1.0f,
//    1.0f, 1.0f, 0.0f,
//    
//    ///////6////////
//    
//    1.0f, 1.0f, 0.0f,
//    1.0f, 1.0f, 1.0f,
//    0.0f, 1.0f, 1.0f,
//    
//    ///////7////////
//    
//    0.0f, 1.0f, 1.0f,
//    0.0f, 0.0f, 1.0f,
//    1.0f, 1.0f, 1.0f,
//    
//    ///////8////////
//    
//    1.0f, 1.0f, 1.0f,
//    1.0f, 0.0f, 1.0f,
//    0.0f, 0.0f, 1.0f,
//    
//    ///////9////////
//    
//    0.0f, 0.0f, 0.0f,
//    0.0f, 0.0f, 1.0f,
//    0.0f, 1.0f, 0.0f,
//    
//    ///////10////////
//    
//    0.0f, 1.0f, 0.0f,
//    0.0f, 1.0f, 1.0f,
//    0.0f, 0.0f, 1.0f,
//    
//    ///////11////////
//    
//    1.0f, 0.0f, 0.0f,
//    1.0f, 0.0f, 1.0f,
//    1.0f, 1.0f, 0.0f,
//    
//    ///////12////////
//    
//    1.0f, 1.0f, 0.0f,
//    1.0f, 1.0f, 1.0f,
//    1.0f, 0.0f, 1.0f
//    
//
//};

@interface GameViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    //GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    createVertexArrayList();

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    glBindVertexArrayOES(0);
}


- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
   _rotation += self.timeSinceLastUpdate * 0.5f;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{

    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    
    glDrawArrays(GL_TRIANGLES, 0, 16000);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
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
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    
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
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    
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

void createVertexArrayList () {
    int count1 = 120;
    int count2 = 50;

    
    
    double alpha = 6.28/30;
    GLfloat vertexdata[count2][count1];
    for (int j=0;j < count2; j++) {
        double radius = sqrt(1-j*j*0.0004);
       // GLfloat array[45];
        for (int i = 0; i <count1; i+=3){
            if (j == 49) {
                vertexdata[j][i] = 0.0f;
                vertexdata[j][i+1] = 0.0f;
                vertexdata[j][i+2] = 1.0f;

            } else {
            vertexdata[j][i] = radius*cos(i*alpha);
            vertexdata[j][i+1] = radius*sin(i*alpha);
            vertexdata[j][i+2] = j*0.02f;
            }
        }

    }
    
    
    
    GLfloat matrixArray[globalcount];
    int counter = 0;
    for (int i = 0; i < count2; i++) {

        for (int j = 0; j < count1; j += 3) {
            
            matrixArray[counter] = vertexdata[i][j];
            counter ++;
            matrixArray[counter] = vertexdata[i][j+1];
            counter++;
            matrixArray[counter] = vertexdata[i][j+2];
            counter ++;
            if (i == 49) {
                matrixArray[counter] = vertexdata[i][j];
                counter++;
                matrixArray[counter] = vertexdata[i][j+1];
                counter++;
                matrixArray[counter] = vertexdata[i][j+2];
                counter++;

            } else {
            matrixArray[counter] = vertexdata[i+1][j];
            counter++;
            matrixArray[counter] = vertexdata[i+1][j+1];
            counter++;
            matrixArray[counter] = vertexdata[i+1][j+2];
            counter++;
            }
            
        }
        for (int j = 0;j < count1; j += 3) {
            if (i == 49) {
                matrixArray[counter] = vertexdata[i][j];
                counter ++;
                matrixArray[counter] = vertexdata[i][j+1];
                counter++;
                matrixArray[counter] = vertexdata[i][j+2];
                counter ++;

            } else {
            matrixArray[counter] = vertexdata[i+1][j];
            counter ++;
            matrixArray[counter] = vertexdata[i+1][j+1];
            counter++;
            matrixArray[counter] = vertexdata[i+1][j+2];
            counter ++;
            }
            matrixArray[counter] = vertexdata[i][j];
            counter++;
            matrixArray[counter] = vertexdata[i][j+1];
            counter++;
            matrixArray[counter] = vertexdata[i][j+2];
            counter++;
          }
            
            
    }

    
    
    /////////// 2-rd ktor/////////////
    
    
    for (int i = 0; i < count2; i++) {
        
            for (int j = 0;j < count1; j += 3) {
                
                matrixArray[counter] = vertexdata[i][j];
                counter ++;
                matrixArray[counter] = vertexdata[i][j+1];
                counter++;
                matrixArray[counter] = -vertexdata[i][j+2];
                counter ++;
                if (i == 49) {
                    matrixArray[counter] = vertexdata[i][j];
                    counter++;
                    matrixArray[counter] = vertexdata[i][j+1];
                    counter++;
                    matrixArray[counter] = -vertexdata[i][j+2];
                    counter++;
                }
                else {
                matrixArray[counter] = vertexdata[i+1][j];
                counter++;
                matrixArray[counter] = vertexdata[i+1][j+1];
                counter++;
                matrixArray[counter] = -vertexdata[i+1][j+2];
                counter++;
                }
            }
            for (int j = 0;j < count1; j += 3) {
                
                if (i == 49) {
                    matrixArray[counter] = vertexdata[i][j];
                    counter ++;
                    matrixArray[counter] = vertexdata[i][j+1];
                    counter++;
                    matrixArray[counter] = -vertexdata[i][j+2];
                    counter ++;
                    
                } else {
                    matrixArray[counter] = vertexdata[i+1][j];
                    counter ++;
                    matrixArray[counter] = vertexdata[i+1][j+1];
                    counter++;
                    matrixArray[counter] = -vertexdata[i+1][j+2];
                    counter ++;
                }

                matrixArray[counter] = vertexdata[i][j];
                counter++;
                matrixArray[counter] = vertexdata[i][j+1];
                counter++;
                matrixArray[counter] = -vertexdata[i][j+2];
                counter++;
            }
            
            
        
    }

    for (int i = 0; i<globalcount; i++) {
        gCubeVertexData[i] =matrixArray[i];
    }
}
   @end
