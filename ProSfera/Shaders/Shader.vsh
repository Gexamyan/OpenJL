//
//  Shader.vsh
//  ProSfera
//
//  Created by Seryozha Movsisyan on 7/27/16.
//  Copyright © 2016 Seryozha Movsisyan. All rights reserved.
//

attribute vec4 position;

varying lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;

void main()
{
   // if (gl_Position.x >= 0.0) {
     
        colorVarying = vec4(0.0,0.2,0.0,1.0);

  //  }else{
    //    colorVarying = vec4(1.0,0.2,0.0,1.0);
    //}
       gl_Position = modelViewProjectionMatrix * position;
}
