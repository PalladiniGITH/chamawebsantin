SCADA lab (ScadaBR + Modbus simulator) - Demo

Requisitos: Docker + docker-compose

Passos rápidos:
1) Colocar o arquivo scadabr.war em scadabr/scadabr.war (obtenha do site oficial).
   Se o arquivo ainda não estiver presente, o script ./scada-up.sh abortará com uma mensagem
   explicando como efetuar o download antes do build.
2) Opcional: gerar certificados locais
   ./gen-lab-certs.sh
   cp lab-pki/server_fullchain.pem ./certs/server.crt
   cp lab-pki/server.key ./certs/server.key
3) Subir containers:
   ./scada-up.sh
4) Acessar ScadaBR: http://192.168.8.50:8080/

OBS:
- NÃO exponha a porta Modbus (502) para redes externas.
- Para remoção completa: docker-compose down -v
