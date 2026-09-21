# Guía de Configuración de Google Play Console — Tienda Gamez

> App: **Tienda Gamez** (`com.gamez.tiendagamez`) · versión `1.0.0+1` · Flutter
> Fecha: septiembre 2026

---

## 0. Estado de la app (ya resuelto en código)

| Requisito de Play | Estado |
|---|---|
| Firma release con keystore (`key.properties`) | ✅ Configurado en `android/app/build.gradle.kts` |
| Minify + Shrink + ProGuard en release | ✅ |
| Permisos mínimos (INTERNET, POST_NOTIFICATIONS, CAMERA, RECEIVE_BOOT_COMPLETED, WAKE_LOCK) | ✅ Declaración en el manifest |
| Política de privacidad pública | ✅ `privacy-policy/index.html` (publícala en GitHub Pages) |
| **Eliminación de cuenta desde la app** | ✅ Botón **"Eliminar cuenta y datos"** en Configuración → Google Drive y Respaldo (borra respaldos de Drive, cierra sesión y vacía la base de datos local) |
| Página web de eliminación de cuenta | ✅ `privacy-policy/delete-account.html` (publícala y usa esa URL en Play Console) |

**Pendiente antes de compilar la release final:**
1. Crear el archivo `android/key.properties` (NO subir a Git) con tu keystore:
   ```properties
   storePassword=<contraseña del keystore>
   keyPassword=<contraseña de la llave>
   keyAlias=<alias>
   storeFile=<ruta absoluta del .jks>
   ```
2. En **Google Cloud Console → Credenciales**, crear un **ID de cliente OAuth (Android)** con el nombre de paquete `com.gamez.tiendagamez` y la **huella SHA-1 de tu keystore release** (obténla con `keytool -list -v -keystore tu-keystore.jks`). Sin esto, Google Sign-In fallará en la app de Play Store.
3. Compilar: `flutter build appbundle --release` → sube `build/app/outputs/bundle/release/app-release.aab`.

---

## 1. Seguridad de los datos (sección obligatoria)

Exporta/importa respuestas con el CSV, pero contesta así en la consola:

### Preguntas generales
| Pregunta | Respuesta |
|---|---|
| ¿Tu app recopila o comparte alguno de los tipos de datos requeridos? | **Sí** |
| ¿Todos los datos recopilados se encriptan en tránsito? | **Sí** (todo va por HTTPS a Google) |
| ¿Ofreces un mecanismo para solicitar eliminación de datos? | **Sí** |

### Métodos de creación de cuenta
- ✅ **OAuth** (inicio de sesión con Google)
- ❌ Usuario/contraseña · ❌ Otra autenticación · ❌ Ninguno
- Campo de texto (describe el método): *"Inicio de sesión único con cuenta de Google (OAuth 2.0) mediante Google Sign-In. La cuenta se usa únicamente para guardar respaldos en el Google Drive del propio usuario. La app es totalmente funcional sin iniciar sesión."*

### URL de eliminación
- **URL de eliminación de datos y de cuenta:** `https://TU-USUARIO.github.io/TU-REPO/delete-account.html`
  (publica `privacy-policy/` en GitHub Pages; la página ya existe en el repositorio)
- ¿Pones a disposición un método para borrar datos? → **Sí** (botón dentro de la app + correo de soporte)

### Tipos de datos declarados (los únicos que aplican)

**1) Información personal → Dirección de correo electrónico**
| Pregunta | Respuesta |
|---|---|
| ¿Recopilada, compartida o ambas? | **Recopilada** (transitoria, no sale del dispositivo hacia tus servidores; se usa con Google) |
| ¿Procesada de forma efímera? | Sí (opcional; si la consola lo exige, marca "Sí") |
| ¿Opcional o requerida? | **Opcional — los usuarios pueden decidir si se recopila** (el login es voluntario) |
| ¿Por qué se recopila? | **Funciones de la app** (respaldo en Drive) |
| ¿Para qué se usa/comparte? | **Funciones de la app** |

**2) Información personal → Nombre**
Mismas respuestas que el correo: Recopilada · Efímera (si aplica) · Opcional · Funciones de la app.
*(El perfil de Google entrega nombre y correo; si prefieres simplificar, puedes declarar solo el correo y no marcar "Nombre", siempre que no lo uses. Decidir y mantener coherencia con la política de privacidad.)*

**3) Información financiera → Historial de compras** — **NO declarar**: la app tiene la dependencia `in_app_purchase` pero no hay compras implementadas. Si más adelante activas compras, declara "Historial de compras · Recopilada · Funciones de la app" (Google gestiona el pago y no comparte datos financieros contigo).

**Todos los demás tipos de datos:** **No recopilados** (ubicación, salud, contactos, fotos, mensajes, registros de fallas, diagnósticos, IDs de dispositivo, etc.). La app no usa analíticas ni crashlytics.

### Preguntas opcionales
| Pregunta | Respuesta |
|---|---|
| Revisión independiente (MASA) | No |
| ¿Cuentas creadas fuera de la app? | No |
| Cumple Política de Familias | No aplica (no está dirigida a niños) |

---

## 2. Política de privacidad

- **URL:** `https://TU-USUARIO.github.io/TU-REPO/` (la raíz redirige a la política)
- Ya menciona Google Sign-In, Drive, almacenamiento local, eliminación y contacto: **cumple los requisitos**.

## 3. Eliminación de cuenta (política obligatoria por usar login)

Google exige **ambos** caminos y ya están implementados:
1. **En la app:** Configuración → Google Drive y Respaldo → **"Eliminar cuenta y datos"** (confirma con diálogo; borra backups de Drive + datos locales + sesión).
2. **En la web:** `…/delete-account.html` — proceso por correo a `soporte@tiendagamez.com`, máximo 7 días.

Pega esa URL en **Seguridad de datos → Gestión de datos → Eliminación de cuenta**.

## 4. Resto de formularios de Play Console

| Sección | Respuesta |
|---|---|
| **Acceso a la app** | "Todas las funciones están disponibles sin restricciones" + nota: *"El inicio de sesión con Google es opcional y solo habilita respaldos; no se requiere credencial para revisar la app."* |
| **Anuncios** | Sin anuncios |
| **Contenido → Calificación** | Cuestionario IARC: respuestas normales (sin violencia, sin apuestas) → resultado esperado "Para todos" |
| **Público objetivo** | 13+ (NO incluir menores de 13 → evita el programa Diseñado para Familias y requisitos adicionales) |
| **Ficha de Play Store** | Descripción, capturas (mín. 2 en teléfono), ícono 512×512, gráfico de funciones 1024×500 |
| **Datos de contacto** | Correo: `soporte@tiendagamez.com` |
| **Clasificación de contenido / Gobierno** | Completar cuestionario estándar |

## 5. Publicación recomendada

1. Sube el `.aab` a **Producción** (o mejor: primero a **Pruebas internas/cerradas** para validar el login de Google con la firma release).
2. Activa **Play App Signing** (lo ofrece Google por defecto al subir el primer AAB) — agrega también el **SHA-1 del certificado de firma de Play** como segundo cliente OAuth en Google Cloud.
3. Completa las declaraciones y envía a revisión.

---

## Resumen de respuestas rápidas (Seguridad de datos)

```
Recopila datos:                    SÍ
Encriptación en tránsito:          SÍ
Método de cuenta:                  OAuth
URL eliminación cuenta:            https://TU-USUARIO.github.io/TU-REPO/delete-account.html
Correo electrónico:                Recopilada · Opcional · Efímera · Funciones de la app
Nombre:                            Recopilada · Opcional · Efímera · Funciones de la app
Historial de compras:              NO (no hay IAP activa)
Todo lo demás:                     NO
Cuentas fuera de la app:           NO
```
