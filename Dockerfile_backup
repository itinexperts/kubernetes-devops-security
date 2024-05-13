FROM adoptopenjdk/openjdk8:alpine-slim
EXPOSE 9080
ARG JAR_FILE=target/*.jar
ADD ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]