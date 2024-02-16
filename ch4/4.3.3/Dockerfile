FROM azul/zulu-openjdk:21.0.2-21.32
LABEL description="Echo IP Java Application"
EXPOSE 80
RUN apt-get update -y && apt-get install -y git && git clone https://github.com/IaC-Sources/InBuilder.git
WORKDIR InBuilder
RUN chmod 700 mvnw
RUN ./mvnw clean package
RUN mv target/app-in-host.jar /opt/app-in-image.jar
WORKDIR /opt
ENTRYPOINT [ "java", "-jar", "app-in-image.jar" ]
