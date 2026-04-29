# Single container full-stack production Docker
FROM node:20-alpine as frontend-build
WORKDIR /frontend
COPY app/frontend/package*.json ./
COPY app/frontend/ ./
RUN npm ci && npm run build -- --mode production

FROM node:20-alpine
RUN apk add --no-cache nginx sqlite

WORKDIR /app
COPY app/backend/package*.json ./backend/
RUN cd backend && npm ci --only=production && cd ..

COPY app/backend ./backend
COPY --from=frontend-build /frontend/dist ./public

COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
VOLUME ["/app/backend/data"]

CMD ["sh", "-c", "nginx -g 'daemon off;' & node backend/src/index.js"]

