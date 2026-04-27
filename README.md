# GLSL Raytracer

![Raytracer Preview](preview.png)

This project is a local port of a Shadertoy-style path tracer. It uses WebGL 2 to render and accumulate samples across multiple passes.

## Project Structure

- `index.html`: The main entry point. It sets up the WebGL 2 context, manages framebuffers for accumulation (ping-ponging), and handles the rendering loop.
- `bufferA.glsl`: The raytracing and accumulation logic.
- `image.glsl`: Post-processing (ACES tonemapping and gamma correction).
- `GEMINI.md`: Architectural overview and technical details.

## How to Run Locally

Due to browser security restrictions on the `file://` protocol, you must serve these files using a local web server to allow the shaders to be fetched.

### Option 1: Python (Recommended)
If you have Python installed, run this command in the project directory:
```bash
python3 -m http.server
```
Then open [http://localhost:8000](http://localhost:8000) in your browser.

### Option 2: Node.js (serve)
If you have Node.js installed:
```bash
npx serve .
```
Then open the provided URL.
