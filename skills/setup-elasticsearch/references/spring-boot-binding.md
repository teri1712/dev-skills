# Connecting Spring Boot to Elasticsearch

This document describes how to configure a Spring Boot application to connect to the Elasticsearch instance.

## 1. Dependency Management

Add the Spring Data Elasticsearch starter dependency to your `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-elasticsearch</artifactId>
</dependency>
```

Or for Gradle (`build.gradle`):

```groovy
implementation 'org.springframework.boot:spring-boot-starter-data-elasticsearch'
```

## 2. Spring Properties Configuration

In `application.yml` or `application.properties`, configure the connection details:

### Development Configuration (Security Disabled)
If security is disabled (like in our default local Docker Compose setup):

```yaml
spring:
  elasticsearch:
    uris: http://localhost:9200
    connection-timeout: 5s
    socket-timeout: 30s
```

### Production/Secured Configuration
If security is enabled and you are using username/password and SSL:

```yaml
spring:
  elasticsearch:
    uris: https://elasticsearch.default.svc.cluster.local:9200
    username: elastic
    password: ${ELASTICSEARCH_PASSWORD}
    connection-timeout: 5s
    socket-timeout: 30s
```

## 3. High-Level Rest Client Customization (Optional)

If you need to bypass SSL certification verification (e.g., self-signed certificates in dev or staging environments), you can configure a custom RestClient bean:

```java
import org.elasticsearch.client.RestClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.elasticsearch.client.ClientConfiguration;
import org.springframework.data.elasticsearch.client.elc.ElasticsearchConfiguration;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;

@Configuration
public class ElasticsearchConfig extends ElasticsearchConfiguration {

    @Override
    public ClientConfiguration clientConfiguration() {
        // Build trust-all SSL context if needed
        SSLContext sslContext = createTrustAllSslContext();

        return ClientConfiguration.builder()
                .connectedTo("localhost:9200")
                .usingSsl(sslContext) // Apply SSL configuration
                .withBasicAuth("elastic", "your_password")
                .build();
    }

    private SSLContext createTrustAllSslContext() {
        try {
            SSLContext sslContext = SSLContext.getInstance("TLS");
            sslContext.init(null, new TrustManager[]{new X509TrustManager() {
                public X509Certificate[] getAcceptedIssuers() { return null; }
                public void checkClientTrusted(X509Certificate[] certs, String authType) {}
                public void checkServerTrusted(X509Certificate[] certs, String authType) {}
            }}, new SecureRandom());
            return sslContext;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
```
