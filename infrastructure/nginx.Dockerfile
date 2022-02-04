FROM nginx:latest

ARG LOCAL

RUN rm -rf /usr/share/nginx/html/*
RUN apt update --yes
RUN apt install --yes certbot python3-certbot-nginx

ADD infrastructure/nginx/nginx.conf /etc/nginx/nginx.conf

ENTRYPOINT [ "nginx", "-g", "daemon off;" ]