# Testcontainers Setup for Elasticsearch (Nexa Project Pattern)

This reference document outlines the exact Testcontainers setup used for Elasticsearch in the Nexa project.

## 1. Test Dependencies (`pom.xml`)

The project uses the following dependencies in `pom.xml` to support Elasticsearch integration testing:

```xml
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>elasticsearch</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>
```

## 2. Test Configuration (`Containers.java`)

Instead of manual initialization per test class, the project defines a centralized `@TestConfiguration` class at `com.decade.nexa.common.Containers` that manages a shared `ElasticsearchContainer`:

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

- `@ServiceConnection` automatically discovers and binds properties for Spring Data and Spring AI vector store configurations (such as `spring.elasticsearch.uris`).
- The Elasticsearch container uses version `8.17.0` with disabled security (`xpack.security.enabled=false`) to simplify local test validation.

## 3. Integration Testing with `@ComponentTest`

The project does not use bare `@SpringBootTest` annotations. Instead, integration tests utilize the custom meta-annotation `com.decade.nexa.common.ComponentTest`, which imports `Containers.class`:

```java
package com.decade.nexa.common;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

// ...
@SpringBootTest
@ActiveProfiles({"test", "openai"})
@Import({Containers.class, AIEvalutationConfig.class, DatasetImportSelector.class})
public @interface ComponentTest {
    Class<? extends TestDataset>[] datasets() default {};
}
```

To run a test with Elasticsearch active, simply annotate the test class with `@ComponentTest`:

```java
package com.decade.nexa.documents;

import com.decade.nexa.common.ComponentTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;

import static org.assertj.core.api.Assertions.assertThat;

@ComponentTest
class DocumentSearchTest {

    @Autowired
    private ElasticsearchOperations esOperations;

    @Test
    void shouldConnectToElasticsearch() {
        assertThat(esOperations).isNotNull();
    }
}
```
