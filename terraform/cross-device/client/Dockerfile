FROM eclipse-temurin:17-jdk-jammy AS builder

WORKDIR /build
COPY . .
RUN ./gradlew clean bootJar

FROM eclipse-temurin:17-jre-jammy

WORKDIR /app
COPY --from=builder /build/build/libs/*.jar app.jar

RUN groupadd -r javauser && useradd -r -g javauser -u 10000 javauser
RUN chown -R javauser:javauser /app
USER javauser

ENV JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Xmx2g -Xms2g"

EXPOSE 8080
ENTRYPOINT ["java", "${JAVA_OPTS}", "-jar", "app.jar"]
