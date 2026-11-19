package __PACKAGE__;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public record AuthOptions(boolean useCookie, boolean secure) {
    public AuthOptions(
            @Value("${jeridi.auth.cookie:false}") boolean useCookie,
            @Value("${jeridi.auth.cookie-secure:true}") boolean secure) {
        this.useCookie = useCookie;
        this.secure = secure;
    }
}
