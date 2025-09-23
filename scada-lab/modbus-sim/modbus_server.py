#!/usr/bin/env python3
from pymodbus.server.sync import StartTcpServer
from pymodbus.device import ModbusDeviceIdentification
from pymodbus.datastore import ModbusSequentialDataBlock, ModbusSlaveContext, ModbusServerContext
import logging

logging.basicConfig()
log = logging.getLogger()
log.setLevel(logging.INFO)

store = ModbusSlaveContext(
    di=ModbusSequentialDataBlock(0, [0]*100),
    co=ModbusSequentialDataBlock(0, [0]*100),
    hr=ModbusSequentialDataBlock(0, [0]*100),
    ir=ModbusSequentialDataBlock(0, [0]*100),
)

context = ModbusServerContext(slaves=store, single=True)

identity = ModbusDeviceIdentification()
identity.VendorName = 'LabGrupo8'
identity.ProductCode = 'MODSIM'
identity.VendorUrl = 'http://lab'
identity.ProductName = 'ModbusSim'
identity.ModelName = 'ModbusSim'
identity.MajorMinorRevision = '1.0'

if __name__ == "__main__":
    host = '0.0.0.0'
    port = 502
    print(f"Starting Modbus TCP simulator on {host}:{port}")
    StartTcpServer(context, identity=identity, address=(host, port))
