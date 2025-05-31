
# Use official Maven image with JDK 17
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy your uneditable source files
COPY Main.java AppController.java ./

# Set up Spring Boot project in a temp build dir
RUN mkdir -p build-temp/src/main/java/com/cyat/ecommerce \
    && mkdir -p build-temp/src/main/resources \
    && cp Main.java AppController.java build-temp/src/main/java/com/cyat/ecommerce/ \
    && echo '<project xmlns="http://maven.apache.org/POM/4.0.0" \
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"> \
        <modelVersion>4.0.0</modelVersion> \
        <parent> \
            <groupId>org.springframework.boot</groupId> \
            <artifactId>spring-boot-starter-parent</artifactId> \
            <version>3.2.5</version> \
            <relativePath/> \
        </parent> \
        <groupId>com.cyat</groupId> \
        <artifactId>ecommerce</artifactId> \
        <version>1.0-SNAPSHOT</version> \
        <packaging>jar</packaging> \
        <properties><java.version>17</java.version></properties> \
        <dependencies><dependency><groupId>org.springframework.boot</groupId> \
        <artifactId>spring-boot-starter-web</artifactId></dependency></dependencies> \
        <build><plugins><plugin><groupId>org.springframework.boot</groupId> \
        <artifactId>spring-boot-maven-plugin</artifactId></plugin></plugins></build> \
    </project>' > build-temp/pom.xml \
    && echo 'package com.cyat.ecommerce; \
    import org.springframework.boot.SpringApplication; \
    import org.springframework.boot.autoconfigure.SpringBootApplication; \
    @SpringBootApplication public class BootMain { \
    public static void main(String[] args) { SpringApplication.run(BootMain.class, args); }}' \
    > build-temp/src/main/java/com/cyat/ecommerce/BootMain.java \
    && echo 'server.address=0.0.0.0' > build-temp/src/main/resources/application.properties \
    && cd build-temp && mvn clean package

# --- Final image ---
FROM eclipse-temurin:17-jdk

WORKDIR /app

# Copy built jar from builder
COPY --from=builder /app/build-temp/target/ecommerce-1.0-SNAPSHOT.jar app.jar

EXPOSE 8080

# Run the Spring Boot app
ENTRYPOINT ["java", "-jar", "app.jar"]
