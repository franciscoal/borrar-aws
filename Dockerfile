# ** Partimos de esta base
FROM node:18-alpine AS base

# Crear app directory, y lo uso como working directory
RUN mkdir -p /usr/app
WORKDIR /usr/app

# ** Build de front partimos de base pero creamos la fase front-build
FROM base AS front-build
COPY ./front ./
RUN  npm ci
RUN npm run build

# ** Build de back partimos de base pero creamos la fase back-build
FROM base as back-build
# Copia backend al raíz workdir (/usr/app)
COPY ./back ./

# Hacemos el install y el build
RUN npm ci
RUN npm run build

# ** Fase Release, juntamos las piezas de las distintas fase
FROM base AS release
COPY --from=front-build /usr/app/dist ./public
COPY --from=back-build /usr/app/dist ./
COPY ./back/package.json ./

# Actualizamos las rutas del package.json para que apunten a dist
RUN apk update && apk add jq
RUN updatedImports="$(jq '.imports[]|=sub("./src"; ".")' ./package.json)" && echo "${updatedImports}" > ./package.json
COPY ./back/package-lock.json ./
RUN npm ci --only=production

# saludos
# Le indicamos variables de entorno (OJO sensibles NO)

ENV STATIC_FILES_PATH=./public
ENV API_MOCK=true
ENV AUTH_SECRET=MY_AUTH_SECRET


# Ejecutamos al aplicación (OJO CMD no lo hacemos con RUN)
CMD node index
