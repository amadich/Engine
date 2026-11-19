package __PACKAGE__;

import java.time.Duration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthenticationConfiguration authentication;
    private final JwtService jwtService;
    private final AuthOptions options;

    public AuthController(AuthenticationConfiguration authentication, JwtService jwtService,
            AuthOptions options) {
        this.authentication = authentication;
        this.jwtService = jwtService;
        this.options = options;
    }

    @GetMapping("/csrf")
    public CsrfResponse csrf(CsrfToken token) {
        if (!options.useCookie())
            throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        return new CsrfResponse(token.getHeaderName(), token.getToken());
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) throws Exception {
        if (request.username() == null || request.password() == null)
            return ResponseEntity.badRequest().build();
        try {
            var verified = authentication.getAuthenticationManager().authenticate(
                UsernamePasswordAuthenticationToken.unauthenticated(request.username(), request.password()));
            String token = jwtService.createToken(verified.getName());
            if (options.useCookie())
                return ResponseEntity.noContent()
                    .header(HttpHeaders.SET_COOKIE, cookie(token, jwtService.ttlSeconds()).toString())
                    .build();
            return ResponseEntity.ok(new TokenResponse(token));
        } catch (AuthenticationException rejected) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout() {
        if (options.useCookie())
            return ResponseEntity.noContent()
                .header(HttpHeaders.SET_COOKIE, cookie("", 0).toString()).build();
        return ResponseEntity.noContent().build();
    }

    private ResponseCookie cookie(String value, long maxAge) {
        return ResponseCookie.from(JwtRequestResolver.COOKIE_NAME, value)
            .httpOnly(true).secure(options.secure()).sameSite("Strict")
            .path("/").maxAge(Duration.ofSeconds(maxAge)).build();
    }

    public record LoginRequest(String username, String password) {}
    public record TokenResponse(String accessToken) {}
    public record CsrfResponse(String headerName, String token) {}
}
