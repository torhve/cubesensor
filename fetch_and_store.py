#!/usr/bin/env python
from rauth import OAuth1Service # pip install rauth
from rauth import OAuth1Session
import json
import psycopg2
import os
from os.path import sep

if __name__ == '__main__':
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    with open(BASE_DIR + sep + "etc" + sep + "config.json") as f:
        config = json.loads(f.read())

    ROOT = 'http://api.cubesensors.com'
    AUTH = '%s/auth' % ROOT
    RES = '%s/v1' % ROOT

    CONSUMER_KEY = config['api']['consumer_key']
    CONSUMER_SECRET = config['api']['consumer_secret']

    cbsr = OAuth1Service(
            consumer_key=CONSUMER_KEY,
            consumer_secret=CONSUMER_SECRET,
            access_token_url='%s/access_token' % AUTH,
            authorize_url='%s/authorize' % AUTH,
            request_token_url='%s/request_token' % AUTH,
            base_url='%s/' % RES)

    #request_token, request_token_secret = cbsr.get_request_token(
    #        params={"oauth_callback":"oob"})
    #print (request_token, request_token_secret)
    #
    #authorize_url = cbsr.get_authorize_url(request_token)
    #print authorize_url
    ##oauth_verifier = '1BS58311'
    #oauth_verifier = raw_input('oauth_verifier')
    ## redirect user to authorize_url
    ## handle authorization - save oauth_verifier
    ##
    #
    ##request_token, request_token_secret = 'FRc9AfJt5lkr', 'GyHSaEsn6Z2zzCuh'
    #
    #
    #
    #access_token, access_token_secret = cbsr.get_access_token(
    #        request_token, 
    #        request_token_secret, 
    #        method="POST", 
    #        params={"oauth_verifier": oauth_verifier})
    #print ('Access token')
    #print (access_token, access_token_secret)
    access_token, access_token_secret = 'FHNeWUzO5Z1v', 'BKX9WztOklADIBCW'
    session = OAuth1Session(
            CONSUMER_KEY,
            CONSUMER_SECRET,
            access_token=access_token,
            access_token_secret=access_token_secret)

    #print session.get('%s/' % RES).json()

    #print session.get('%s/devices/' % RES).json()
    #session.get('%s/devices/%s' % (RES, device_id)).json()
    db = psycopg2.connect("dbname='cubesensor' user='cubes' host='localhost' password='2014yolocubemode'")
    cursor =  db.cursor()
    device_ids = ('000D6F0003E16037', '000D6F0003117ED0')
    for device_id in device_ids:
        data = session.get('%s/devices/%s/current' % (RES, device_id)).json()
        print data
        if data['ok']:
            field_list = ','.join(data['field_list'])

            results = data['results'][0]

            insert = "INSERT INTO data_"+device_id+" ({}) ".format(field_list)
            values = '%s,'*len(results)
            values = values.rstrip(',')
            insert += "VALUES ({})".format(values)
            cursor.execute(insert, results)

    db.commit()
    db.close()
