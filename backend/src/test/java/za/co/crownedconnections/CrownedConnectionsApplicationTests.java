package za.co.crownedconnections;
import org.junit.jupiter.api.Test;
import za.co.crownedconnections.CrownedConnectionsApplication;

import static org.junit.jupiter.api.Assertions.*;
class CrownedConnectionsApplicationTests {
 @Test void applicationClassIsPresent(){ assertNotNull(CrownedConnectionsApplication.class); }
 @Test void southAfricanTimezoneIsAvailable(){ assertEquals("Africa/Johannesburg", java.time.ZoneId.of("Africa/Johannesburg").getId()); }
}
