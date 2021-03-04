from flask import Flask, render_template, request
import pymongo

import json

app = Flask(__name__)

client = pymongo.MongoClient("mongodb://myuser:mypassword@localhost:27017/")

@app.route('/getaccountmaster')
def getaccountmaster():
   db = client["accounts"]
   collection = db["customers"]
   documents = collection.find({}, {"_id":0})

   return json.dumps(list(documents))

if __name__ == '__main__':
   app.run(debug = True)
