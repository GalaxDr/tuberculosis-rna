# Stage 1: Build the application
FROM eclipse-temurin:17-jdk-focal AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper and pom.xml first to leverage Docker cache
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Copy the 'lib' directory containing your custom JARs
# This is crucial for your ADReNA_API.jar and gson-2.2.4.jar
COPY lib lib/

# --- NOVO PASSO: Instalar JARs locais no repositório Maven do contêiner ---
# Isso garante que o Maven os encontre como dependências normais
# Removido '-DlocalRepositoryPath=./.m2/repository' para que Maven use o local padrão.
RUN chmod +x mvnw \
    && ./mvnw install:install-file \
       -Dfile=./lib/ADReNA_API.jar \
       -DgroupId=ADReNA_API \
       -DartifactId=ADReNA_API \
       -Dversion=1.0 \
       -Dpackaging=jar \
    && ./mvnw install:install-file \
       -Dfile=./lib/gson-2.2.4.jar \
       -DgroupId=com.google.code.gson \
       -DartifactId=gson \
       -Dversion=2.2.4 \
       -Dpackaging=jar
# -------------------------------------------------------------------------

# Copy the rest of your application source code
COPY src src/

# Build the application using Maven
# Agora, o Maven encontrará ADReNA_API e gson no seu repositório local
RUN chmod +x mvnw \
    && ./mvnw -DoutputFile=target/mvn-dependency-list.log -B -DskipTests clean dependency:list install

# Stage 2: Create the final runtime image
FROM eclipse-temurin:17-jre-focal

# Set the working directory
WORKDIR /app

# Copy the built JAR from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Expose the port your Spring Boot application runs on (default is 8080)
EXPOSE 8080

# Define the command to run your application
ENTRYPOINT ["java", "-Dserver.port=8080", "-jar", "app.jar"]
# Se precisar usar a variável de ambiente $PORT, altere para:
# ENTRYPOINT ["java", "-Dserver.port=${PORT:-8080}", "-jar", "app.jar"]
# A sintaxe ${PORT:-8080} significa usar $PORT se definida, caso contrário, usar 8080
