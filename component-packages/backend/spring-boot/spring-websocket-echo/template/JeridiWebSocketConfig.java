package __PACKAGE__;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Configuration
@EnableWebSocket
public class JeridiWebSocketConfig implements WebSocketConfigurer {
    @Value("${jeridi.websocket.path:/ws}")
    private String path;

    @Value("${jeridi.websocket.origin:http://127.0.0.1:3000}")
    private String origin;

    @Value("${jeridi.websocket.limit:4096}")
    private int limit;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(new TextWebSocketHandler() {
            @Override
            public void afterConnectionEstablished(WebSocketSession session) {
                session.setTextMessageSizeLimit(limit);
            }

            @Override
            protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
                if (message.getPayloadLength() > limit) {
                    session.close(CloseStatus.TOO_BIG_TO_PROCESS);
                    return;
                }
                session.sendMessage(new TextMessage(message.getPayload()));
            }
        }, path).setAllowedOrigins(origin);
    }
}
