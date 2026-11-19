package __PACKAGE__;

import java.time.Instant;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
    private final JwtEncoder encoder;

    private final long ttlSeconds;

    public JwtService(JwtEncoder encoder, @Value("${jeridi.auth.ttl-seconds:3600}") long ttlSeconds) {
        if (ttlSeconds < 60 || ttlSeconds > 86400)
            throw new IllegalArgumentException("jeridi.auth.ttl-seconds must be between 60 and 86400");
        this.ttlSeconds = ttlSeconds;
        this.encoder = encoder;
    }

    public long ttlSeconds() { return ttlSeconds; }

    public String createToken(String subject) {
        Instant now = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
            .issuer("jeridi-engine")
            .subject(subject)
            .issuedAt(now)
            .expiresAt(now.plusSeconds(ttlSeconds))
            .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        return encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }
}
