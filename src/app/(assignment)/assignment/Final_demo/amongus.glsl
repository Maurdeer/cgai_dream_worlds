/////////////////////////////////////////////////////
//// CS 8803/4803 CGAI: Computer Graphics in AI Era
//// Assignment 1A: SDF and Ray Marching
/////////////////////////////////////////////////////

precision highp float;              //// set default precision of float variables to high precision

varying vec2 vUv;                   //// screen uv coordinates (varying, from vertex shader)
uniform vec2 iResolution;           //// screen resolution (uniform, from CPU)
uniform float iTime;                //// time elapsed (uniform, from CPU)

const vec3 CAM_POS = vec3(-0.35, 1.0, -3.0);
#define PI 3.1415925359


/////////////////////////////////////////////////////
//// sdf functions
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 1: sdf primitives
//// You are asked to implement sdf primitive functions for sphere, plane, and box.
//// In each function, you will calculate the sdf value based on the function arguments.
/////////////////////////////////////////////////////

//// sphere: p - query point; c - sphere center; r - sphere radius
float sdfSphere(vec3 p, vec3 c, float r)
{
    //// your implementation starts
    
    return length(p - c) - r;
    
    //// your implementation ends
}

//// plane: p - query point; h - height
float sdfPlane(vec3 p, float h)
{
    //// your implementation starts

    return p.y + h;
    
    //// your implementation ends
}

//// box: p - query point; c - box center; b - box half size (i.e., the box size is (2*b.x, 2*b.y, 2*b.z))
float sdfBox(vec3 p, vec3 c, vec3 b)
{
    //// your implementation starts
    
    vec3 q = abs(p - c) - b;
    return length (max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
    
    //// your implementation ends
}

/////////////////////////////////////////////////////
//// boolean operations
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 2: sdf boolean operations
//// You are asked to implement sdf boolean operations for intersection, union, and subtraction.
/////////////////////////////////////////////////////

float sdfIntersection(float s1, float s2)
{
    //// your implementation starts
    
    return max(s1, s2);

    //// your implementation ends
}

float sdfUnion(float s1, float s2)
{
    //// your implementation starts
    
    return min(s1, s2);

    //// your implementation ends
}

float sdfSubtraction(float s1, float s2)
{
    //// your implementation starts
    
    return max(s1, -s2);

    //// your implementation ends
}

/////////////////////////////////////////////////////
//// sdf calculation
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 3: scene sdf
//// You are asked to use the implemented sdf boolean operations to draw the following objects in the scene by calculating their CSG operations.
/////////////////////////////////////////////////////

vec3 rotate(vec3 p, vec3 ax, float ro)
{
    return mix(dot(p, ax) * ax, p, cos(ro)) + sin(ro) * cross(ax, p);
}

float sdfCapsule(vec3 p, vec3 a, vec3 b, float r) 
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sdCutSphere( vec3 p, float r, float h )
{
  // sampling independent computations (only depend on shape)
  float w = sqrt(r*r-h*h);

  // sampling dependant computations
  vec2 q = vec2( length(p.xz), p.y );
  float s = max( (h-r)*q.x*q.x+w*w*(h+r-2.0*q.y), h*q.x-w*q.y );
  return (s<0.0) ? length(q)-r :
         (q.x<w) ? h - q.y     :
                   length(q-vec2(w,h));
}

float sdfCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}


float opRound(float primitive, float rad )
{
    return primitive - rad;
}

float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}


float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}


vec3 opElongate(in vec3 p, in vec3 h )
{
    vec3 q = p - clamp( p, -h, h );
    return q;
}

vec4 sdf(vec3 p)
{
    float s = 0.;

    // p = rotate(p, vec3(0.0, 1.0, 0.0), -PI / 2.);

    // vec3 capsuleBody_a = vec3(0.0, 1.1, 0.2);
    // vec3 capsuleBody_b = vec3(0.0, 2.0, 0.2);
    // // vec3 capsuleBodyP = opElongate(p, vec3(1.0, 1.0, 0.0));
    // float chest = sdfCapsule(p, capsuleBody_a , capsuleBody_b, 1.2);

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

    

    // s = sdfUnion(modifiedSphere, s);

    vec3 color = vec3(0.0, 0.0, 0.0);
    if (s == body) color.x = 1.0;
    else if (s == visor) color = vec3(0.38, 0.84, 1.0);
    // else if (s == modifiedSphere) color.y = 1.0;

    
    
    // vec3 color = vec3(0.0, 0.0, 0.0);
    // if (s == s) color.x = 1.0;
    
    //// your implementation ends
    return vec4(color, s);
}








/////////////////////////////////////////////////////
//// ray marching
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 4: ray marching
//// You are asked to implement the ray marching algorithm within the following for-loop.
/////////////////////////////////////////////////////

//// ray marching: origin - ray origin; dir - ray direction 
float rayMarching(vec3 origin, vec3 dir)
{
    float s = 0.0;
    float t = 0.0;
    float epsilon = 0.01;
    float max_distance = 1000.0;
    for(int i = 0; i < 100; i++)
    {
        //// your implementation starts
        vec3 point = origin + dir * t;
        s = sdf(point).w;
        t += s;
        if (s < epsilon || t > max_distance) {
            break;
        }
        //// your implementation ends
    }
    
    return t;
}

/////////////////////////////////////////////////////
//// normal calculation
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 5: normal calculation
//// You are asked to calculate the sdf normal based on finite difference.
/////////////////////////////////////////////////////

//// normal: p - query point
vec3 normal(vec3 p)
{
    float s = sdf(p).w;          //// sdf value in p
    float dx = 0.01;           //// step size for finite difference

    //// your implementation starts
    float x = sdf(p + vec3(dx, 0, 0)).w - sdf(p - vec3(dx, 0, 0)).w;
    float y = sdf(p + vec3(0, dx, 0)).w - sdf(p - vec3(0, dx, 0)).w;
    float z = sdf(p + vec3(0, 0, dx)).w - sdf(p - vec3(0, 0, dx)).w;
    return normalize(vec3(x, y, z));
    //// your implementation ends
}

/////////////////////////////////////////////////////
//// Phong shading
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 6: lighting and coloring
//// You are asked to specify the color for each object in the scene.
//// Each object must have a separate color without mixing.
//// Notice that we have implemented the default Phong shading model for you.
/////////////////////////////////////////////////////

vec3 phong_shading(vec3 p, vec3 n)
{
    //// background
    if(p.z > 10.0){
        return vec3(0.9, 0.6, 0.2);
    }

    //// phong shading
    vec3 lightPos = vec3(4.*sin(iTime) + 4., 4., 4.*cos(iTime));  
    vec3 l = normalize(lightPos - p);               
    float amb = 0.1;
    float dif = max(dot(n, l), 0.) * 0.7;
    vec3 eye = CAM_POS;
    float spec = pow(max(dot(reflect(-l, n), normalize(eye - p)), 0.0), 128.0) * 0.9;

    vec3 sunDir = vec3(0, 1, -1);
    float sunDif = max(dot(n, sunDir), 0.) * 0.2;

    //// shadow
    float s = rayMarching(p + n * 0.02, l);
    if(s < length(lightPos - p)) dif *= .2;

    vec3 color = vec3(1.0, 1.0, 1.0);

    //// your implementation for coloring starts

    color = sdf(p).xyz;

    //// your implementation for coloring ends

    return (amb + dif + spec + sunDif) * color;
}

/////////////////////////////////////////////////////
//// Step 7: creative expression
//// You will create your customized sdf scene with new primitives and CSG operations in the sdf2 function.
//// Call sdf2 in your ray marching function to render your customized scene.
/////////////////////////////////////////////////////

// Moved this function up


/////////////////////////////////////////////////////
//// main function
/////////////////////////////////////////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy - .5 * iResolution.xy) / iResolution.y;         //// screen uv
    vec3 origin = CAM_POS + vec3(0.0, 0.0, -5.0);                                                  //// camera position 
    vec3 dir = normalize(vec3(uv.x, uv.y, 1));                 //// camera direction
    float s = rayMarching(origin, dir);                         //// ray marching
    vec3 p = origin + dir * s;                                              //// ray-sdf intersection
    vec3 n = normal(p);                                                   //// sdf normal
    vec3 color = phong_shading(p, n);                                   //// phong shading
    fragColor = vec4(color, 1.);                                       //// fragment color
}

void main() 
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}