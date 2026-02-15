# ============================================================================
# Apache Fineract - Cloud Run Dockerfile
# ============================================================================
# Build strategy: Local Gradle build + slim JRE container
#
# Usage:
#   1. Build the JAR first:
#      ./gradlew :fineract-provider:bootJar -x test -x rat -x checkstyleMain
#   2. Build the Docker image:
#      docker buildx build --platform=linux/amd64 -t fineract-backend .
# ============================================================================

FROM azul/zulu-openjdk-alpine:21-jre

# Labels
LABEL maintainer="SECDEP Team"
LABEL description="Apache Fineract Backend for Cloud Run"

# Create non-root user
RUN addgroup -S fineract && adduser -S fineract -G fineract

# Set working directory
WORKDIR /app

# Copy the pre-built bootJar (copied to root to avoid .dockerignore exclusions)
COPY app.jar app.jar

# Cloud Run sends HTTP traffic to the container on $PORT (default 8080)
# We disable Fineract's built-in SSL since Cloud Run handles TLS termination
ENV SERVER_PORT=8080 \
    FINERACT_SERVER_SSL_ENABLED=false \
    JAVA_TOOL_OPTIONS="-Xmx512m -XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport -XX:+UseStringDeduplication --add-exports=java.naming/com.sun.jndi.ldap=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.security=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.management/javax.management=ALL-UNNAMED --add-opens=java.naming/javax.naming=ALL-UNNAMED"

EXPOSE 8080

# Healthcheck for Cloud Run
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/fineract-provider/actuator/health || exit 1

# Run as non-root
USER fineract

ENTRYPOINT ["java", "-jar", "app.jar"]
