package __PACKAGE__;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GreetingController {
    @GetMapping("/api/greeting")
    public Map<String, String> greeting() {
        return Map.of("message", "Hello from Jeridi Engine");
    }
}
