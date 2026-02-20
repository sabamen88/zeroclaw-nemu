FROM node:20-slim
WORKDIR /app
COPY nemu/node-agent/package.json .
RUN npm install --production
COPY nemu/node-agent/server.mjs .
EXPOSE 3000
CMD ["node", "server.mjs"]
