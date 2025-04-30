vec4 sdfAmongus(vec3 p) 
{
    float s = 0.;

    float circle = sdfSphere(p, vec3(0.18,2.1, 0.0), 0.8);
    float circle2 = sdfSphere(p, vec3(-0.18,2.1, 0.0), 0.8);
    circle = opSmoothUnion(circle, circle2, 0.1);
    // // float body = opSmoothUnion(circle, chest, 0.1);

    // float body = chest;

    vec3 modifiedPoint = opElongate(p - vec3(0.0, 1.4, 0.), vec3(0.5, 0.8, 0.2));
    float modifiedSphere = sdfSphere(modifiedPoint, vec3(0.0, 0.0, 0.0), 0.6);

    float body = opSmoothUnion(circle, modifiedSphere, 0.1);
    // float body = modifiedSphere;

    float cylinderLeft = sdfCylinder(p - vec3(-0.63, .02, 0.0), .6, .42);
    float cylinderRight = sdfCylinder(p - vec3(0.63, .02, 0.0), .6, .42);
    cylinderLeft = opRound(cylinderLeft, .05);
    cylinderRight = opRound(cylinderRight, .05);

    float legsTogether = sdfUnion(cylinderLeft, cylinderRight);

    vec3 modP = opElongate(p - vec3(0, 1.8, -0.8), vec3(0.5, 0.1, 0.1));
    float visor = sdEllipsoid(modP, vec3(0.3, 0.3, 0.1));
    
    body = opSmoothUnion(body, legsTogether, 0.1);
    body = sdfUnion(body, legsTogether);

    vec3 scaledP = opElongate(p - vec3(0.0, 1.5, 1.0), vec3(0.5, 0.5, 0.2));
    float backpack = sdfSphere(scaledP, vec3(0.0, 0.0, 0.0), 0.2);

    body = sdfUnion(backpack, body);

    s = sdfUnion(body, visor);

    vec3 color = vec3(0.0, 0.0, 0.0);
    if (s == body) color.x = 1.0;
    else if (s == visor) color = vec3(0.38, 0.84, 1.0);

    return vec4(color, s);

}