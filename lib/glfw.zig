const _glfw = @cImport({@cInclude("GLFW/glfw3.h");});

pub const Window = _glfw.GLFWwindow;

pub const init = _glfw.glfwInit;
pub const terminate = _glfw.glfwTerminate;

pub const getProcAddress = _glfw.glfwGetProcAddress;
pub const setFramebufferSizeCallback = _glfw.glfwSetFramebufferSizeCallback;
pub const createWindow = _glfw.glfwCreateWindow;
pub const windowHint = _glfw.glfwWindowHint;
pub const destroyWindow = _glfw.glfwDestroyWindow;
pub const setErrorCallback = _glfw.glfwSetErrorCallback;
pub const windowShouldClose = _glfw.glfwWindowShouldClose;
pub const makeContextCurrent = _glfw.glfwMakeContextCurrent;
pub const setInputMode = _glfw.glfwSetInputMode;
pub const swapBuffers = _glfw.glfwSwapBuffers;

pub const pollEvents = _glfw.glfwPollEvents;

pub const TRUE = _glfw.GLFW_TRUE;
pub const FALSE = _glfw.GLFW_FALSE;
pub const RESIZABLE = _glfw.GLFW_RESIZABLE;
pub const AUTO_ICONIFY = _glfw.GLFW_AUTO_ICONIFY;
pub const SAMPLES = _glfw.GLFW_SAMPLES;
pub const CONTEXT_VERSION_MAJOR = _glfw.GLFW_CONTEXT_VERSION_MAJOR;
pub const CONTEXT_VERSION_MINOR = _glfw.GLFW_CONTEXT_VERSION_MINOR;
pub const DECORATED = _glfw.GLFW_DECORATED;
pub const STICKY_KEYS = _glfw.GLFW_STICKY_KEYS;
