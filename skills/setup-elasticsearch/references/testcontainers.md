# Testcontainers Setup for Elasticsearch

This reference provides instructions and templates for setting up Elasticsearch in integration tests using Testcontainers in a Spring Boot application.

## 1. Maven / Gradle Dependencies

Ensure that the required Testcontainers dependencies are present in your build configuration.

### Maven (`pom.xml`)
```xml
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>elasticsearch</artifactId>
    <scope>test</scope>
</dependency>
```

### Gradle (`build.gradle`)
```groovy
testImplementation "org.testcontainers:elasticsearch"
```

---

## 2. Test Configuration with Spring Boot 3.1+ Connection Details

Spring Boot 3.1 introduced `@ServiceConnection` which automatically configures connection details for Testcontainers-managed services without manual dynamic property registration.

### Containers Configuration (`Containers.java`)

Create a test configuration class (e.g., `com.decade.nexa.common.Containers`) to manage your containers:

```java
package com.decade.nexa.common;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.elasticsearch.ElasticsearchContainer;

@TestConfiguration
public class Containers {

    @Bean
    @ServiceConnection
    ElasticsearchContainer elasticsearch() {
        return new ElasticsearchContainer(
            "docker.elastic.co/elasticsearch/elasticsearch:8.17.0"
        )
            .withEnv("discovery.type", "single-node")
            .withEnv("xpack.security.enabled", "false");
    }
}
```

---

## 3. Using the Test Configuration in Integration Tests

Annotate your integration tests with `@Import(Containers.class)` to spin up Elasticsearch for the duration of the tests.

```java
package com.decade.nexa.documents;

import com.decade.nexa.common.Containers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Import(Containers.class)
class ElasticsearchIntegrationTest {

    @Autowired
    private ElasticsearchOperations esOperations;

    @Test
    void testConnection() {
        assertThat(esOperations).isNotNull();
        // Perform search, insert or check index here
    }
}
```
