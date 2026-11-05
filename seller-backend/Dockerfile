# Build stage: compile the Spring Boot jar inside the image so Render does not
# need a prebuilt target/ directory.
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml .
RUN mvn -B -q -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -B -DskipTests clean package

# Runtime stage: small JRE image.
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

COPY --from=build /app/target/backend-1.0.0.jar app.jar

EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
