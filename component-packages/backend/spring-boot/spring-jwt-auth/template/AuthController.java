package __PACKAGE__;

import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthenticationConfiguration authentication;
    private final JwtService jwtService;

    public AuthController(AuthenticationConfiguration authentication, JwtService jwtService) {
        this.authentication = authentication;
        this.jwtService = jwtService;
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@RequestBody LoginRequest request) throws Exception {
        var verified = authentication.getAuthenticationManager().authenticate(
            new UsernamePasswordAuthenticationToken(request.username(), request.password()));
        return ResponseEntity.ok(new TokenResponse(jwtService.createToken(verified.getName())));
    }

    public record LoginRequest(String username, String password) {}
    public record TokenResponse(String accessToken) {}
}
