# ms_web_clientes

Frontend estático del widget de chatbot para **clientes finales** de la plataforma NEXURA. Sirve las páginas HTML por tenant (empresa), cada una con el chatbot embebido configurado para la empresa correspondiente.

---

## Descripción

Aplicación web estática construida con **React** (Create React App), compilada y servida mediante **Nginx** sobre **Cloud Run**. No expone APIs propias — su función es entregar los artefactos estáticos del chatbot al navegador del cliente final.

Cada empresa cliente tiene su propia página HTML con el atributo `data-company` configurado con el ID de empresa correspondiente, lo que permite al chatbot cargar la configuración y personalización correcta.

---

## Stack

| Componente | Tecnología |
|---|---|
| Framework | React (Create React App) |
| Servidor web | Nginx Alpine |
| Contenedor | Docker |
| Compute | Cloud Run (GCP) |
| Puerto expuesto | 8080 |
| CI/CD | Azure DevOps → GitHub → Cloud Build |

---

## Páginas por tenant

| Archivo | Empresa | ID de empresa (`data-company`) |
|---|---|---|
| `index.html` | Default / Avanti | 1031 |
| `avanti.html` | Avanti IT | 1020 |
| `agn.html` | AGN | 1032 |
| `coomeva.html` | Coomeva | 1025 |
| `pereira.html` | Pereira | 1024 |
| `sfc.html` | SFC | 1023 |
| `ideam.html` | IDEAM | 1031 |
| `chatico.html` | Chatico (Avanti) | 1020 |
| `sfc-pruebas.html` | SFC (Pruebas) | — |

Cada página inicializa el widget con su `data-company` específico:

```html
<div data-company="1025" id="chatbot-avanti"></div>
```

---

## Estructura del repositorio

```
ms_web_clientes/
├── build/                    # Artefactos compilados (servidos por Nginx)
│   ├── index.html            # Página principal
│   ├── agn.html              # Página por tenant
│   ├── avanti.html
│   ├── coomeva.html
│   ├── ideam.html
│   ├── pereira.html
│   ├── sfc.html
│   ├── chatico.html
│   ├── sfc-pruebas.html
│   ├── assets/               # Imágenes y recursos estáticos
│   ├── static/
│   │   ├── css/              # Estilos compilados del chatbot
│   │   └── js/               # Bundles JS del chatbot
│   └── manifest.json
├── Dockerfile
├── nginx.conf
├── .azure-pipelines.yml
└── README.md
```

---

## Infraestructura y despliegue

### Arquitectura de ejecución

```
Navegador cliente
    │  HTTPS
    ▼
Cloud Load Balancer  (pre-mscloud.nexura.com.co)
    ▼
API Gateway ESPv2
    ▼
Cloud Run  (qam-web-clientes / prem-web-clientes)
    │  Nginx escuchando en :8080
    └── Sirve build/ como archivos estáticos
```

### Servidor web — nginx.conf

Nginx está configurado para:
- Escuchar en el puerto **8080** (requerido por Cloud Run).
- Servir el directorio `/usr/share/nginx/html` (contenido de `build/`).
- Fallback a `index.html` para rutas no encontradas (`try_files`).
- Caché de 30 días para assets estáticos (JS, CSS, imágenes, SVG).
- `server_tokens off` — no expone la versión de Nginx en headers.

### Dockerfile

```dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
RUN rm -rf /usr/share/nginx/html/*
COPY build/ /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

### Ramas y ambientes

| Rama | Ambiente | Trigger Cloud Build | Nombre Cloud Run |
|---|---|---|---|
| `qa` | QAM | Automático al push | `qam-web-clientes` |
| `master` | PREM | Automático al push | `prem-web-clientes` |
| `main` | PROD | Requiere aprobación | `prod-web-clientes` |

### Pipeline CI/CD

El archivo `.azure-pipelines.yml` sincroniza las ramas `dev`, `qa` y `master` desde Azure DevOps hacia el repositorio espejo en GitHub (`nexuraintl/ms_web_clientes`). Cloud Build detecta el push en GitHub y ejecuta la build + despliegue en Cloud Run.

**Requisito:** variable de pipeline `GITHUB_TOKEN_NEXURAINTL` configurada en ADO con scope `repo`.

---

## Ejecución local

```bash
# Build local
docker build -t ms-web-clientes:local .

# Ejecutar
docker run --rm -p 8080:8080 ms-web-clientes:local

# Verificar
curl http://localhost:8080/
# Abrir en el navegador: http://localhost:8080/coomeva.html
```

> No requiere variables de entorno — es un servidor de archivos estáticos puro.

---

## Agregar un nuevo tenant

1. Crear el archivo HTML en `build/` con el `data-company` correspondiente:
   ```html
   <!-- build/nuevo-cliente.html -->
   <!doctype html>
   <html lang="en">
   <head>
     <!-- copiar head de index.html -->
     <title>Cliente Web</title>
   </head>
   <body>
     <div data-company="XXXX" id="chatbot-avanti"></div>
     <!-- copiar scripts de index.html -->
   </body>
   </html>
   ```
2. Registrar el nuevo archivo en la tabla de tenants de este README.
3. Hacer push a `qa` para validar en QAM antes de promover a PREM y PROD.

---

## Dependencias externas

| Dependencia | Tipo | Descripción |
|---|---|---|
| Firebase Storage | CDN | Icono del avatar del chatbot (`firebasestorage.googleapis.com`) |
| `ms_ia_chatbot` | Microservicio backend | Lógica y respuestas del chatbot |
| Cloud Build | CI/CD | Build y despliegue de la imagen Docker |
| Artifact Registry | Registro | Almacenamiento de la imagen Docker |

---

## Responsable técnico

Santiago Valenzuela López — Equipo de Plataforma NEXURA