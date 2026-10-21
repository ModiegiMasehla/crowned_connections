package za.co.crownedconnections;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.OffsetDateTime;
import java.util.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

class ApiControllerTests {
  private JdbcTemplate db;
  private PasswordEncoder passwords;
  private ApiController api;
  private final String secret = "test-only-secret-with-at-least-thirty-two-bytes";

  @BeforeEach
  void setup() {
    db = mock(JdbcTemplate.class);
    passwords = mock(PasswordEncoder.class);
    api = new ApiController(db, passwords);
    ReflectionTestUtils.setField(api, "jwtSecret", secret);
  }

  private void bad(Runnable action) {
    assertEquals(
        400, assertThrows(ResponseStatusException.class, action::run).getStatusCode().value());
  }

  @Test
  void rejectsNonFiniteRadiusBeforeQueryingDatabase() {
    bad(() -> api.search(null, null, null, Double.NaN, null, null, null));
    bad(() -> api.search(null, null, null, Double.POSITIVE_INFINITY, null, null, null));
    verifyNoInteractions(db);
  }

  @Test
  void rejectsInvalidCoordinatesAndFilters() {
    bad(() -> api.search(null, 91.0, 28.0, 10, null, null, null));
    bad(() -> api.search(null, 0.0, Double.NaN, 10, null, null, null));
    bad(() -> api.search(null, 0.0, null, 10, null, null, null));
    bad(() -> api.search(null, null, null, 10, 500, 100, null));
    bad(() -> api.search(null, null, null, 10, -1, null, null));
    bad(() -> api.search(null, null, null, 10, null, null, 5.1));
    verifyNoInteractions(db);
  }

  @Test
  void preservesPasswordWhitespace() {
    var user =
        new HashMap<String, Object>(
            Map.of(
                "id",
                UUID.randomUUID(),
                "role",
                "CUSTOMER",
                "email",
                "a@b.co",
                "password_hash",
                "hash"));
    when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(user));
    when(passwords.matches("  Password123!  ", "hash")).thenReturn(true);
    assertNotNull(
        api.login(Map.of("email", "a@b.co", "password", "  Password123!  ")).get("token"));
    verify(passwords).matches("  Password123!  ", "hash");
  }

  @Test
  void rejectsNonStringIdentityAndOverlongBcryptPassword() {
    bad(
        () ->
            api.register(
                Map.of(
                    "email", 12, "password", "Password123!", "firstName", "A", "lastName", "B")));
    bad(
        () ->
            api.register(
                Map.of(
                    "email",
                    "a@b.co",
                    "password",
                    "é".repeat(37),
                    "firstName",
                    "A",
                    "lastName",
                    "B")));
    verifyNoInteractions(db, passwords);
  }

  @Test
  void checksMidnightInSalonTimezone() {
    var start = OffsetDateTime.parse("2030-10-20T21:30:00Z");
    assertEquals(
        409,
        assertThrows(
                ResponseStatusException.class,
                () -> ApiController.validateBookingDay(start, start.plusHours(2)))
            .getStatusCode()
            .value());
    assertDoesNotThrow(() -> ApiController.validateBookingDay(start, start.plusMinutes(15)));
  }

  private MockHttpServletRequest owner() {
    UUID id = UUID.randomUUID();
    var request = new MockHttpServletRequest();
    request.addHeader(
        "Authorization",
        "Bearer "
            + Jwts.builder()
                .subject(id.toString())
                .signWith(Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8)))
                .compact());
    when(db.queryForList(anyString(), any(Object[].class)))
        .thenReturn(List.of(new HashMap<>(Map.of("id", id, "role", "SALON_OWNER"))));
    return request;
  }

  @Test
  void rejectsFractionalAndOverflowingServiceNumbers() {
    var request = owner();
    bad(
        () ->
            api.createService(
                request, Map.of("name", "Cut", "durationMinutes", 15.5, "priceCents", 100)));
    bad(
        () ->
            api.createService(
                request, Map.of("name", "Cut", "durationMinutes", 30, "priceCents", 4294967296L)));
    verify(db, never()).update(anyString(), any(Object[].class));
  }

  @Test
  void rejectsOverlappingWorkingIntervalsBeforeDeletion() {
    var request = owner();
    bad(
        () ->
            api.setAvailability(
                request,
                UUID.randomUUID(),
                List.of(
                    Map.of("weekday", 1, "startLocal", "08:00", "endLocal", "12:00"),
                    Map.of("weekday", 1, "startLocal", "11:00", "endLocal", "17:00"))));
    verify(db, never()).update(anyString(), any(Object[].class));
  }
}
