FROM openjdk:8u222-jre-stretch

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

RUN mkdir -p /app
COPY newsfeed.jar /app/

ENV APP_PORT=8081

RUN chmod +x /tini
ENTRYPOINT ["/tini", "-g", "--", "java", "-jar", "/app/newsfeed.jar"]
CMD []
