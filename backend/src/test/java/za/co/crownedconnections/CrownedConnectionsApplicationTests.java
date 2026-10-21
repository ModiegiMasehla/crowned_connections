package za.co.crownedconnections;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class CrownedConnectionsApplicationTests {
  @Test
  void applicationClassIsPresent() {
    assertNotNull(CrownedConnectionsApplication.class);
  }

  @Test
  void southAfricanTimezoneIsAvailable() {
    assertEquals("Africa/Johannesburg", java.time.ZoneId.of("Africa/Johannesburg").getId());
  }
}
