//
//  controller.hpp
//  refractiveObj
//
//  Created by Execution on 28/05/2017.
//  Copyright © 2017 Execution. All rights reserved.
//

#ifndef controller_hpp
#define controller_hpp

#include "main.hpp"

class Controller {
private:
    GLFWwindow *window;
    
    double lastXpos;
    double lastYpos;
    float horizontalAngle;
    float verticalAngle;
    float mouseSpeed;
    vec3 direction;
    vec3 right;
    vec3 up;
    
    float dist;
    bool zPressed;
    bool xPressed;
    double lastTime;
    int frameCount;
public:
    mat4 Projection;
    mat4 View;
    mat4 Model_object;
    mat4 MVP_object;
    mat4 Model_table;
    mat4 MVP_table;
    
    vec3 camera;
    vec3 lightPos;
    
    float fps;
    
    Controller();
    ~Controller();
    void init(GLFWwindow *window);
    void update();
};
#endif /* controller_hpp */
