// Configuración de Google Sign-In
// 1. En Firebase Console > Authentication > Sign-in method > Google > activar
// 2. Copiar el "Web client ID" (formato: xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com)
// 3. Pegar aquí reemplazando el valor de abajo.

const String googleWebClientId = '236819672209-vb868hs4iksee9vt8jae96gl3bd9ibg0.apps.googleusercontent.com';

// Para Android: En Firebase Console > Configuración del proyecto > Tu app Android
// Añade la SHA-1 del keystore de debug:
// keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android