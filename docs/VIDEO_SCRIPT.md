# Video Demo Script - BossAuto PoC

## Duración: 5-7 minutos

## Objetivo
Demostrar el PoC funcional del Flujo 1 (Motor de Aprobaciones) de manera clara, técnica y profesional.

---

## 🎬 SCRIPT

### [00:00 - 00:30] INTRO

**[Pantalla: Título + Logo]**

**"Hola, soy [Tu Nombre]. He desarrollado un Proof of Concept funcional del Flujo 1 del proyecto BossAuto - el Motor de Aprobaciones Multinivel para solicitudes de compra con integración a Microsoft Dynamics 365 Business Central.**

**En los próximos 5 minutos les mostraré:**
- ✅ El workflow completo en n8n
- ✅ La integración con una Mock API de Business Central
- ✅ El sistema de reglas de aprobación multinivel
- ✅ La persistencia en PostgreSQL
- ✅ El sistema de notificaciones
- ✅ Y por supuesto, todo funcionando en tiempo real

**Vamos allá."**

---

### [00:30 - 01:30] ARQUITECTURA GENERAL

**[Pantalla: Diagrama de Arquitectura]**

**"Primero, veamos la arquitectura del sistema."**

**[Mostrar README.md con el diagrama]**

**"El flujo es el siguiente:**
1. Recibimos una solicitud de compra vía Webhook
2. Validamos los datos de entrada
3. Guardamos en PostgreSQL
4. Aplicamos reglas de negocio basadas en el monto
5. Si es auto-aprobación (menos de $1,000), creamos la Purchase Order en Business Central
6. Si requiere aprobación, calculamos el SLA y enviamos notificación
7. Todo queda registrado en la base de datos con trazabilidad completa

**Esta arquitectura replica exactamente lo que necesitan para el proyecto completo."**

---

### [01:30 - 03:00] DEMO DEL WORKFLOW EN n8n

**[Pantalla: n8n Editor]**

**"Ahora veamos el workflow en n8n. Aquí está el flujo completo."**

**[Hacer scroll lento por el workflow, mostrando los nodos]**

**"Tenemos 12 nodos interconectados:**

1. **Webhook Trigger** - punto de entrada del sistema
2. **Validate Input** - validación de estructura y datos
3. **Save to PostgreSQL** - persistencia de la solicitud
4. **Get Approval Rules** - obtención de reglas según monto
5. **Apply Business Rules** - lógica de negocio
6. **Calculate SLA** - cálculo de deadline
7. **Branch: Auto vs Manual** - split según tipo de aprobación
8. **Create PO in BC** - llamada a Business Central API
9. **Save Approval History** - registro de decisiones
10. **Send Notification** - Telegram (adaptable a Teams)
11. **System Logs** - logging completo
12. **Response** - respuesta estructurada JSON

**[Click en un nodo de Function para mostrar código]**

**"Aquí pueden ver el código JavaScript que implementa las reglas de aprobación multinivel. Todo está documentado y es fácil de mantener."**

---

### [03:00 - 04:00] DEMO EN VIVO - Test Request

**[Pantalla: Terminal o Postman]**

**"Ahora hagamos una prueba en vivo. Voy a enviar una solicitud de compra por $3,500 - esto requiere aprobación del Gerente de Compras."**

**[Ejecutar curl o Postman request]**

```bash
curl -X POST https://webscansearch.name/automotive/webhook/purchase-request \
  -H "Content-Type: application/json" \
  -d '{...}'
```

**[Mostrar response]**

**"Perfecto. El sistema respondió que:**
- La solicitud fue recibida
- Requiere aprobación de nivel 'manager'
- El SLA es de 24 horas
- La notificación fue enviada
- Todo está registrado en la base de datos"**

---

### [04:00 - 04:45] VERIFICACIÓN EN BASE DE DATOS

**[Pantalla: PostgreSQL / pgAdmin]**

**"Veamos qué se guardó en la base de datos."**

**[Ejecutar queries]**

```sql
SELECT * FROM purchase_requests ORDER BY created_at DESC LIMIT 1;
```

**"Aquí está nuestra solicitud con todos los detalles."**

```sql
SELECT * FROM approval_history WHERE request_id = 'PR-TEST-002';
```

**"Y aquí el historial de aprobación, incluyendo el nivel requerido y el SLA."**

```sql
SELECT * FROM system_logs WHERE request_id = 'PR-TEST-002';
```

**"Y todos los logs del sistema para trazabilidad completa."**

---

### [04:45 - 05:30] MOCK BUSINESS CENTRAL API

**[Pantalla: Browser o Postman]**

**"También desarrollé una Mock API de Business Central para simular las integraciones. En el proyecto real, esto se conectará a su BC real."**

**[Mostrar health endpoint]**

```
GET https://webscansearch.name/automotive/health
```

**"El Mock API simula:**
- Vendors (proveedores)
- Items (productos)
- Purchase Orders (órdenes de compra)

**[Mostrar un endpoint]**

```
GET https://webscansearch.name/automotive/api/v1/vendors
```

**"Todo siguiendo la estructura de la API real de Business Central."**

---

### [05:30 - 06:15] SISTEMA DE REGLAS Y ESCALABILIDAD

**[Pantalla: Tabla approval_rules en DB]**

**"Una característica importante: las reglas de aprobación están en base de datos."**

```sql
SELECT * FROM approval_rules;
```

**"Esto significa que pueden modificar:**
- Los umbrales de montos
- Los niveles de aprobación
- Los SLAs
- Todo sin tocar código, solo actualizando la tabla.

**Es 100% configurable y escalable."**

---

### [06:15 - 07:00] CIERRE

**[Pantalla: GitHub repo o Documentation]**

**"Para resumir, este PoC demuestra:**

✅ Dominio técnico de n8n y automatizaciones complejas
✅ Experiencia con integraciones de APIs REST
✅ Conocimiento de Business Central
✅ Diseño de bases de datos robustas
✅ Código limpio y documentado
✅ Enfoque en calidad y trazabilidad

**Este es solo el Flujo 1. Para el proyecto completo, desarrollaré los 5 flujos con el mismo nivel de calidad, siguiendo exactamente sus especificaciones.**

**Toda la documentación técnica, scripts de deployment, y código está disponible. Puedo comenzar inmediatamente.**

**¿Hablamos?**

**Gracias por su tiempo."**

**[Pantalla final con contacto]**

---

## 📋 CHECKLIST PRE-GRABACIÓN

Antes de grabar, asegurarse de tener:

- [ ] n8n workflow importado y funcionando
- [ ] Mock API corriendo en VPS
- [ ] PostgreSQL con datos de prueba
- [ ] Postman/curl requests preparados
- [ ] Database client (pgAdmin/DBeaver) abierto
- [ ] Browser con todos los tabs necesarios
- [ ] Screen recording software configurado (OBS/Loom)
- [ ] Audio test realizado
- [ ] Internet estable

## 🎨 TIPS DE GRABACIÓN

1. **Calidad de audio**: Usar micrófono decente, ambiente silencioso
2. **Resolución**: 1080p mínimo
3. **Cursor**: Activar highlight del cursor para que sea visible
4. **Velocidad**: Hablar claro pero no muy lento
5. **Pantalla**: Cerrar notificaciones y apps innecesarias
6. **Edición**: Agregar texto/flechas para enfatizar puntos clave
7. **Música de fondo**: Opcional, muy baja si la usas
8. **Subtítulos**: Considerar agregar subtítulos en español

## 📤 DÓNDE SUBIR

- YouTube (unlisted o private, compartir link)
- Loom (más simple, profesional)
- Google Drive (si el archivo es muy grande)
- Vimeo (buena calidad)

## 🔗 INCLUIR EN PROPUESTA

Agregar el link del video en:
- Cover letter de Upwork
- Mensaje inicial al cliente
- Portfolio/GitHub readme
- LinkedIn (si quieres promocionarte)

---

**¡Mucha suerte con el video! 🎬🚀**
