# SQL Injection Defender - Minijuego de Seguridad SQL

## 📋 Descripción

SQL Injection Defender es un minijuego educativo donde el jugador actúa como firewall de base de datos, identificando y bloqueando intentos de inyección SQL antes de que lleguen a la base de datos.

## 🎯 Objetivo

Analizar consultas SQL con inputs de usuarios y determinar si son **consultas legítimas** o **ataques de inyección SQL**.

## 🎮 Mecánicas del Juego

### Información Mostrada

Para cada consulta verás:
- **Consulta SQL Base**: La plantilla SQL del sistema
- **Input del Usuario**: Lo que el usuario envió
- **SQL Resultante**: La consulta final que se ejecutaría

### Controles

- **✅ Consulta Segura**: Permite la consulta (input legítimo)
- **🚨 SQL Injection**: Bloquea la consulta (ataque detectado)
- **💡 Pista**: Muestra ayuda sobre la consulta actual

### Sistema de Puntuación

- ✅ **Decisión correcta**: +150 puntos
- ✅ **Sin usar pistas**: +75 puntos bonus
- ❌ **Decisión incorrecta**: -1 vida
- 🎯 **Vidas totales**: 3
- 📊 **Consultas totales**: 15

### Dificultad Única

Este minijuego **NO tiene niveles de dificultad** - todas las consultas están mezcladas en un solo desafío progresivo que incluye desde ataques básicos hasta técnicas avanzadas.

## 🛡️ Tipos de Ataques SQL Incluidos

### 1. **SQL Injection Básico (OR bypass)**
```sql
Input: admin' OR '1'='1
Peligro: Devuelve TODOS los usuarios
```

### 2. **UNION-based SQL Injection**
```sql
Input: 1 UNION SELECT username, password FROM users
Peligro: Roba datos de otras tablas
```

### 3. **SQL Injection con DROP TABLE**
```sql
Input: admin'; DROP TABLE users; --
Peligro: ELIMINA tablas completas
```

### 4. **Comment-based SQL Injection**
```sql
Input: admin' --
Peligro: Omite verificación de contraseña
```

### 5. **Stacked Queries Attack**
```sql
Input: 1; UPDATE users SET role='admin' WHERE username='hacker'
Peligro: Ejecuta múltiples comandos
```

### 6. **Boolean-based Blind SQL Injection**
```sql
Input: admin' AND SUBSTRING(password,1,1)='a
Peligro: Extrae contraseñas carácter por carácter
```

### 7. **Time-based Blind SQL Injection**
```sql
Input: 1 AND SLEEP(10)
Peligro: Confirma vulnerabilidad con retrasos
```

## ✅ Consultas Legítimas Incluidas

- Búsqueda de usuarios por nombre
- Filtrado de productos por categoría
- Consultas por ID numérico
- Búsqueda de artículos con palabras clave
- Operaciones de conteo
- Inserción de logs del sistema
- Limpieza de datos de sesión

## 💡 Señales de Alerta

### Caracteres Sospechosos
- `'` (comillas) - Cierra strings prematuramente
- `;` (punto y coma) - Permite múltiples comandos
- `--` (guiones dobles) - Comentarios SQL
- `OR` - Condiciones siempre verdaderas

### Palabras Clave Peligrosas
- `UNION` - Combina resultados de múltiples queries
- `DROP` - Elimina tablas/bases de datos
- `UPDATE` - Modifica registros
- `SLEEP()` - Ataques de tiempo
- `SUBSTRING()` - Extracción de datos

### Patrones de Ataque
1. Comillas seguidas de operadores SQL
2. Múltiples comandos SQL en un input
3. Funciones SQL en inputs de usuario
4. Comentarios para omitir validaciones

## 📚 Conceptos Educativos

### ¿Qué es SQL Injection?

SQL Injection es una vulnerabilidad de seguridad donde un atacante inserta código SQL malicioso en campos de entrada para:
- Acceder a datos sin autorización
- Modificar o eliminar datos
- Ejecutar comandos administrativos
- Obtener acceso completo al sistema

### ¿Cómo Prevenirlo?

1. **Consultas Parametrizadas**: Usar placeholders en lugar de concatenación
2. **Validación de Entrada**: Filtrar caracteres especiales
3. **Principio de Mínimo Privilegio**: Limitar permisos de BD
4. **Escape de Caracteres**: Sanitizar inputs del usuario
5. **Web Application Firewall (WAF)**: Filtrado de peticiones

## 🎯 Consejos para Jugadores

1. 📝 **Lee la consulta completa**: No solo el input
2. 🔍 **Busca comillas**: Indican intentos de cerrar strings
3. 🧠 **Identifica palabras clave SQL**: UNION, DROP, UPDATE, etc.
4. ⚡ **Punto y coma = Múltiples comandos**: Muy sospechoso
5. 🎯 **Guiones dobles (--) = Comentarios**: Omite validaciones
6. 💡 **Usa pistas cuando dudes**: Mejor aprender que fallar

## 📁 Archivos del Proyecto

### Scripts
- `SQLQueryResource.gd` - Clase que representa una consulta SQL
- `SQLQueryDatabase.gd` - Base de datos de consultas
- `sql_injection_defender.gd` - Lógica principal del juego

### Escenas
- `SQLInjectionDefender.tscn` - Escena principal con UI completa

### Recursos
- `sql_query_database.tres` - 15 consultas (8 seguras, 7 maliciosas)
- `SQLInjectionDefenderApp.tres` - Configuración de la app

## 🎮 Características

- ✅ **15 consultas SQL** variadas
- ✅ **7 tipos diferentes de ataques** SQL
- ✅ **8 consultas legítimas** para balance
- ✅ **Sistema de pistas** educativo
- ✅ **Explicaciones detalladas** después de cada decisión
- ✅ **Preview de SQL** para ver el resultado final
- ✅ **3 vidas** para margen de error
- ✅ **Temporizador** de 10 minutos
- ✅ **Sistema de puntos** con bonus

## 🚀 Integración

El minijuego está integrado como **aplicación de pistas** en el escritorio del juego, accesible mediante un icono dedicado junto a Network Defender y Password Cracker.

## 🎓 Valor Educativo

Este minijuego enseña:
- **Identificación de ataques SQL** comunes
- **Sintaxis SQL** básica y avanzada
- **Patrones de vulnerabilidad** web
- **Pensamiento crítico** en ciberseguridad
- **Análisis de código** malicioso
- **Mejores prácticas** de seguridad SQL

¡Perfecto para aprender sobre una de las vulnerabilidades web más críticas! 🛡️💻
