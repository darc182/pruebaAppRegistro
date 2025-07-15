# Registro de Visitantes - Flutter + Supabase

**Autor:** Darwin Cachimil

## Descripción
Esta aplicación permite registrar y gestionar visitantes en una oficina de manera moderna y eficiente. Desarrollada en Flutter y usando Supabase como backend, es compatible tanto para web como para dispositivos móviles.

## Funcionalidades principales
- **Autenticación:** Registro e inicio de sesión con correo y contraseña usando Supabase Auth.
- **Lista de visitantes:** Visualización en tiempo real de los visitantes registrados (nombre, motivo, hora y foto).
- **Agregar visitante:** Formulario validado para registrar nombre, motivo, hora (con selector) y foto (cámara o galería).
- **Almacenamiento seguro:** Fotos almacenadas en Supabase Storage y datos en la base de datos.
- **Interfaz atractiva:** Diseño moderno, responsivo y fácil de usar.
- **Cierre de sesión:** Botón de logout accesible en la barra superior.

## Instalación y ejecución
1. Clona el repositorio y navega a la carpeta del proyecto.
2. Ejecuta `flutter pub get` para instalar dependencias.
3. Configura tus credenciales de Supabase en `lib/app.dart` si es necesario.
4. Ejecuta en web o móvil:
   - Web: `flutter run -d chrome`
   - Android/iOS: `flutter run`

## Notas
- El sistema de permisos y almacenamiento está configurado para seguridad y facilidad de uso.
- El diseño y la experiencia de usuario han sido optimizados para ser intuitivos y agradables.

---

¡Desarrollado por Darwin Cachimil!
