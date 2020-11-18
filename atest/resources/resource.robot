*** Settings ***
Library           XML
Library           Collections
Library           Suds2Library
Library           String
Library           ../resources/TestWebServices.py
Library           ../resources/Loggers.py
Library           ../resources/Util.py

*** Variables ***
${CALCULATOR WSDL URL}    http://localhost:8080/Calculator/soap11/description
${TEST WSDL URL}    http://localhost:8080/TestService/soap11/description
${SECURE TEST WSDL URL}    http://localhost:8080/secure/TestService/soap11/description
${SECURE TEST URL}    http://localhost:8080/secure/TestService/soap11
${WSDL DIR}       http://localhost:8080/wsdls
${SECURE WSDL DIR}    http://localhost:8080/secure/wsdls
