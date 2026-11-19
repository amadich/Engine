package __PACKAGE__;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.oauth2.server.resource.web.BearerTokenResolver;
import org.springframework.security.oauth2.server.resource.web.DefaultBearerTokenResolver;
import org.springframework.stereotype.Component;

@Component
public class JwtRequestResolver implements BearerTokenResolver {
    static final String COOKIE_NAME = "jeridi_access";

    private final AuthOptions options;
    private final DefaultBearerTokenResolver bearer = new DefaultBearerTokenResolver();

    public JwtRequestResolver(AuthOptions options) {
        this.options = options;
    }

    @Override
    public String resolve(HttpServletRequest request) {
        if (!options.useCookie())
            return bearer.resolve(request);
        var cookies = request.getCookies();
        if (cookies != null) {
            for (var cookie : cookies) {
                if (COOKIE_NAME.equals(cookie.getName()))
                    return cookie.getValue();
            }
        }
        return null;
    }
}
