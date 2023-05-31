FROM openjdk:11 AS int-build
LABEL description="Java Application builder"
RUN git clone https://github.com/gnu-gnu/inbuilder.git
WORKDIR inbuilder
RUN chmod 700 mvnw
RUN ./mvnw clean package

FROM gcr.io/distroless/java11-debian11
LABEL description="Echo IP Java Application"
EXPOSE 80
COPY --from=int-build inbuilder/target/app-in-host.jar /opt/app-in-image.jar
WORKDIR /opt
ENTRYPOINT [ "java", "-jar", "app-in-image.jar" ]
