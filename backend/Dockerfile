FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q -DskipTests package
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/crowned-connections-api-1.0.0.jar app.jar
EXPOSE 5000
ENTRYPOINT ["java","-jar","/app/app.jar"]
