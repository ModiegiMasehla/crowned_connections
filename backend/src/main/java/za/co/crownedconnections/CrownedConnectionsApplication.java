package za.co.crownedconnections;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@SpringBootApplication
public class CrownedConnectionsApplication {
    public static void main(String[] args) { SpringApplication.run(CrownedConnectionsApplication.class, args); }
    @Bean PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(12); }
    @Bean WebMvcConfigurer corsConfigurer() { return new WebMvcConfigurer() {
        @Override public void addCorsMappings(CorsRegistry registry) { registry.addMapping("/**").allowedOriginPatterns("*").allowedMethods("GET","POST","PUT","DELETE","OPTIONS").allowedHeaders("*"); }
    }; }
}
