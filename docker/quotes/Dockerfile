FROM openjdk:8u222-jre-stretch

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

RUN mkdir -p /app
COPY quotes.jar /app/

ENV APP_PORT=8082

RUN chmod +x /tini
ENTRYPOINT ["/tini", "-g", "--", "java", "-jar", "/app/quotes.jar"]
CMD []
