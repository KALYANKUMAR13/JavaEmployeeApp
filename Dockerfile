# Use a base image with JDK pre-installed
FROM openjdk:11-jre-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the packaged Spring Boot application JAR file into the container
COPY target/*.jar /app/your-application.jar

# Expose the port that your Spring Boot application listens on


# Command to run the Spring Boot application when the container starts
ENTRYPOINT ["java", "-jar", "your-application.jar"]
