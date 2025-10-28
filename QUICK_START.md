# 🚀 BossAuto PoC - Quick Start Guide

Guía rápida para deployar y probar el PoC en 30 minutos.

## Prerequisitos

- VPS con Ubuntu 20.04+
- Node.js 18+ instalado
- PostgreSQL 14+ instalado
- nginx instalado
- Acceso SSH: `quantum@188.245.77.73`
- Dominio: `webscansearch.name`

## 🎯 Setup Rápido (30 minutos)

### 1. Deploy a VPS (5 min)

```bash
# Hacer ejecutable el script de deploy
chmod +x /Users/alex/UpWork/Automotive/deployment/deploy.sh

# Ejecutar deployment
cd /Users/alex/UpWork/Automotive/deployment
./deploy.sh
```

### 2. Configurar PostgreSQL (5 min)

```bash
# Conectar al VPS
ssh quantum@188.245.77.73

# Crear database (si no existe)
sudo -u postgres psql -c "CREATE DATABASE bossauto;"
sudo -u postgres psql -c "CREATE USER quantum WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bossauto TO quantum;"

# Importar schema
cd /var/www/html/Automotive/database
psql -U quantum -d bossauto -f schema.sql

# Importar datos de prueba (opcional)
psql -U quantum -d bossauto -f sample_data.sql

# Verificar
psql -U quantum -d bossauto -c "\dt"
```

### 3. Iniciar Mock API (2 min)

```bash
# Instalar dependencias
cd /var/www/html/Automotive/mock-api
npm install

# Iniciar con PM2
pm2 start server.js --name bossauto-mock-api
pm2 save

# Verificar
curl http://localhost:3001/health
```

### 4. Configurar nginx (3 min)

```bash
# Copiar configuración
sudo cp /var/www/html/Automotive/deployment/nginx-automotive.conf /etc/nginx/sites-available/automotive

# Activar sitio
sudo ln -s /etc/nginx/sites-available/automotive /etc/nginx/sites-enabled/

# Test
sudo nginx -t

# Reload
sudo systemctl reload nginx

# Verificar
curl http://webscansearch.name/automotive/health
```

### 5. Setup n8n (10 min)

```bash
# Si n8n no está instalado
sudo npm install -g n8n

# Configurar variables de entorno
export N8N_HOST="0.0.0.0"
export N8N_PORT=5678
export N8N_PROTOCOL="http"
export WEBHOOK_URL="https://webscansearch.name"

# Iniciar n8n con PM2
pm2 start n8n --name n8n -- start
pm2 save

# Acceder a: http://webscansearch.name:5678
```

**En la UI de n8n:**

1. Crear credentials para PostgreSQL:
   - Name: `BossAuto PostgreSQL`
   - Host: `localhost`
   - Database: `bossauto`
   - User: `quantum`
   - Password: `[tu_password]`

2. Importar workflow:
   - Click "Import from File"
   - Seleccionar: `n8n-workflows/flujo-1-approval-engine.json` (cuando lo crees)
   - Asignar credentials
   - Activar workflow

### 6. Configurar Telegram Bot (5 min) - OPCIONAL

```bash
# 1. Crear bot con @BotFather en Telegram
# 2. Obtener token
# 3. Obtener chat_id:

# Enviar mensaje al bot, luego:
curl "https://api.telegram.org/bot<TOKEN>/getUpdates"

# 4. Agregar credentials en n8n:
# Name: BossAuto Telegram
# Access Token: [tu_token]
```

## ✅ Testing (5 min)

### Test 1: Health Check

```bash
curl http://webscansearch.name/automotive/health
```

**Esperado:**
```json
{
  "status": "ok",
  "service": "BossAuto Mock BC API"
}
```

### Test 2: Auto-aprobación (< $1,000)

```bash
curl -X POST http://webscansearch.name/automotive/webhook/purchase-request \
  -H "Content-Type: application/json" \
  -d '{
    "purchase_request_id": "PR-TEST-001",
    "requester": {
      "name": "Test User",
      "department": "Testing",
      "email": "test@company.com"
    },
    "items": [{
      "item_code": "TEST-001",
      "description": "Test Item",
      "quantity": 10,
      "unit_price": 50,
      "total": 500
    }],
    "total_amount": 500,
    "currency": "USD",
    "supplier": {
      "name": "Test Supplier",
      "code": "SUP-TEST"
    },
    "requested_date": "2025-01-28T10:00:00Z",
    "delivery_date": "2025-02-15"
  }'
```

### Test 3: Aprobación Manager ($1,000+)

```bash
curl -X POST http://webscansearch.name/automotive/webhook/purchase-request \
  -H "Content-Type: application/json" \
  -d '{
    "purchase_request_id": "PR-TEST-002",
    "requester": {
      "name": "Test User 2",
      "department": "Testing",
      "email": "test2@company.com"
    },
    "items": [{
      "item_code": "TEST-002",
      "description": "Test Item 2",
      "quantity": 50,
      "unit_price": 60,
      "total": 3000
    }],
    "total_amount": 3000,
    "currency": "USD",
    "supplier": {
      "name": "Test Supplier",
      "code": "SUP-TEST"
    },
    "requested_date": "2025-01-28T10:00:00Z",
    "delivery_date": "2025-02-15"
  }'
```

### Test 4: Verificar en Database

```bash
psql -U quantum -d bossauto -c "SELECT request_id, total_amount, status, approval_level FROM purchase_requests ORDER BY created_at DESC LIMIT 5;"
```

## 🔍 Monitoring

```bash
# Ver logs de Mock API
pm2 logs bossauto-mock-api

# Ver logs de n8n
pm2 logs n8n

# Ver logs de nginx
sudo tail -f /var/log/nginx/automotive-access.log

# Ver estado de servicios
pm2 status
```

## 🐛 Troubleshooting

### Mock API no responde
```bash
pm2 restart bossauto-mock-api
pm2 logs bossauto-mock-api --lines 50
```

### PostgreSQL no conecta
```bash
# Verificar que esté corriendo
sudo systemctl status postgresql

# Verificar conexión
psql -U quantum -d bossauto -h localhost
```

### n8n no recibe webhooks
```bash
# Verificar workflow activado en UI
# Verificar nginx:
sudo nginx -t
sudo systemctl reload nginx

# Ver logs:
pm2 logs n8n
```

## 📦 Estructura de Archivos

```
/var/www/html/Automotive/
├── database/
│   ├── schema.sql              # Schema de PostgreSQL
│   └── sample_data.sql         # Datos de prueba
├── mock-api/
│   ├── server.js               # Mock BC API
│   ├── package.json
│   └── node_modules/
├── deployment/
│   ├── deploy.sh               # Script de deployment
│   ├── nginx-automotive.conf   # Config nginx
│   └── SETUP_GUIDE.md          # Guía completa
└── README.md
```

## 🎯 Next Steps

1. ✅ Todo funcionando localmente
2. 🎥 Grabar video demo
3. 📝 Escribir proposal para Upwork
4. 🚀 Enviar propuesta con link al demo

## 🆘 Ayuda

Si algo no funciona:
1. Verificar logs: `pm2 logs`
2. Verificar puertos: `netstat -tulpn | grep -E '3001|5678'`
3. Verificar permisos: `ls -la /var/www/html/Automotive/`
4. Reiniciar servicios: `pm2 restart all`

---

**¡Listo! Ahora tienes un PoC funcional para impresionar al cliente. 🚀**
