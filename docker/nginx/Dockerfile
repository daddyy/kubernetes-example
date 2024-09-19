FROM nginx:latest

### otázkou je jeslti není lepší použít rovnou shodný adresář a nedržet se konvence /var/www/... místo /app/ nebo cokoli jiného
COPY ./app/www/ /var/www/html/www
# pokud se jedná o jeden konkrétní projekt je jednodušší použít nginx conf rovnou,
# výhoda je nepotřeba inicializovat pro daný docker image proměnné pří spuštění / potažmo v docker filu
COPY ./docker/nginx/nginx.conf.template /etc/nginx/templates/default.conf.template

# uv rámci určítých vlastnosti je vhodné následovat použití adresářové struktury
COPY ./docker/nginx/bin/docker-nginx.sh /usr/local/bin/docker-nginx.sh
RUN chmod +x /usr/local/bin/docker-nginx.sh

# HEALTHCHECK --interval=10s --timeout=10s CMD /usr/local/bin/docker-nginx.sh || exit 1