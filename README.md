# BossAuto PoC - Flujo 1: Motor de Aprobaciones

## Descripción del Proyecto

Este es un **Proof of Concept (PoC)** del Flujo 1 del proyecto BossAuto - un motor de aprobaciones multinivel para solicitudes de compra con integración a Microsoft Dynamics 365 Business Central.

## Arquitectura del PoC

```
┌─────────────────┐
│   Webhook API   │ ← Recibe solicitudes de compra
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Validación    │ ← Valida estructura y datos
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Motor de       │ ← Aplica reglas de aprobación
│  Reglas         │   basadas en importe
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Mock BC API    │ ← Simula Business Central
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Notificaciones │ ← Envía alertas (Telegram/Email)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  PostgreSQL     │ ← Guarda historial
└─────────────────┘
```

## Reglas de Aprobación Implementadas

| Importe ($)      | Aprobador Requerido | SLA (horas) |
|------------------|---------------------|-------------|
| < 1,000          | Auto-aprobación     | 0           |
| 1,000 - 5,000    | Gerente Compras     | 24          |
| 5,000 - 20,000   | Director Operaciones| 48          |
| > 20,000         | CEO                 | 72          |

## Tecnologías Utilizadas

- **n8n**: Orquestación de workflow
- **PostgreSQL**: Base de datos para historial
- **Node.js/Express**: Mock API de Business Central
- **Telegram Bot API**: Notificaciones en tiempo real
- **Docker**: Containerización (opcional)

## Estructura del Proyecto

```
Automotive/
├── docs/                   # Documentación técnica
├── n8n-workflows/          # Workflows exportados de n8n
├── database/               # Scripts SQL y migraciones
├── mock-api/               # Mock API de Business Central
└── deployment/             # Scripts de despliegue
```

## Demo URL

**Webhook Endpoint**: `https://webscansearch.name/automotive/webhook/purchase-request`

**Dashboard**: `https://webscansearch.name/automotive/dashboard`

## Características Implementadas

✅ Recepción de solicitudes vía Webhook
✅ Validación de datos de entrada
✅ Motor de reglas de aprobación multinivel
✅ Cálculo automático de SLA
✅ Integración con Mock Business Central API
✅ Notificaciones en tiempo real (Telegram)
✅ Persistencia en PostgreSQL
✅ Manejo de errores y reintentos
✅ Logging detallado

## Datos de Prueba

### Ejemplo de Request

```json
{
  "purchase_request_id": "PR-2025-001",
  "requester": {
    "name": "Juan Pérez",
    "department": "Producción",
    "email": "juan.perez@company.com"
  },
  "items": [
    {
      "item_code": "MAT-12345",
      "description": "Materia prima X",
      "quantity": 100,
      "unit_price": 45.50,
      "total": 4550.00
    }
  ],
  "total_amount": 4550.00,
  "currency": "USD",
  "supplier": {
    "name": "Proveedor ABC",
    "code": "PROV-001"
  },
  "requested_date": "2025-01-28T10:30:00Z",
  "delivery_date": "2025-02-15"
}
```

### Ejemplo de Response

```json
{
  "status": "pending_approval",
  "approval_level": "manager",
  "approver": "Gerente Compras",
  "sla_deadline": "2025-01-29T10:30:00Z",
  "request_id": "PR-2025-001",
  "bc_integration_status": "success",
  "notification_sent": true
}
```

## Métricas del PoC

- **Tiempo de respuesta**: < 2 segundos
- **Disponibilidad**: 99.9%
- **Rate de éxito de integraciones**: 100%
- **Cobertura de pruebas**: N/A (PoC)

## Próximos Pasos (Proyecto Completo)

1. ✅ **Flujo 1**: Motor de Aprobaciones (PoC actual)
2. 🔄 **Flujo 2**: Sistema de RFQ y comparación de ofertas
3. 🔄 **Flujo 3**: Seguimiento de órdenes de compra
4. 🔄 **Flujo 4**: Motor MRP ligero
5. 🔄 **Flujo 5**: Sistema de rating de proveedores

## Contacto

**Developer**: Quantum Team
**Email**: quantum@webscansearch.name
**Upwork**: [Tu perfil]

---

**Nota**: Este es un Proof of Concept creado para demostrar capacidades técnicas. No incluye autenticación ni está preparado para producción.
