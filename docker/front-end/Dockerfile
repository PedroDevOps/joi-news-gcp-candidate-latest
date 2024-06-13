FROM openjdk:8u222-jre-stretch

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

RUN mkdir -p /app
COPY front-end.jar /app/

ENV APP_PORT="8080" \
  STATIC_URL="http://localhost:8000/" \
  QUOTE_SERVICE_URL="http://quotes:8082" \
  NEWSFEED_SERVICE_URL="http://newsfeed:8081" \
  NEWSFEED_SERVICE_TOKEN="secret"

RUN chmod +x /tini
ENTRYPOINT ["/tini", "-g", "--", "java", "-jar", "/app/front-end.jar"]
CMD []
