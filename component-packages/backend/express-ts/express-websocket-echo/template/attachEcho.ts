import type { Server } from "node:http";
import { WebSocketServer } from "ws";
import settings from "./settings.json" with { type: "json" };

export function attachEcho(server: Server) {
  const sockets = new WebSocketServer({ noServer: true, maxPayload: settings.max_bytes });
  server.on("upgrade", (request, socket, head) => {
    if (request.url?.split("?")[0] !== settings.path) {
      if (server.listenerCount("upgrade") === 1) socket.destroy();
      return;
    }
    if (request.headers.origin !== settings.allowed_origin) {
      socket.end("HTTP/1.1 403 Forbidden\r\nConnection: close\r\n\r\n");
      return;
    }
    sockets.handleUpgrade(request, socket, head, connection => sockets.emit("connection", connection));
  });

  sockets.on("connection", connection => {
    connection.on("error", () => connection.terminate());
    connection.on("message", (data, binary) => {
      if (binary) {
        connection.close(1003, "Text messages only");
        return;
      }
      if (connection.bufferedAmount > settings.max_bytes * 4) {
        connection.close(1013, "Backpressure");
        return;
      }
      connection.send(data.toString());
    });
  });
  return sockets;
}
