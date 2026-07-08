---
name: spring-component-test
description: Comprehensive pattern for modular, dataset-driven integration testing in Spring Boot. Includes @ComponentTest meta-annotation, TestDataset lifecycles, and Testcontainers setup.
---

# Spring Component Testing Infrastructure

This pattern enables isolated, declarative integration testing with automatic dataset management. It uses meta-annotations to bundle common test configurations and provides a lifecycle for test data.

All infrastructure classes below live in `com.decade.nexa.kernel` (test scope), mirroring the `kernel` module under `src/main/java/com/decade/nexa/kernel` (formerly `common`, renamed as part of the kernel migration).

## Prerequisites

Add these dependencies to your `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-testcontainers</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>
<!-- Required: ComponentTest is an @ApplicationModuleTest -->
<dependency>
    <groupId>org.springframework.modulith</groupId>
    <artifactId>spring-modulith-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

## 1. Test Containers Infrastructure

`com.decade.nexa.kernel.Containers` manages shared Testcontainers plus WireMock servers for external sidecars. Add a `@Bean`/`@ServiceConnection` per real dependency, and a `WireMockServer` + `DynamicPropertyRegistrar` pair for any HTTP-based external service (OpenAI, the graph sidecar, etc.):

```java
@Slf4j
@TestConfiguration
public class Containers {

    @Bean
    @ServiceConnection
    PostgreSQLContainer<?> postgres() {
        return new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("mydatabase")
            .withUsername("myuser")
            .withPassword("secret");
    }

    @Bean
    @ServiceConnection
    ElasticsearchContainer elasticsearch() {
        return new ElasticsearchContainer("docker.elastic.co/elasticsearch/elasticsearch:8.17.0")
            .withEnv("discovery.type", "single-node")
            .withEnv("xpack.security.enabled", "false");
    }

    @Bean
    MinIOContainer minioContainer() {
        return new MinIOContainer("minio/minio:RELEASE.2023-09-04T19-57-37Z")
            .withUserName("decadedecade")
            .withPassword("decadedecade");
    }

    @Bean
    DynamicPropertyRegistrar awsProperties(MinIOContainer minIO) {
        return registry -> {
            registry.add("aws.s3.endpoint", minIO::getS3URL);
            registry.add("aws.s3.bucket", () -> "test-bucket");
            registry.add("aws.s3.access.id", minIO::getUserName);
            registry.add("aws.s3.access.secret", minIO::getPassword);
        };
    }

    // HTTP-based sidecar: WireMock server + DynamicPropertyRegistrar instead of a Testcontainer
    @Bean(initMethod = "start", destroyMethod = "stop")
    WireMockServer openAiWireMockServer() {
        return new WireMockServer(WireMockConfiguration.wireMockConfig().dynamicPort());
    }

    @Bean
    DynamicPropertyRegistrar openAiProperties(WireMockServer openAiWireMockServer) {
        return registry -> {
            registry.add("spring.ai.openai.base-url", () -> "http://localhost:" + openAiWireMockServer.port());
            registry.add("spring.ai.openai.api-key", () -> "test-key");
        };
    }
}
```

`BaseTestClass` (the pre-`@ComponentTest` legacy base class, still present for reference) autowires `List<WireMockServer>` and calls `resetAll()` after each test — do the same in new dataset/listener code if WireMock stubs leak state between tests.

## 2. Dataset Management Contract

### TestDataset.java
Datasets are themselves Spring test components (`@TestComponent`), not just plain interfaces:

```java
@TestComponent
public interface TestDataset {
    default void clean() {} // Called after each test method
    default void setup() {} // Called before each test method
}
```

## 3. Orchestration Logic

### DatasetImportSelector.java
Ensures the datasets passed to the annotation are registered as Spring beans.

```java
public class DatasetImportSelector implements ImportSelector {
    @Override
    public String[] selectImports(AnnotationMetadata metadata) {
        var attributes = AnnotationAttributes.fromMap(
            metadata.getAnnotationAttributes(ComponentTest.class.getName()));
        if (attributes != null && attributes.containsKey("datasets")) {
            return Arrays.stream(attributes.getClassArray("datasets"))
                .map(Class::getName).toArray(String[]::new);
        }
        return new String[0];
    }
}
```

### DatasetTestExecutionListener.java
Hooks into the JUnit lifecycle to call `setup()` and `clean()`. Use `TYPE_HIERARCHY` search strategy so subclasses of a `@ComponentTest`-annotated base pick up the datasets too:

```java
public class DatasetTestExecutionListener extends AbstractTestExecutionListener {
    @Override
    public void beforeTestMethod(TestContext testContext) {
        getDatasets(testContext).forEach(TestDataset::setup);
    }

    @Override
    public void afterTestMethod(TestContext testContext) {
        getDatasets(testContext).forEach(TestDataset::clean);
    }

    private List<TestDataset> getDatasets(TestContext testContext) {
        ComponentTest annotation = MergedAnnotations
            .from(testContext.getTestClass(), MergedAnnotations.SearchStrategy.TYPE_HIERARCHY)
            .get(ComponentTest.class).synthesize();
        if (annotation == null) return List.of();
        ApplicationContext context = testContext.getApplicationContext();
        return Arrays.stream(annotation.datasets())
            .map(context::getBean).toList();
    }
}
```

## 4. The @ComponentTest Meta-Annotation

Bundles the module test scope, container setup, import logic, and execution listener. This project uses `@ApplicationModuleTest` (Spring Modulith) instead of a plain `@SpringBootTest`, so each component test is scoped to its owning module plus `kernel`:

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@ApplicationModuleTest(extraIncludes = "kernel")
@TestConstructor(autowireMode = TestConstructor.AutowireMode.ALL)
@ActiveProfiles({"test", "openai"})
@Import({Containers.class, AIEvalutationConfig.class, DatasetImportSelector.class})
@AutoConfigureMockMvc
@TestExecutionListeners(
    listeners = DatasetTestExecutionListener.class,
    mergeMode = TestExecutionListeners.MergeMode.MERGE_WITH_DEFAULTS
)
public @interface ComponentTest {
    Class<? extends TestDataset>[] datasets() default {};
}
```

Notes on the extra elements vs. a minimal `@SpringBootTest`-based version:
- `@ApplicationModuleTest(extraIncludes = "kernel")` boots only the annotated test's module plus `kernel`, keeping each component test's context small and modules verifiably decoupled (Spring Modulith).
- `@Documented @Inherited` let a shared abstract test base carry `@ComponentTest` and have subclasses inherit it — required for `TYPE_HIERARCHY` lookup in the listener to matter.
- `@TestConstructor(autowireMode = ALL)` allows constructor injection in test classes without `@Autowired` on every field.
- `@ActiveProfiles({"test", "openai"})` activates the `openai` profile alongside `test` so AI-related beans (`AIEvalutationConfig`, the OpenAI WireMock wiring) resolve correctly.
- `AIEvalutationConfig` (also under `kernel`) supplies AI-evaluation beans (e.g. `RelevancyEvaluator`) used by tests that assert on LLM output quality; only import it if your module touches AI features.

## 5. Usage Example

### Implementation
Datasets typically wrap real repositories and only need `clean()` — `setup()` is often unnecessary because seeding happens via the API/adapter under test:

```java
@TestComponent
@RequiredArgsConstructor
public class DocumentDataset implements TestDataset {
    private final DocumentRepository docs;
    private final InsightRepository insights;

    @Override
    public void clean() {
        docs.deleteAll(RefreshPolicy.IMMEDIATE);
        insights.deleteAll(RefreshPolicy.IMMEDIATE);
    }
}
```

### In a Test Class
```java
@ComponentTest(datasets = {DocumentDataset.class})
class DocumentApiTest {
    @Autowired MockMvc mockMvc;

    @Test
    void shouldFindDocument() {
        mockMvc.perform(get("/documents/1")).andExpect(status().isOk());
    }
}
```

## Best Practices
- **Parallelism**: Using `ServiceConnection` and shared beans in `Containers.java` optimizes resource usage.
- **Dynamic Port Injection**: Use `DynamicPropertyRegistrar` for services that don't support `@ServiceConnection` (Testcontainers) or that are HTTP sidecars backed by WireMock.
- **Selective Datasets**: Only import the datasets required for the specific test to keep context small.
- **Module scoping**: Prefer `@ApplicationModuleTest(extraIncludes = "kernel")` over a bare `@SpringBootTest` so tests stay scoped to their module and don't silently depend on unrelated modules.
- **WireMock hygiene**: Reset WireMock servers (`resetAll()`) between tests — either in a shared listener or an `@AfterEach` in a base test class — so stubs from one test don't leak into the next.
