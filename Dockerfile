FROM openjdk:8-jdk-alpine
EXPOSE 9080
ARG JAR_FILE=target/*.jar
ADD ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]