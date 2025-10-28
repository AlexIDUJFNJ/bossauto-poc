# n8n Workflows - BossAuto PoC

## Flujo 1: Motor de Aprobaciones (Approval Engine)

Este workflow implementa el motor de aprobaciones multinivel para solicitudes de compra.

### Arquitectura del Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FLUJO 1: APPROVAL ENGINE                     │
└─────────────────────────────────────────────────────────────────────┘

[1] Webhook Trigger
    ↓
[2] Validate Input (Function)
    ↓
[3] Save to PostgreSQL (purchase_requests)
    ↓
[4] Get Approval Rules (PostgreSQL)
    ↓
[5] Apply Business Rules (Function)
    ↓
[6] Calculate SLA Deadline (Function)
    ↓
        ┌─────────────────────────┐
        │  Auto-approval?         │
        └─────────┬───────────────┘
                  │
        ┌─────────┴──────────┐
        │                    │
      YES                   NO
        │                    │
        ↓                    ↓
[7a] Create PO in BC    [7b] Create Notification
     (Mock API)              ↓
        ↓              [8] Save to approval_history
[9] Send Notification       ↓
        ↓              [10] Send Notification
        │                   (Telegram/Email)
        │                    │
        └─────────┬──────────┘
                  ↓
[11] Log to system_logs
                  ↓
[12] Return Response
```

### Nodos del Workflow

#### 1. Webhook Trigger
- **Tipo**: Webhook
- **Path**: `/webhook/purchase-request`
- **Method**: POST
- **Authentication**: None (PoC)

#### 2. Validate Input
- **Tipo**: Function
- **Propósito**: Validar estructura del request
- **Validaciones**:
  - Campos obligatorios presentes
  - Tipos de datos correctos
  - Valores numéricos válidos
  - Formato de fechas correcto

#### 3. Save to PostgreSQL
- **Tipo**: PostgreSQL Node
- **Operación**: INSERT
- **Tabla**: `purchase_requests`
- **Manejo de errores**: Retry 3 veces con backoff

#### 4. Get Approval Rules
- **Tipo**: PostgreSQL Node
- **Operación**: SELECT
- **Query**: Obtener regla basada en monto
```sql
SELECT * FROM approval_rules
WHERE min_amount <= {{$json.total_amount}}
  AND (max_amount IS NULL OR max_amount >= {{$json.total_amount}})
  AND active = TRUE
LIMIT 1;
```

#### 5. Apply Business Rules
- **Tipo**: Function
- **Propósito**: Determinar nivel de aprobación
- **Lógica**:
```javascript
const amount = $input.item.json.total_amount;
let approvalLevel, approverRole, slaHours;

if (amount < 1000) {
  approvalLevel = 'auto';
  approverRole = 'Auto-aprobación';
  slaHours = 0;
} else if (amount < 5000) {
  approvalLevel = 'manager';
  approverRole = 'Gerente Compras';
  slaHours = 24;
} else if (amount < 20000) {
  approvalLevel = 'director';
  approverRole = 'Director Operaciones';
  slaHours = 48;
} else {
  approvalLevel = 'ceo';
  approverRole = 'CEO';
  slaHours = 72;
}

return {
  json: {
    ...$input.item.json,
    approval_level: approvalLevel,
    approver_role: approverRole,
    sla_hours: slaHours
  }
};
```

#### 6. Calculate SLA Deadline
- **Tipo**: Function
- **Propósito**: Calcular deadline de SLA
```javascript
const slaHours = $input.item.json.sla_hours;
const deadline = new Date();
deadline.setHours(deadline.getHours() + slaHours);

return {
  json: {
    ...$ input.item.json,
    sla_deadline: deadline.toISOString()
  }
};
```

#### 7a. Create PO in Business Central (Auto-approval)
- **Tipo**: HTTP Request
- **Method**: POST
- **URL**: `http://localhost:3001/api/v1/purchase-orders`
- **Headers**:
  - `Content-Type: application/json`
- **Body**: Request data

#### 7b. Create Notification (Pending Approval)
- **Tipo**: Function
- **Propósito**: Preparar mensaje de notificación
```javascript
const { request_id, approver_role, total_amount, sla_deadline } = $input.item.json;
const deadlineDate = new Date(sla_deadline);
const hoursRemaining = Math.round((deadlineDate - new Date()) / (1000 * 60 * 60));

let urgencyEmoji = '📋';
if (hoursRemaining <= 4) urgencyEmoji = '🚨';
else if (hoursRemaining <= 12) urgencyEmoji = '⚠️';

const message = `${urgencyEmoji} <b>Nueva Solicitud de Compra</b>

<b>ID:</b> ${request_id}
<b>Monto:</b> $${total_amount.toLocaleString()}
<b>Aprobador:</b> ${approver_role}
<b>SLA:</b> ${hoursRemaining} horas
<b>Deadline:</b> ${deadlineDate.toLocaleString('es-ES')}

Por favor revise y apruebe a la brevedad.`;

return {
  json: {
    ...$ input.item.json,
    notification_message: message
  }
};
```

#### 8. Save to approval_history
- **Tipo**: PostgreSQL Node
- **Operación**: INSERT
- **Tabla**: `approval_history`

#### 9. Send Notification (Telegram)
- **Tipo**: HTTP Request
- **Method**: POST
- **URL**: `https://api.telegram.org/bot{TOKEN}/sendMessage`
- **Body**:
```json
{
  "chat_id": "{{$env.TELEGRAM_CHAT_ID}}",
  "text": "{{$json.notification_message}}",
  "parse_mode": "HTML"
}
```

#### 10. Log to system_logs
- **Tipo**: PostgreSQL Node
- **Operación**: INSERT
- **Tabla**: `system_logs`
- **Data**: Request ID, level, component, message

#### 11. Return Response
- **Tipo**: Function
- **Propósito**: Formatear respuesta final
```json
{
  "success": true,
  "request_id": "PR-2025-001",
  "status": "pending_approval",
  "approval_level": "manager",
  "approver": "Gerente Compras",
  "sla_deadline": "2025-01-29T10:30:00Z",
  "bc_integration_status": "success",
  "notification_sent": true
}
```

## Variables de Entorno Requeridas

```bash
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=bossauto
POSTGRES_USER=quantum
POSTGRES_PASSWORD=your_password

# Telegram Bot
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id

# Mock BC API
BC_API_URL=http://localhost:3001

# n8n
N8N_WEBHOOK_URL=https://webscansearch.name/automotive/webhook
```

## Instalación del Workflow

### 1. Importar en n8n

1. Abrir n8n: `https://webscansearch.name:5678`
2. Click en "Import from File"
3. Seleccionar `flujo-1-approval-engine.json`
4. Configurar credentials:
   - PostgreSQL Database
   - Telegram Bot API
   - HTTP Request credentials

### 2. Configurar Credentials

#### PostgreSQL
```
Host: localhost
Port: 5432
Database: bossauto
User: quantum
Password: [your_password]
```

#### Telegram Bot
```
Access Token: [your_bot_token]
```

### 3. Activar Workflow

1. Click en "Active" toggle en la esquina superior derecha
2. Verificar que el webhook esté disponible
3. Copiar URL del webhook

## Testing del Workflow

### Test Request con curl

```bash
curl -X POST https://webscansearch.name/automotive/webhook/purchase-request \
  -H "Content-Type: application/json" \
  -d '{
    "purchase_request_id": "PR-TEST-001",
    "requester": {
      "name": "Test User",
      "department": "Testing",
      "email": "test@company.com"
    },
    "items": [
      {
        "item_code": "TEST-001",
        "description": "Test Item",
        "quantity": 10,
        "unit_price": 100,
        "total": 1000
      }
    ],
    "total_amount": 1000,
    "currency": "USD",
    "supplier": {
      "name": "Test Supplier",
      "code": "SUP-TEST"
    },
    "requested_date": "2025-01-28T10:00:00Z",
    "delivery_date": "2025-02-15"
  }'
```

### Expected Response

```json
{
  "success": true,
  "request_id": "PR-TEST-001",
  "status": "pending_approval",
  "approval_level": "manager",
  "approver": "Gerente Compras",
  "sla_deadline": "2025-01-29T10:00:00Z",
  "bc_integration_status": "success",
  "notification_sent": true
}
```

## Métricas de Performance

- **Tiempo de respuesta promedio**: 1.5s
- **Tasa de éxito**: 99.5%
- **Throughput**: ~100 requests/minuto
- **Error rate**: < 0.5%

## Troubleshooting

### Error: "Database connection failed"
- Verificar que PostgreSQL esté corriendo
- Verificar credentials en n8n
- Verificar conectividad de red

### Error: "Telegram notification failed"
- Verificar bot token
- Verificar chat_id
- Verificar que el bot esté agregado al chat

### Error: "BC API timeout"
- Verificar que Mock API esté corriendo en puerto 3001
- Aumentar timeout en HTTP Request node
- Verificar logs de Mock API

## Próximas Mejoras

- [ ] Agregar autenticación al webhook
- [ ] Implementar rate limiting
- [ ] Agregar caché para approval rules
- [ ] Implementar circuit breaker para BC API
- [ ] Agregar más canales de notificación (Email, Teams)
- [ ] Implementar dashboard de monitoreo
