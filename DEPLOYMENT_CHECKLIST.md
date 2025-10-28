# 🚀 BossAuto PoC - Deployment Checklist

## Pre-Deployment

### ✅ Preparación Local

- [ ] Todos los archivos están en `/Users/alex/UpWork/Automotive/`
- [ ] Scripts tienen permisos de ejecución (`chmod +x`)
- [ ] Tienes acceso SSH al VPS: `ssh quantum@188.245.77.73`
- [ ] Tienes contraseña de PostgreSQL preparada

### ✅ Verificar VPS

```bash
ssh quantum@188.245.77.73

# Check services
node --version          # Should be 18+
psql --version         # Should be 14+
nginx -v               # Should be installed
pm2 --version          # Should be installed
```

## Deployment Steps

### 1️⃣ Deploy Archivos (5 min)

```bash
# En tu Mac
cd /Users/alex/UpWork/Automotive/deployment
./deploy.sh
```

**Verificar:**
- [ ] Archivos copiados a `/var/www/html/Automotive/`
- [ ] No hubo errores en el output

### 2️⃣ Setup PostgreSQL (5 min)

```bash
# En VPS
ssh quantum@188.245.77.73

# Crear database
sudo -u postgres psql << EOF
CREATE DATABASE bossauto;
CREATE USER quantum WITH ENCRYPTED PASSWORD 'YOUR_SECURE_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE bossauto TO quantum;
\q
EOF

# Importar schema
cd /var/www/html/Automotive/database
psql -U quantum -d bossauto -f schema.sql

# Importar datos de prueba
psql -U quantum -d bossauto -f sample_data.sql

# Verificar tablas
psql -U quantum -d bossauto -c "\dt"
```

**Verificar:**
- [ ] Database `bossauto` creada
- [ ] 6 tablas creadas
- [ ] Datos de prueba insertados
- [ ] Puedes conectarte: `psql -U quantum -d bossauto -h localhost`

### 3️⃣ Start Mock API (2 min)

```bash
# En VPS
cd /var/www/html/Automotive/mock-api

# Instalar dependencias
npm install

# Start con PM2
pm2 start server.js --name bossauto-mock-api
pm2 save
pm2 startup  # Seguir instrucciones si es primera vez

# Verificar
pm2 status
curl http://localhost:3001/health
```

**Verificar:**
- [ ] PM2 muestra el proceso como "online"
- [ ] Health check responde con `{"status":"ok"}`
- [ ] No hay errores en logs: `pm2 logs bossauto-mock-api`

### 4️⃣ Configure nginx (3 min)

```bash
# En VPS
sudo cp /var/www/html/Automotive/deployment/nginx-automotive.conf \
        /etc/nginx/sites-available/automotive

sudo ln -s /etc/nginx/sites-available/automotive \
           /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

**Verificar:**
- [ ] `nginx -t` no muestra errores
- [ ] nginx reloaded exitosamente
- [ ] Health check público: `curl http://webscansearch.name/automotive/health`

### 5️⃣ Setup n8n (10 min)

```bash
# En VPS (si n8n no está instalado)
sudo npm install -g n8n

# Set environment variables
export N8N_HOST="0.0.0.0"
export N8N_PORT=5678
export WEBHOOK_URL="https://webscansearch.name"
export N8N_BASIC_AUTH_ACTIVE=true
export N8N_BASIC_AUTH_USER="admin"
export N8N_BASIC_AUTH_PASSWORD="YOUR_SECURE_PASSWORD"

# Start n8n
pm2 start n8n --name n8n -- start
pm2 save
```

**En Browser - Acceder a: `http://webscansearch.name:5678`**

1. **Login** con las credenciales configuradas

2. **Crear PostgreSQL Credential:**
   - Click en "Credentials" → "Add Credential"
   - Buscar "Postgres"
   - Name: `BossAuto PostgreSQL`
   - Host: `localhost`
   - Database: `bossauto`
   - User: `quantum`
   - Password: `[tu_password]`
   - Port: `5432`
   - SSL: `disable`
   - Click "Save"

3. **Importar Workflow:**
   - Click en "+" → "Import from File"
   - Nota: Necesitarás crear el workflow manualmente siguiendo `n8n-workflows/README.md`
   - O exportar uno existente y subirlo

4. **Activar Workflow:**
   - Toggle "Active" en ON
   - Verificar que el webhook esté visible

**Verificar:**
- [ ] n8n UI accesible
- [ ] Credential de PostgreSQL funciona (test connection)
- [ ] Workflow importado
- [ ] Workflow activado
- [ ] Webhook URL copiada

### 6️⃣ Test End-to-End (5 min)

```bash
# Test 1: Auto-approval
curl -X POST http://webscansearch.name/automotive/webhook/purchase-request \
  -H "Content-Type: application/json" \
  -d '{
    "purchase_request_id": "PR-DEPLOY-TEST-001",
    "requester": {"name": "Test User", "department": "Testing", "email": "test@company.com"},
    "items": [{"item_code": "TEST-001", "description": "Test", "quantity": 10, "unit_price": 50, "total": 500}],
    "total_amount": 500,
    "currency": "USD",
    "supplier": {"name": "Test Supplier", "code": "TEST"},
    "requested_date": "2025-01-28T10:00:00Z",
    "delivery_date": "2025-02-15"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "request_id": "PR-DEPLOY-TEST-001",
  "status": "approved",
  "approval_level": "auto",
  ...
}
```

**Verificar en Database:**
```bash
psql -U quantum -d bossauto -c "SELECT request_id, total_amount, status, approval_level FROM purchase_requests ORDER BY created_at DESC LIMIT 1;"
```

**Verificar:**
- [ ] Webhook responde exitosamente
- [ ] Datos guardados en database
- [ ] Mock API creó Purchase Order
- [ ] Logs muestran éxito: `pm2 logs n8n --lines 20`

### 7️⃣ Automated Test Suite (opcional)

```bash
# En tu Mac
cd /Users/alex/UpWork/Automotive/docs
./run-tests.sh
```

Esto ejecutará 7 tests automáticos cubriendo todos los escenarios.

**Verificar:**
- [ ] Todos los tests pasan
- [ ] Responses son correctas
- [ ] No hay errores en logs

## Post-Deployment

### ✅ Security (Producción)

- [ ] Cambiar password de PostgreSQL
- [ ] Cambiar password de n8n
- [ ] Habilitar HTTPS con Let's Encrypt: `sudo certbot --nginx`
- [ ] Configurar firewall: `sudo ufw enable`
- [ ] Agregar rate limiting a nginx

### ✅ Monitoring

```bash
# Check services status
pm2 status

# View logs
pm2 logs bossauto-mock-api --lines 50
pm2 logs n8n --lines 50

# Check nginx
sudo tail -f /var/log/nginx/automotive-access.log
sudo tail -f /var/log/nginx/automotive-error.log

# Check database
psql -U quantum -d bossauto -c "SELECT COUNT(*) FROM purchase_requests;"
```

### ✅ Create Video Demo

Seguir el script en `docs/VIDEO_SCRIPT.md`:

- [ ] Grabar intro (30s)
- [ ] Mostrar arquitectura (1 min)
- [ ] Tour n8n workflow (1.5 min)
- [ ] Demo en vivo (1 min)
- [ ] Verificar database (45s)
- [ ] Mostrar Mock API (45s)
- [ ] Explicar reglas (30s)
- [ ] Cierre (30s)

**Total: 5-7 minutos**

Upload to:
- [ ] YouTube (unlisted)
- [ ] Loom
- [ ] Google Drive

### ✅ Prepare Upwork Proposal

**Incluir en tu proposal:**

1. **Link al video demo** ✅

2. **URLs funcionando:**
   - Health Check: `http://webscansearch.name/automotive/health`
   - Webhook endpoint para testing

3. **Ejemplo de test:**
   ```bash
   curl -X POST http://webscansearch.name/automotive/webhook/purchase-request \
     -H "Content-Type: application/json" \
     -d @test-request.json
   ```

4. **Highlights técnicos:**
   - Motor de aprobaciones multinivel funcional
   - Integración con Mock Business Central API
   - PostgreSQL con schema completo
   - Sistema de notificaciones
   - Código documentado y deployable

5. **Tu experiencia:**
   - n8n: 3+ años
   - Business Central API
   - PostgreSQL, Node.js, DevOps
   - Metodologías ágiles

6. **Compromiso:**
   - Inicio inmediato
   - 196h @ $30/h = $5,880
   - Español fluido
   - Interés en long-term

## Troubleshooting

### Mock API no responde
```bash
pm2 restart bossauto-mock-api
pm2 logs bossauto-mock-api
curl http://localhost:3001/health
```

### PostgreSQL connection failed
```bash
sudo systemctl status postgresql
psql -U quantum -d bossauto -h localhost
# Check password in n8n credentials
```

### nginx 502 Bad Gateway
```bash
# Check if backend services are running
pm2 status
# Check nginx logs
sudo tail -f /var/log/nginx/automotive-error.log
# Restart nginx
sudo systemctl restart nginx
```

### n8n workflow not triggering
```bash
# Check workflow is active in UI
# Check webhook URL is correct
# Check nginx proxy config
# View n8n logs
pm2 logs n8n
```

## Success Criteria

✅ **Deployment is successful when:**

- [ ] Health check accessible: `http://webscansearch.name/automotive/health`
- [ ] Webhook accepting requests
- [ ] PostgreSQL storing data correctly
- [ ] Mock API creating Purchase Orders
- [ ] n8n workflow executing without errors
- [ ] All 7 test scenarios pass
- [ ] Logs show no errors
- [ ] Video demo recorded
- [ ] Upwork proposal ready

## Final Steps Before Proposal

1. [ ] Run full test suite: `./docs/run-tests.sh`
2. [ ] Verify all services: `pm2 status`
3. [ ] Check logs for errors: `pm2 logs`
4. [ ] Test from external network
5. [ ] Take screenshots/screen recording
6. [ ] Prepare demo credentials (if sharing access)
7. [ ] Write compelling cover letter
8. [ ] Submit proposal on Upwork! 🚀

---

## 🎯 You're Ready!

Con este PoC funcionando, demuestras:
- ✅ Capacidad técnica superior
- ✅ Experiencia real con el stack
- ✅ Proactividad y ownership
- ✅ Calidad de código y documentación
- ✅ Habilidad para deploy en producción

**¡Mucha suerte con la propuesta! 🚀**

---

**Notas:**
- Guarda las credenciales en un lugar seguro
- Haz backup de la database después del deployment
- Monitorea los logs durante las primeras horas
- Prepara respuestas para preguntas técnicas del cliente

**Support**: Si algo falla, revisa los logs primero: `pm2 logs`
