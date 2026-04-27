//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x){
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = fragCoord/iResolution.xy;
    uv /= iResolution.x/iResolution.y;
    
    //Read the RGBA value in iChannel0 that holds the path tracer data from BufferB
    vec4 data = texelFetch(iChannel0, ivec2(fragCoord - 0.5), 0).rgba;
    
    //Set the colour to the accumulated RGB value divided by the number of iterations
    //which is the value of the alpha channel as it gets 1 added to it every frame
    vec3 col = data.rgb/data.a;
       
    //Tonemapping
    col = ACESFilm(col);
    
    //Gamma correction
    col = pow(col, vec3(1.0 / 2.2));
    
    //Output to screen
	fragColor = vec4(col, 1.0);    
}
