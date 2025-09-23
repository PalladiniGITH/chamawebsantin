FROM python:3.11-slim
RUN pip install pymodbus==3.0.0
COPY modbus_server.py /opt/modbus_server.py
CMD ["python", "/opt/modbus_server.py"]
