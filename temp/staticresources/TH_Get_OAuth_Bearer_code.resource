#!/usr/bin/python
'''
# Python 2.7.9 script to demonstrate how to get an access token from Salesforce Identity
# Pre-requisite: standard library functionality = e.g urrlib2, json, StringIO

 #/**
 #* Copyright (c) 2012, Salesforce.com, Inc.  All rights reserved.
 #*
 #* Redistribution and use in source and binary forms, with or without
 #* modification, are permitted provided that the following conditions are
 #* met:
 #*
 #*   * Redistributions of source code must retain the above copyright
 #*     notice, this list of conditions and the following disclaimer.
 #*
 #*   * Redistributions in binary form must reproduce the above copyright
 #*     notice, this list of conditions and the following disclaimer in
 #*     the documentation and/or other materials provided with the
 #*     distribution.
 #*
 #*   * Neither the name of Salesforce.com nor the names of its
 #*     contributors may be used to endorse or promote products derived
 #*     from this software without specific prior written permission.
 #*
 #* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 #* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 #* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 #* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 #* HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 #* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 #* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 #* DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 #* THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 #* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 #* OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 #*/
'''

# Configurations
CLIENT_ID = '3MVG9fMtCkV6eLhejNzm7w_Nwg0OrNLLbTMbGlzwelxthWi2aTseFNC8qm5c77KzNERp73WnR88f2eb1_iOqt'
CLIENT_SECRET = 'MzY5OTMzNzc5NjgzNTQ1NjAzNQ==' 

USER_NAME = 'FILL_ME_IN'
PASS_WORD = 'FILL_ME_IN'

#imports

import urllib2
import json
import getpass
import base64

#code

def login():
    ''' login function '''
    # prompt for username and password
    username = raw_input('Username: \n')
    password = getpass.getpass('Password: \n')

    # check to see if anything was entered and if not, default values
    # change default values for username and password to your own
    if len(username) < 1:
        #username = 'user@company.com'
        #password = 'Passw0rd'
        username = USER_NAME
        password = PASS_WORD
        print 'Using default username: ' + username
    else:
        print 'Using user inputed username: ' + username

    # decode client secret
    decoded_secret = base64.b64decode(CLIENT_SECRET)
    clientsecret = decoded_secret

    # create a new Urllib2 Request object with base REST API oauth2 token endpoint
    req = urllib2.Request('https://login.salesforce.com/services/oauth2/token')

    # pass in grant type including username, password, client secret, and client id
    data = '&grant_type=password&client_id='+CLIENT_ID+'&client_secret='+clientsecret+'&username='+username+'&password='+password
    
    # add data to request
    req.add_data(data)

    # make REST request and post results to res object
    res = urllib2.urlopen(req)

    # store the results in a dictionary object in order to parse JSON
    res_dict = json.load(res)

    # clean up
    res.close()

    # return access token to calling function
    return res_dict['access_token']

def get_token(): 
	
    # to get access token, call login function
    access_token = login()

    # print access token to screen
    print 'access_token: \nBearer ' + access_token + '\n'


def main():
    ''' Main function '''
    get_token()

if __name__ == "__main__":
    main() 
