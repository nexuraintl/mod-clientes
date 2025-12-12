# 1. Imagen base oficial de Nginx
FROM nginx:alpine

# 2. Copia el archivo de configuración de Nginx personalizado
# Este paso sobreescribe la configuración por defecto de Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# 3. Elimina la carpeta estática por defecto de Nginx
# Esto es para asegurar que solo servimos nuestros archivos.
RUN rm -rf /usr/share/nginx/html/*

# 4. Copia los archivos compilados de su frontend (asumiendo que están en /build)
# Reemplace 'build' si su herramienta usa 'dist' o 'out'.
COPY build/ /usr/share/nginx/html

# 5. Expone el puerto que Nginx está escuchando (8080, como se configuró en nginx.conf)
# Cloud Run usará esta información para enrutar el tráfico.
EXPOSE 8080

# 6. Comando por defecto para iniciar Nginx
CMD ["nginx", "-g", "daemon off;"]