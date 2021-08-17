FROM maven:3.8.1-ibmjava-8-alpine AS builder
LABEL maintainer="IBM Java Engineering at IBM Cloud"
WORKDIR /
COPY pom.xml ./
COPY src src/
RUN mvn clean package

FROM openliberty/open-liberty:kernel-java8-openj9-ubi as staging
USER root
COPY --from=builder target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar /staging/fatClinic.jar

RUN springBootUtility thin \
 --sourceAppPath=/staging/fatClinic.jar \
 --targetThinAppPath=/staging/thinClinic.jar \
 --targetLibCachePath=/staging/lib.index.cache

FROM openliberty/open-liberty:kernel-java8-openj9-ubi
USER root
COPY --from=staging /staging/lib.index.cache /opt/ol/wlp/usr/shared/resources/lib.index.cache
COPY --from=staging /staging/thinClinic.jar /config/dropins/spring/thinClinic.jar

RUN chown -R 1001.0 /config && chmod -R g+rw /config
RUN chown -R 1001.0 /opt/ol/wlp/usr/shared/resources/lib.index.cache && chmod -R g+rw /opt/ol/wlp/usr/shared/resources/lib.index.cache

RUN cp /opt/ol/wlp/templates/servers/springBoot2/server.xml /config/server.xml

USER 1001

RUN configure.sh