FROM tomcat:10.1-jdk17
COPY target/vehiculosBuild.war /usr/local/tomcat/webapps/vehiculosBuild.war
EXPOSE 8080
