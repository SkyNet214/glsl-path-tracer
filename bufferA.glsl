#define PI 3.1415926535
#define MAX_ITERATIONS 10
#define MAX_SAMPLES 1


struct Ray {
    vec3 origin;
    vec3 dir;
};

struct Material {
    vec3 color;
    float emission_strength;
    float roughness;
    bool glas;
};

struct Sphere {
    vec3 center;
    float radius;
    Material mat;
    
};

struct Plane {
    vec3 center;
    vec3 normal;
    Material mat;
};

struct Triangle {
    vec3 v0, v1, v2; // vertices
    Material material;
    vec3 normal; // optional, for smooth shading
};


struct Hit {
    vec3 point;
    vec3 normal;
    float t;
    Material mat;
    bool inside;
};



float atan2(float y, float x) {
 	float absx, absy, val;
 
     if (x == 0.0 && y == 0.0) {
 		return 0.0;
 	}
 	absy = y < 0.0 ? -y : y;
 	absx = x < 0.0 ? -x : x;
 	if (absy - absx == absy) {
 		return y < 0.0 ? -3.1415*2.0 : 3.1415*2.0;
 	}
    
    if (absx - absy == absx) {
		val = 0.0;
    } else {
        val = asin((y/x)/sqrt(1.0+((y/x)*(y/x))));
    }
 	if (x > 0.0) {
 		return val;
 	}
 	if (y < 0.0) {
		return val - 3.1415;
 	}
 	return val + 3.1415;
}

vec3 lerp(vec3 a, vec3 b, float n) {
    return (b - a) * n + a;
}

vec3 skybox(vec3 N) {
    float u = 1.0-atan(N.z, N.x) / (2.0*PI);
	float v = 1.0-(atan(length(N.xz), N.y)) / PI;
    return texture(iChannel1, vec2(u + 0.1*iTime, v)).rgb;
}

// random number generator
uint NextRandom(inout uint state)
{
	state = state * 747796405u + 2891336453u;
	uint result = ((state >> ((state >> 28) + 4u)) ^ state) * 277803737u;
	result = (result >> 22) ^ result;
	return result;
}

float RandomValue(inout uint state)
{
	return float(NextRandom(state)) / 4294967295.0; // 2^32 - 1
}

// Random value in normal distribution (with mean=0 and sd=1)
float RandomValueNormalDistribution(inout uint state)
{
	// Thanks to https://stackoverflow.com/a/6178290
	float theta = 2.0 * 3.1415926 * RandomValue(state);
	float rho = sqrt(-2.0 * log(RandomValue(state)));
	return rho * cos(theta);
}

// Calculate a random direction
vec3 RandomDirection(inout uint state)
{
	// Thanks to https://math.stackexchange.com/a/1585996
	float x = RandomValueNormalDistribution(state);
	float y = RandomValueNormalDistribution(state);
	float z = RandomValueNormalDistribution(state);
	return normalize(vec3(x, y, z));
}


Hit hit_sphere(Ray r, Sphere s) {
    float a = dot(r.dir, (r.origin - s.center));
    float b = length(r.origin - s.center);
    float c = s.radius;
    float d = a*a - (b*b - c*c);
    
    Hit h;
    if (d < 0.0) {
        h.t = -1.0;
    } else if (d == 0.0) {
        h.t = -a;
        h.point = r.origin + r.dir * h.t;
        vec3 outside_normal = normalize(h.point - s.center);
        h.inside = dot(outside_normal, r.dir) < 0.0;
        h.normal = h.inside ? outside_normal : -outside_normal;
        h.mat = s.mat;

    } else {
        h.t = -a - sqrt(d);
        h.point = r.origin + r.dir * h.t;
        vec3 outside_normal = normalize(h.point - s.center);
        h.inside = dot(outside_normal, r.dir) < 0.0;
        h.normal = h.inside ? outside_normal : -outside_normal;
        h.mat = s.mat;
    }
    return h;
}

Hit hit_plane(Ray r, Plane p) {
    Hit h;
    h.t = -1.0;
    h.normal = -p.normal;
    h.inside = false;
    h.mat = p.mat;
    float scalar = dot(p.normal, r.dir);
    if (scalar > 1e-6) {
        h.t = dot(p.center - r.origin, p.normal) / scalar;
    }
    h.point = r.origin + r.dir * h.t;
    return h;
}

Sphere scene[] = Sphere[2](
    Sphere(vec3(0.0, 3.9, 0.0), 1.0, Material(vec3(1.000,1.000,1.000), 1.0, 0.0, false)),
    Sphere(vec3(0.0, -1.5, 0.0), 1.0, Material(vec3(1.000,1.000,1.000), 0.0, 0.0, false))
);



const vec3 WHITE = vec3(0.89);
Plane walls[] = Plane[6](
    Plane(vec3(0.0, -3.0, 0.0), vec3(0.0, -1.0, 0.0), Material(vec3(0.153,0.282,0.808), 0.0, 1.0, false)), // bottom
    Plane(vec3(0.0, 3.0, 0.0), vec3(0.0, 1.0, 0.0), Material(WHITE, 0.0, 1.0, false)), // top
    Plane(vec3(3.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), Material(vec3(0.325,0.804,0.196), 0.0, 0.0, false)), // right
    Plane(vec3(-3.0, 0.0, 0.0), vec3(-1.0, 0.0, 0.0), Material(vec3(0.859,0.239,0.239), 0.0, 0.0, false)), // left
    Plane(vec3(0.0, 0.0, 3.0), vec3(0.0, 0.0, 1.0), Material(WHITE, 0.0, 1.0, false)),  // back
    Plane(vec3(0.0, 0.0, -3.0), vec3(0.0, 0.0, -1.0), Material(WHITE, 0.0, 1.0, false)) // front 
);



vec3 ray_color(Ray ray, uint rngState) {
    Ray r = ray;
    vec3 raylight = vec3(0.0, 0.0, 0.0);
    vec3 raycol = vec3(1.0, 1.0, 1.0);
    for (int iteration = 0; iteration < MAX_ITERATIONS; iteration++) {
        Hit closest;
        closest.t = -1.0;
        for (int i = 0; i < scene.length(); i++) {
            Sphere s = scene[i];
            Hit h = hit_sphere(r, s);
            if (closest.t < 0.0 || h.t >= 0.0 && h.t < closest.t) {
                closest = h;
            }
        }
        for (int i = 0; i < walls.length(); i++) {
            Plane p = walls[i];
            Hit h = hit_plane(r, p);
            if (closest.t < 0.0 || h.t >= 0.001 && h.t < closest.t) {
                closest = h;
            }
        }
        
        if (closest.t >= 0.0) {
            vec3 emitted_light = closest.mat.color * closest.mat.emission_strength;
            raylight += emitted_light * raycol;
            raycol *= closest.mat.color; //* (closest.normal + 1.0);
            vec3 diffDir = RandomDirection(rngState) + closest.normal;
            vec3 specDir = reflect(r.dir, closest.normal);
            vec3 newdir = lerp(specDir, diffDir, closest.mat.roughness);

            if (closest.mat.glas) {
                float eta = !closest.inside ? 1.5 / 1.0 : 1.0 / 1.5; 
                float cos_theta = min(dot(-r.dir, closest.normal), 2.0);
                float sin_theta = sqrt(1.0 - cos_theta*cos_theta);

                bool cannot_refract = eta * sin_theta > 1.0;
                if (cannot_refract) {
                    newdir = reflect(r.dir, closest.normal);
                } else {
                    newdir = refract(r.dir, closest.normal, eta);
                }
            }
            
            r = Ray(closest.point, newdir);
        } else {
            
            
            float a = 0.5*(r.dir.y + 1.0);
            vec3 skycol = (1.0-a)*vec3(1.0, 1.0, 1.0) + a*vec3(0.486,0.796,0.953);
            //vec3 skycol = skybox(r.dir).rgb;
            float skylight = 0.5;
            raylight += skycol * 0.7 * raycol;
            raycol *= skycol;
            break;
        }
    }
    return raylight;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 cam = vec3(0.0, 0.0, -8.0);
    float vp_h = 2.0;
    float vp_w = vp_h * iResolution.x / iResolution.y;
    float vp_fl = 1.0;
    vec3 ulc = cam + vec3(0.0, 0.0, vp_fl) - vec3(0.0, vp_h / 2.0, 0.0) - vec3(vp_w / 2.0, 0.0, 0.0);
    vec2 uv = fragCoord / iResolution.xy + 0.5;
    uv.x *= iResolution.x / iResolution.y;
    vec2 numPixels = iResolution.xy;
    vec2 pixelCoord = uv*numPixels;
    uint pixelIndex = uint(pixelCoord.y * numPixels.x + pixelCoord.x);
    uint rngState = pixelIndex + uint(iFrame * 719393);
    
    // scene[1].center.y = 1.5*sin(iTime);
    /*
    float radius = 10.0;
    scene[0].center.x += radius * sin(iTime);
    // scene[0].center.y += 4.0 * sin(2.0*iTime);
    scene[0].center.z += radius * cos(iTime);
    scene[1].center.x += radius * sin(iTime + PI);
    // scene[1].center.y += 4.0 * sin(2.0*(iTime + 3.0*PI/4.0));
    scene[1].center.z += radius * cos(iTime + PI);*/
    Ray r;
    r.origin = cam;
    r.dir = normalize((ulc + vec3(uv.xy, 0.0)) - cam);
    vec3 pxl_col = vec3(0.0, 0.0, 0.0);
    for (int s = 0; s < MAX_SAMPLES; s++) {
        r.dir = normalize((ulc + vec3(uv.xy, 0.0) + 0.2 * vec3(vp_w / iResolution.x * RandomValueNormalDistribution(rngState), vp_h / iResolution.y * RandomValueNormalDistribution(rngState),0.0)) - cam);
        pxl_col += ray_color(r, rngState);
    }
    vec3 currCol = vec3(pxl_col / float(MAX_SAMPLES));
    vec4 prevCol = texelFetch(iChannel0, ivec2(fragCoord - 0.5), 0);
    if (prevCol.a < 10000.0) {
        prevCol += vec4(currCol, 1.0);
    }
    fragColor = prevCol;
    /*
    vec3 prevAvg = textureLod(iChannel0, uv, 0.0f).rgb;
    vec3 currCol = vec3(pxl_col / float(MAX_SAMPLES));
    fragColor = vec4( (prevAvg.rgb * float(iFrame) + currCol) / float(iFrame + 1), 1.0);
    */
    /*
    float weight = 1.0 / float(iFrame + 1);
	vec4 accumulatedCol = prevCol * (1.0 - weight) + currCol * weight;	
	fragColor = accumulatedCol;
    fragColor = currCol;*/
    
}
