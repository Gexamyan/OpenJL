//
//  Shader.fsh
//  ProSfera
//
//  Created by Seryozha Movsisyan on 7/27/16.
//  Copyright © 2016 Seryozha Movsisyan. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;

       // gl_FragColor = vec4(1.0,0.2,0.0,1.0);
 }
