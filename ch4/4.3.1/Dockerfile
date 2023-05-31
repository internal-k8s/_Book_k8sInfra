FROM openjdk:11
LABEL description="Echo IP Java Development"
EXPOSE 80
COPY ./target/app-in-host.jar /opt/app-in-image.jar
WORKDIR /opt
ENTRYPOINT [ "java", "-jar", "app-in-image.jar" ]
