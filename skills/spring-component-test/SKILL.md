---
name: spring-component-test
description: Pattern for building a modular, dataset-driven integration testing infrastructure in Spring Boot. Use when setting up @ComponentTest meta-annotations, TestDataset lifecycles, and Testcontainers.
---

# Spring Component Testing Infrastructure

This pattern enables isolated, declarative integration testing with automatic dataset management.

## Core Infrastructure

### 1. TestDataset Interface
Define a contract for test data setup and cleanup.

```java
public interface TestDataset {
    default void clean() {}
    default void setup() {}
}
```

### 2. Dataset Import Selector
Dynamically imports the dataset beans specified in the annotation.

```java
public class DatasetImportSelector implements ImportSelector {
    @Override
    public String[] selectImports(AnnotationMetadata metadata) {
        AnnotationAttributes attributes = AnnotationAttributes.fromMap(
            metadata.getAnnotationAttributes(ComponentTest.class.getName()));
        if (attributes != null && attributes.containsKey("datasets")) {
            return Arrays.stream(attributes.getClassArray("datasets"))
                .map(Class::getName).toArray(String[]::new);
        }
        return new String[0];
    }
}
```

### 3. Dataset Test Execution Listener
Handles the lifecycle calls to `setup()` and `clean()`.

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
        ComponentTest annotation = MergedAnnotations.from(testContext.getTestClass())
            .get(ComponentTest.class).synthesize();
        ApplicationContext context = testContext.getApplicationContext();
        return Arrays.stream(annotation.datasets())
            .map(context::getBean).toList();
    }
}
```

### 4. @ComponentTest Annotation
Meta-annotation to bundle everything together.

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@SpringBootTest
@ActiveProfiles("test")
@Import({Containers.class, DatasetImportSelector.class})
@AutoConfigureMockMvc
@TestExecutionListeners(
    listeners = DatasetTestExecutionListener.class,
    mergeMode = TestExecutionListeners.MergeMode.MERGE_WITH_DEFAULTS
)
public @interface ComponentTest {
    Class<? extends TestDataset>[] datasets() default {};
}
```

## Usage

### 1. Define a Dataset
Implement `TestDataset` and annotate with `@TestComponent`.

```java
@TestComponent
@RequiredArgsConstructor
public class UserDataset implements TestDataset {
    private final UserRepository repository;

    @Override
    public void setup() {
        repository.save(new User("test-user"));
    }

    @Override
    public void clean() {
        repository.deleteAll();
    }
}
```

### 2. Use in Test
Annotate your test class with `@ComponentTest` and specify required datasets.

```java
@ComponentTest(datasets = {UserDataset.class})
class UserIntegrationTest {
    @Test
    void shouldFindUser() {
        // UserDataset.setup() was called automatically
    }
}
```

## Best Practices
- **Isolation**: Use `Testcontainers` in a `Containers.java` class imported by `@ComponentTest`.
- **Cleanup**: Always implement `clean()` to ensure test independence.
- **Profiles**: Use a dedicated `application-test.yaml` via `@ActiveProfiles("test")`.
