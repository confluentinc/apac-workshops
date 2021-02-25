from flask import Flask, render_template, request

import json

from thrift import Thrift
from thrift.transport import TSocket,TTransport
from thrift.protocol import TBinaryProtocol
from hbase import Hbase
from hbase.ttypes import ColumnDescriptor,Mutation,BatchMutation,TRegionInfo
from hbase.ttypes import IOError,AlreadyExists

app = Flask(__name__)

@app.route('/getallcustomers')
def getallcustomers():
   socket = TSocket.TSocket('hbase', 9090)
   socket.setTimeout(5000)
   transport = TTransport.TBufferedTransport(socket)
   
   protocol = TBinaryProtocol.TBinaryProtocol(transport)
   client = Hbase.Client(protocol)
   
   transport.open()
   
   scanId = client.scannerOpen("C360_STREAM", "", [])
   result = client.scannerGetList(scanId, 10)
   
   customers = []
   
   for row in result:
      customer = {}
      customer["CUSTOMER_ID"] = row.row
      customer["FIRST_NAME"] = row.columns.get('C360_STREAM:FIRST_NAME').value
      customer["LAST_NAME"] = row.columns.get('C360_STREAM:LAST_NAME').value
      # customer["DOB"] = row.columns.get('C360_STREAM:DOB').value
      customer["PHONE_TYPE"] = row.columns.get('C360_STREAM:PHONE_TYPE').value
      # customer["PHONE_NUM"] = row.columns.get('C360_STREAM:PHONE_NUM').value
      customer["ADDRESS_LINE_1"] = row.columns.get('C360_STREAM:ADDRESS_LINE_1').value
      customer["ADDRESS_LINE_2"] = row.columns.get('C360_STREAM:ADDRESS_LINE_2').value
      # customer["PIN"] = row.columns.get('C360_STREAM:PIN').value
      customer["ADDRESS_TYPE"] = row.columns.get('C360_STREAM:ADDRESS_TYPE').value
      customers.append(customer)
   
   transport.close()

   return json.dumps(customers)

if __name__ == '__main__':
   app.run(debug = True)
