FROM tomcat:9.0-jdk11-openjdk

# limpar webapps padrão
RUN rm -rf /usr/local/tomcat/webapps/*

# copiar a aplicação ScadaBR (o WAR deve ser colocado manualmente em scadabr/scadabr.war)
COPY scadabr.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
