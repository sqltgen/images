FROM eclipse-temurin:21-jdk-alpine

RUN apk add --no-cache maven make

# Pre-populate ~/.m2 with the union of all example dependencies and plugins.
# Running "mvn compile" (not just dependency:go-offline) is necessary to trigger
# the kotlin-maven-plugin download, which only happens during a real compile phase.
WORKDIR /warmup
COPY pom.xml .
COPY src/ src/
RUN mvn compile -q && mvn dependency:go-offline -q
