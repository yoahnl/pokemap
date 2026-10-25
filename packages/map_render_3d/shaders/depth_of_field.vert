#version 460 core

in vec2 vertexPosition;
out vec2 textureCoordinate;

void main() {
    gl_Position = vec4(vertexPosition, 0.0, 1.0);
    textureCoordinate = vec2(vertexPosition.x * 0.5 + 0.5, 0.5 - vertexPosition.y * 0.5);
}
