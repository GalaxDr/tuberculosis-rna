# Stage 1: Build the application
FROM eclipse-temurin:17-jdk-focal AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper and pom.xml first to leverage Docker cache
# This means if only source code changes, Maven dependencies won't be re-downloaded
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Copy the 'lib' directory containing your custom JARs
# This is crucial for your ADReNA_API.jar and gson-2.2.4.jar
COPY lib lib/

# Copy the rest of your application source code
COPY src src/

# Build the application using Maven
# The 'install' goal will package your application into a JAR
# -DskipTests: Skips running tests to speed up the build (remove if you want tests to run)
# -DoutputFile=target/mvn-dependency-list.log: For Nixpacks compatibility, though not strictly needed here
RUN chmod +x mvnw \
    && ./mvnw -DoutputFile=target/mvn-dependency-list.log -B -DskipTests clean dependency:list install

# Stage 2: Create the final runtime image
FROM eclipse-temurin:17-jre-focal

# Set the working directory
WORKDIR /app

# Copy the built JAR from the builder stage
# The 'repackage' goal of the Spring Boot Maven plugin creates an executable JAR
# The name might vary slightly, so we use a wildcard
COPY --from=builder /app/target/*.jar app.jar

# Expose the port your Spring Boot application runs on (default is 8080)
EXPOSE 8080

# Define the command to run your application
# The $PORT environment variable will be provided by your deployment environment (e.g., Nixpacks, Kubernetes)
ENTRYPOINT ["java", "-Dserver.port=${PORT:-8080}", "-jar", "app.jar"]
# If you need to use $PORT from the environment, change the above to:
# ENTRYPOINT ["java", "-Dserver.port=${PORT:-8080}", "-jar", "app.jar"]
# The ${PORT:-8080} syntax means use $PORT if set, otherwise default to 8080
