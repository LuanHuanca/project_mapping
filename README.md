# 🎬 Project Mapping Studio

> **By: Luan**  
> *Sistema de Video Mapping Profesional de Alto Rendimiento para Windows (Motor Nativo OpenGL C++ a 60 FPS + Interfaz Flutter Desktop + Calibración Asistida con IA)*

---

## 📌 Descripción General

**Project Mapping Studio** es una plataforma integral de **Video Mapping y Calibración Geométrica** desarrollada para Windows. Combina la flexibilidad de una interfaz moderna en Flutter con la potencia de un motor gráfico nativo escrito en **C++ con OpenGL 3.3 Core Profile** capaz de renderizar shaders generativos a **60 FPS continuos** directamente sobre la tarjeta de video (GPU dedicada NVIDIA / AMD).

---

## 🏗️ Arquitectura del Proyecto (Monorepo)

```
project_mapping/
├── apps/
│   └── mapper_desktop/       # Aplicación principal Flutter Windows (UI/UX, Editor de Escenas)
├── packages/
│   ├── mapper_core/          # Modelos matemáticos (Homografía 3x3, Escenas, Polígonos, Formas)
│   ├── mapper_vision/        # Detección de superficies física por gradiente de luminancia Sobel (100% On-Device)
│   ├── mapper_render/        # Wrapper FFI y bindings en Dart para la DLL nativa C++
│   └── mapper_aws_api/       # Cliente API opcional para análisis con Rekognition en la nube
├── native/
│   ├── native_renderer.h     # C ABI exportado
│   ├── CMakeLists.txt        # Configuración de compilación CMake MSVC
│   └── src/                  # Motor C++ (GLAD, ScopedGLContext, Shaders GLSL embebidos)
└── infra/                    # Infraestructura Serverless AWS CDK (Opcional)
```

---

## 💻 Requisitos del Sistema (Cualquier PC con Windows)

Para ejecutar este proyecto en otra computadora con Windows, se requieren los siguientes programas e instaladores básicos:

1. **Sistema Operativo**: Windows 10 o Windows 11 (64-bit).
2. **Git**: [Git for Windows](https://git-scm.com/download/win).
3. **Flutter SDK**: 3.19+ ([Instalar Flutter](https://docs.flutter.dev/get-started/install/windows/desktop)).  
   *Asegúrate de habilitar el soporte de escritorio: `flutter config --enable-windows-desktop`*
4. **Visual Studio 2022**: Carga de trabajo **"Desarrollo para el escritorio con C++"** (incluye compilador MSVC y CMake).
5. **Tarjeta de Video (GPU)**: Gráfica con soporte para **OpenGL 3.3 Core Profile** (disponible en GPUs Intel HD Graphics 4000+, NVIDIA GeForce o AMD Radeon).

---

## 🚀 Guía Completa de Instalación y Ejecución Paso a Paso

Sigue esta guía secuencial para instalar y ejecutar el proyecto desde cero en cualquier computadora:

### 1️⃣ Clonar el Repositorio

Abre la terminal de PowerShell o CMD:

```powershell
git clone https://github.com/TU_USUARIO/Project_mapping.git
cd Project_mapping
```

---

### 2️⃣ Compilar la Librería Nativa C++ (`native_renderer.dll`)

Este paso genera la DLL del motor gráfico nativo OpenGL:

```powershell
# Crear carpeta de build
mkdir native/build
cd native/build

# Generar archivos de solución con CMake (MSVC 2022)
cmake ..

# Compilar la DLL en modo Release
cmake --build . --config Release

# Regresar a la raíz del proyecto
cd ../..
```

*Se creará el archivo `native/build/Release/native_renderer.dll`.*

---

### 3️⃣ Probar el Diagnóstico de GPU (Opcional)

Puedes verificar si tu tarjeta gráfica integrada/dedicada inicializa OpenGL correctamente ejecutando la app nativa standalone:

```powershell
./native/build/Release/native_test.exe
```

---

### 4️⃣ Instalar Dependencias en Flutter

Ingresa a la aplicación desktop e instala los paquetes:

```powershell
cd apps/mapper_desktop
flutter pub get
```

---

### 5️⃣ Lanzar la Aplicación

Ejecuta la aplicación en modo escritorio Windows:

```powershell
flutter run -d windows
```

---

## 🖥️ Guía de Proyección en Pantalla Auxiliar / Proyector (2 Pantallas)

Para realizar una proyección real en un evento o demostración:

1. Conecta el cable **HDMI, DisplayPort o USB-C** del proyector a la laptop.
2. Presiona la combinación de teclas en Windows: **`Win + P`**.
3. Selecciona la opción **"Extender" (Extend)**. *(NUNCA selecciones "Duplicar").*
4. En la barra superior de la app, haz clic en el botón de **"Abrir Ventana de Proyección"** (🎥 icono de videocámara color Ámbar).
5. Aparecerá la **Ventana Flotante de Proyección**:
   - Puedes dejarla a un lado en tu monitor para probar en tiempo real mientras editas.
   - Haz clic en el botón de **Maximizar (🗖)** para enviarla a pantalla completa a tu proyector.

---

## ⚡ Características Clave e Innovaciones

* **Cero Configuración GPU Manual**: Incluye símbolos nativos `NvOptimusEnablement` y `AmdPowerXpressRequestHighPerformance` que obligan a Windows a asignar la GPU dedicada (NVIDIA / AMD) automáticamente.
* **Fallback de Seguridad (Contingencia)**: Si la PC no soporta OpenGL 3.3, la app activa automáticamente un motor de renderizado de reserva en Dart (`CustomPainter`), permitiendo que la app nunca se cierre en pleno evento.
* **Calibración Asistida por IA On-Device (0% Red)**: Algoritmo de gradiente de luminancia Sobel 3x3 que detecta bordes y superficies en tiempo real mediante webcam sin necesitar internet.
* **Shaders Generativos GLSL**: Efectos dinámicos en vivo (`Pulse`, `Grid Wave`, `Outline Tracer`, `Rainbow Wave`, `Strobe`).
* **Edición Side-by-Side**: Edita polígonos, vértices y capas en tu pantalla principal mientras la pantalla secundaria proyecta a 60 FPS.

---

## 🧪 Comandos para Ejecutar las Pruebas Automatizadas (Unit Tests)

```powershell
# 1. Pruebas de FFI y Motor OpenGL Nativo (5/5)
cd packages/mapper_render
dart test

# 2. Pruebas de Calibración e IA por Visión Sobel (7/7)
cd ../mapper_vision
dart test

# 3. Pruebas de Geometría y Homografía Core (3/3)
cd ../mapper_core
dart test
```

---

## 👤 Autor

**By: Luan**  
*Project Mapping Studio — 2026*
