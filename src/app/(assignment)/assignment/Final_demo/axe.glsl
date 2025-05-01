precision highp float;              //// set default precision of float variables to high precision

varying vec2 vUv;                   //// screen uv coordinates (varying, from vertex shader)
uniform vec2 iResolution;           //// screen resolution (uniform, from CPU)
uniform float iTime;                //// time elapsed (uniform, from CPU)

const vec3 CAM_POS = vec3(-0.35, 1.0, -3.0);
#define PI 3.1415925359


struct Snow {
    vec3 defaultPos;
    float xOffset;
};

bool has_initialized = false;
const int NUM_PARTICLES = 50;
Snow snowParticles[NUM_PARTICLES];

/////////////////////////////////////////////////////
//// sdf functions
/////////////////////////////////////////////////////

//// sphere: p - query point; c - sphere center; r - sphere radius
float sdfSphere(vec3 p, vec3 c, float r)
{
    //// your implementation starts
    
    return length(p - c) - r;
    
    //// your implementation ends
}

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

vec3 rotate(vec3 p, vec3 ax, float ro)
{
    return mix(dot(p, ax) * ax, p, cos(ro)) + sin(ro) * cross(ax, p);
}


float sdfCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 opElongate(in vec3 p, in vec3 h )
{
    vec3 q = p - clamp( p, -h, h );
    return q;
}


float opRound(float p, float rad )
{
    return p - rad;
}

float sdEllipsoid( vec3 p, vec3 r )
{
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}


float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

vec4 sdfAmongus(vec3 p) 
{
    float s = 0.;

    float circle = sdfSphere(p, vec3(0.18,2.1, 0.0), 0.8);
    float circle2 = sdfSphere(p, vec3(-0.18,2.1, 0.0), 0.8);
    circle = opSmoothUnion(circle, circle2, 0.1);

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

vec4 sdfSnowfall(vec3 p) 
{
    float s = 0.;
    vec3 particlePos = snowParticles[0].defaultPos + mod(iTime, 2.) * vec3(2.0, -4., 0.);

    
    // s = sdfSphere(p, snowParticles[0].pos + iTime * vec3(0.0, -4., 0.), 0.1);
    s = sdfSphere(p, particlePos, 0.01);

    for (int i = 1; i < NUM_PARTICLES; i++) {

        // We could calculate two different forces here perhaps? One for gravity, and another for some wind blowing. 
        // Add some noise to the movement to make it more appealing, and r eset after a certain amount of time.
        // particlePos = snowParticles[i].pos + mod(iTime, 4.) * vec3(cos(float(i)) * 2., sin(float(i)) * -4., 0.);
        
        particlePos = snowParticles[i].defaultPos + mod(iTime, 4.) * vec3(sin(0.5 * iTime + snowParticles[i].xOffset), -2., 0.);
        s = sdfUnion(s, sdfSphere(p, particlePos, .01));   
    }

    // for (int i = 0; i < 10; i++) {
    //     particlesPos = snowParticles[i]
    // }

    vec3 color = vec3(1.0, 1.0, 1.0);
    return vec4(color, s);
}

float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

float udQuad( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d )
{
  vec3 ba = b - a; vec3 pa = p - a;
  vec3 cb = c - b; vec3 pb = p - b;
  vec3 dc = d - c; vec3 pc = p - c;
  vec3 ad = a - d; vec3 pd = p - d;
  vec3 nor = cross( ba, ad );

  return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(dc,nor),pc)) +
     sign(dot(cross(ad,nor),pd))<3.0)
     ?
     min( min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(dc*clamp(dot(dc,pc)/dot2(dc),0.0,1.0)-pc) ),
     dot2(ad*clamp(dot(ad,pd)/dot2(ad),0.0,1.0)-pd) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}

vec4 sdfAxe(vec3 p) 
{
    float s = 0.;
    vec3 color = vec3(1., 1., 1.);

    float axeBody = sdfCylinder(p, 1.5, .1);
    float axeHead1 = sdfBox(rotate(p - vec3(1., 0.8, 0.), vec3(0.0, 0., 1.), PI / 4.), vec3(0., 0., 0.), vec3(.6, .6, 0.2));
    float axeHead2 = sdfBox(p, vec3(.6, 0.8, 0.), vec3(.75, .5, 0.2));
    float axeHead = sdfUnion(axeHead1, axeHead2);

    s = sdfUnion(axeBody, axeHead);

    if (s == axeHead) color = vec3(0.47, 0.45, 0.45);
    else if (s == axeBody) color = vec3(0.61, 0.31, 0.0);
    return vec4(color, s);
}

vec4 sdf(vec3 p)
{
    float s = 0.;
    vec3 color = vec3(0.0, 0.0, 0.0);

    // vec4 AmongUs = sdfAmongus(p);
    // s = AmongUs.w;
    // // color = AmongUs.xyz;

    // vec4 snowfall = sdfSnowfall(p);
    // // color = snowfall.xyz;
    // s = sdfUnion(snowfall.w, s);

    // if (s == snowfall.w) color = snowfall.xyz;
    // else if (s == AmongUs.w) color = AmongUs.xyz;

    vec4 axe = sdfAxe(p);

    s = axe.w;

    if (s == axe.w) color = axe.xyz;

    return vec4(color, s);
}

/////////////////////////////////////////////////////
//// ray marching
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

void initialize() {
    // snowParticles[0].pos = vec3(0., 0., 0.);
    float xOffset = -5.; 
    for (int i = 0; i < NUM_PARTICLES; i++) {
        snowParticles[i].defaultPos = vec3(xOffset, 5. - sin(float(i)), 0.);
        snowParticles[i].xOffset = 2. * sin(float(i));
        xOffset += 0.2;
    }
    has_initialized = true;
}

/////////////////////////////////////////////////////
//// main function
/////////////////////////////////////////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    if (!has_initialized) initialize();
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