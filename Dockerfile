FROM openjdk:8-jdk-alpine

WORKDIR /app
COPY target/umsl-0.0.1-SNAPSHOT.jar /app/

# Port to expose
EXPOSE 8081

ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app/umsl-0.0.1-SNAPSHOT.jar"]
