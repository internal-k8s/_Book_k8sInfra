FROM gcr.io/distroless/java11-debian11
LABEL description="Echo IP Java Application"
EXPOSE 80
COPY ./target/app-in-host.jar /opt/app-in-image.jar
WORKDIR /opt
ENTRYPOINT [ "java", "-jar", "app-in-image.jar" ]
