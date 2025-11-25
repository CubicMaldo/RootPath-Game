# Port Scanner Defender - Minijuego de Ciberseguridad

## 📋 Descripción

Port Scanner Defender es un minijuego educativo donde el jugador actúa como un **IDS (Sistema de Detección de Intrusiones)**, analizando actividades de red en tiempo real y determinando si son tráfico legítimo o escaneos de puertos maliciosos.

## 🎯 Objetivo

Analizar cada actividad de red completa (IP origen, puerto, protocolo, tipo de scan, volumen) y clasificarla correctamente como **TRÁFICO LEGÍTIMO** o **SCAN MALICIOSO**.

## 🎮 Mecánicas del Juego

### Información Mostrada

Para cada actividad verás:
- **IP Origen**: Dirección IP de donde proviene la actividad
- **Puerto**: Número de puerto objetivo y su servicio
- **Protocolo**: TCP o UDP
- **Tipo**: Tipo de actividad o scan detectado
- **Paquetes**: Cantidad de paquetes enviados
- **Tiempo**: Duración de la actividad
- **Descripción**: Detalles técnicos de la actividad

### Controles

- **✅ Tráfico Legítimo**: Permite la actividad (no es amenaza)
- **🚨 Scan MALICIOSO**: Bloquea la actividad (escaneo detectado)
- **💡 Ver Pista**: Muestra ayuda sobre la actividad actual
- **➡️ Siguiente Actividad**: Continúa al siguiente análisis

### Sistema de Puntuación

- ✅ **Decisión correcta**: +120 puntos
- ✅ **Sin usar pistas**: +60 puntos bonus (total 180)
- ❌ **Decisión incorrecta**: -1 vida
- 🎯 **Vidas totales**: 3
- 🔍 **Actividades totales**: 18
- ⏱️ **Tiempo límite**: 9 minutos

### Dificultad Única

Este minijuego **NO tiene niveles de dificultad** - todas las 18 actividades están mezcladas aleatoriamente, desde tráfico legítimo obvio hasta técnicas de escaneo avanzadas que requieren conocimiento profundo de seguridad de redes.

## 🔍 Tipos de Actividades Incluidas

### ✅ Tráfico Legítimo (9 ejemplos)

1. **Conexión HTTPS** - Navegación web segura
2. **Conexión MySQL** - Base de datos interna
3. **Petición HTTP GET** - Descarga web normal
4. **Consulta DNS** - Resolución de nombres
5. **Sesión SSH** - Administración remota
6. **Conexión IMAP** - Descarga de correo
7. **Conexión PostgreSQL** - Base de datos de aplicación
8. **Sesión POP3** - Cliente de correo
9. **Proxy HTTP interno** - Filtrado corporativo

### 🚨 Técnicas de Port Scanning (9 ejemplos)

#### 1. **SYN Scan (Half-open Scan)**
```
Técnica: Envía SYN sin completar handshake TCP
Ventaja para atacante: Sigiloso, no deja logs completos
Indicador: Alto volumen de paquetes SYN en poco tiempo
```

#### 2. **Xmas Tree Scan**
```
Técnica: Paquetes con flags FIN+PSH+URG simultáneos
Ventaja para atacante: Evasión de IDS básicos
Indicador: Flags TCP anómalas combinadas
```

#### 3. **NULL Scan**
```
Técnica: Paquetes TCP sin flags
Ventaja para atacante: Muy sigiloso, difícil de detectar
Indicador: Paquetes sin flags + IP sospechosa
```

#### 4. **FIN Scan**
```
Técnica: Solo flag FIN sin conexión previa
Ventaja para atacante: Evade firewalls stateless
Indicador: FIN sin contexto de conexión establecida
```

#### 5. **ACK Scan**
```
Técnica: Paquetes ACK para mapear firewall
Ventaja para atacante: Descubre reglas de firewall
Indicador: ACK sin conexión + alto volumen
```

#### 6. **UDP Scan**
```
Técnica: Escaneo de servicios UDP
Ventaja para atacante: Encuentra servicios críticos (DNS, SNMP)
Indicador: Volumen masivo de paquetes UDP
```

#### 7. **TCP Connect Scan**
```
Técnica: Completa handshake TCP
Ventaja para atacante: Funciona siempre, no requiere privilegios
Indicador: Múltiples conexiones completas sin propósito
```

#### 8. **Vertical Scan**
```
Técnica: Muchos puertos en un solo host
Ventaja para atacante: Mapeo completo de servicios
Indicador: Escaneo secuencial de rango completo de puertos
```

#### 9. **Horizontal Scan (Botnet)**
```
Técnica: Un puerto en múltiples hosts (botnet)
Ventaja para atacante: Busca vulnerabilidad masivamente
Indicador: Orígenes distribuidos + mismo puerto
```

## 🔢 Puertos Importantes

### Puertos Comunes Legítimos
- **21** - FTP (Transferencia de archivos)
- **22** - SSH (Administración segura)
- **25** - SMTP (Envío de correo)
- **53** - DNS (Resolución de nombres)
- **80** - HTTP (Web)
- **110** - POP3 (Recepción de correo)
- **143** - IMAP (Correo avanzado)
- **443** - HTTPS (Web segura)
- **3306** - MySQL (Base de datos)
- **5432** - PostgreSQL (Base de datos)
- **8080** - HTTP-Alt (Proxy web)

### Puertos de Alto Riesgo
- **23** - Telnet (SIN CIFRAR - PELIGROSO)
- **445** - SMB (Vector de ransomware - EternalBlue)
- **3389** - RDP (Remote Desktop - blanco común)
- **161** - SNMP (Info sensible de red)

## 🚩 Indicadores de Escaneo Malicioso

### Volumen de Tráfico
- ⚠️ **>100 paquetes** en actividad corta
- ⚠️ **>500 paquetes** = definitivamente automatizado
- ⚠️ **Segundos vs minutos** - velocidad sospechosa

### Patrones de Conexión
- 🔴 **Conexiones sin completar** (SYN sin ACK)
- 🔴 **Flags TCP anómalas** (FIN+PSH+URG, NULL, solo FIN/ACK)
- 🔴 **Múltiples intentos** sin intercambio de datos
- 🔴 **Secuencial** (puerto 1, 2, 3... 1000)

### Origen de la Actividad
- 🔴 **IP externa desconocida** hacia puertos críticos
- 🔴 **IP falsificada/spoofed**
- 🔴 **Orígenes distribuidos** (botnet)
- ✅ **Red interna** (10.x.x.x, 172.16-31.x.x, 192.168.x.x)

### Puertos Objetivo
- 🔴 **Telnet (23)** - Protocolo inseguro obsoleto
- 🔴 **SMB (445)** - Vector crítico de malware
- 🔴 **RDP (3389)** - Acceso remoto completo
- 🔴 **SNMP (161)** - Información de dispositivos

### Comportamiento Temporal
- ⚠️ **Segundos** para cientos de paquetes = automatizado
- ✅ **Minutos/horas** para pocas conexiones = normal
- 🔴 **Patrón repetitivo** sin variación = bot

## 💡 Reglas de Oro para Detectar Scans

1. **Volumen + Velocidad = Automatización**
   - Si ves cientos de paquetes en segundos, es scan

2. **Flags TCP Normales vs Anómalas**
   - Normal: SYN → SYN-ACK → ACK (handshake completo)
   - Anómalo: Solo SYN, o FIN sin conexión, o flags raras

3. **Red Interna = Generalmente Seguro**
   - IPs 10.x, 172.16-31.x, 192.168.x = tráfico interno legítimo
   - IPs externas + puertos sensibles = ALERTA

4. **Contexto del Puerto**
   - HTTP/HTTPS/DNS = uso común legítimo
   - Telnet/SMB/RDP desde externa = SOSPECHOSO

5. **Completitud de Conexiones**
   - Conexión completa + intercambio datos = legítimo
   - Conexiones sin completar + sin datos = reconocimiento

6. **IP Origen Clara vs Oscura**
   - IP identificada + descripción clara = probablemente OK
   - "unknown", "spoofed", "distributed" = ALERTA ROJA

## 📁 Archivos del Proyecto

### Scripts
- `PortScanResource.gd` - Clase que representa una actividad de red
- `PortScanDatabase.gd` - Base de datos de actividades
- `port_scanner_defender.gd` - Lógica principal del juego

### Escenas
- `PortScannerDefender.tscn` - Escena principal con UI completa

### Recursos
- `port_scan_database.tres` - 18 actividades (9 legítimas, 9 scans)
- `PortScannerDefenderApp.tres` - Configuración de la app

## 🎮 Características

- ✅ **18 actividades variadas** (9 legítimas + 9 scans)
- ✅ **9 técnicas diferentes** de port scanning
- ✅ **11 puertos comunes** + 4 de alto riesgo
- ✅ **Sistema de pistas** educativo
- ✅ **Análisis de indicadores** automático
- ✅ **Explicaciones técnicas** detalladas
- ✅ **3 vidas** para margen de error
- ✅ **Temporizador** de 9 minutos
- ✅ **Sistema de puntos** con bonus
- ✅ **Dificultad única progresiva**

## 🚀 Integración

El minijuego está integrado como **aplicación de pistas** en el escritorio del juego, accesible mediante un icono dedicado junto a los demás minijuegos de ciberseguridad.

## 🎓 Valor Educativo

Este minijuego enseña:
- **Identificación de port scans** en tráfico real
- **Técnicas de escaneo** usadas por atacantes
- **Funcionamiento de IDS/IPS** (Sistemas de Detección/Prevención)
- **Análisis de paquetes** y flags TCP
- **Puertos críticos** y sus servicios
- **Comportamiento normal vs anómalo** de red
- **Vectores de ataque** comunes (SMB, RDP, Telnet)
- **Tácticas de evasión** de seguridad

### Conceptos Técnicos

**Port Scanning**: Técnica de reconocimiento donde un atacante envía paquetes a múltiples puertos para descubrir qué servicios están activos en un objetivo.

**IDS (Intrusion Detection System)**: Sistema que monitorea tráfico de red en busca de actividad sospechosa o maliciosa.

**TCP Handshake Normal**:
```
Cliente → SYN → Servidor
Servidor → SYN-ACK → Cliente
Cliente → ACK → Servidor
```

**Stealth Scanning**: Técnicas diseñadas para evitar detección por IDS/firewalls usando flags TCP anómalas o no completando conexiones.

## 🏆 Consejos para Jugadores

1. 🔢 **Mira el volumen de paquetes** - Más de 100 es sospechoso
2. ⏱️ **Observa el tiempo** - Segundos = automatizado
3. 🌐 **Verifica la IP** - Externa + puerto sensible = alerta
4. 🔌 **Conoce los puertos** - Telnet/SMB/RDP son blancos comunes
5. 🤝 **Busca handshakes completos** - Incompletos = reconocimiento
6. 🚩 **Flags TCP anómalas** - FIN/NULL/Xmas = definitivamente scan
7. 🏠 **Red interna es segura** - 10.x/192.168.x son OK generalmente
8. 💡 **Usa pistas cuando dudes** - Mejor aprender que fallar

## 📊 Estadísticas del Juego

- **Balance perfecto**: 50% legítimo, 50% malicioso
- **Tiempo promedio por análisis**: 30 segundos
- **Puntuación perfecta**: 3,240 puntos (18 × 180)
- **Técnicas de scan**: 9 diferentes (de básico a avanzado)
- **Puertos cubiertos**: 15 puertos distintos

## 🔐 Casos de Uso Real

Los ejemplos están basados en ataques y tráfico real:
- **SYN Floods** - Ataques DoS comunes
- **EternalBlue** - Exploit de SMB que causó WannaCry
- **RDP Brute Force** - Ataques masivos de fuerza bruta
- **SNMP Enumeration** - Recopilación de info de dispositivos
- **Botnet Scanning** - Búsqueda masiva de vulnerabilidades

¡Conviértete en un experto en seguridad de redes y protege la infraestructura de amenazas! 🔍🛡️
