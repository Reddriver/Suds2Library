*** Settings ***
Test Setup        Create Soap Client    ${TEST WSDL URL}
Resource          resources/resource.robot

*** Test Cases ***
Timestamp
    Apply Security Timestamp    30 sec
    Call Soap Method    theAnswer
    Timestamp Duration Should Be    30
    Apply Security Timestamp    5s
    Call Soap Method    theAnswer
    Timestamp Duration Should Be    5

Replace Existing Timestamp
    [Documentation]    Existing Security object should be kept and other Timestamp instances removed
    ${date}=    Evaluate    suds.wsse    suds
    ${security}=    Call Method    ${date}    Security
    ${timestamp}=    Call Method    ${date}    Timestamp    ${5}
    Append To List    ${security.tokens}    ${timestamp}
    ${sudslib}=    Get Library Instance    Suds2Library
    ${sudslib._client().options.wsse}    Set Variable    ${security}
    Call Soap Method    theAnswer
    Timestamp Duration Should Be    5
    Apply Security Timestamp    10 sec
    Call Soap Method    theAnswer
    Timestamp Duration Should Be    10
    Should Be Equal    ${sudslib._client().options.wsse}    ${security}

Timestamp Without Expires
    Apply Security Timestamp
    Call Soap Method    theAnswer
    ${xml}=    Get Last Sent
    Element Should Not Exist    ${xml}    Header/Security/Timestamp/Expires

Timestamp Precise Only To Milliseconds
    [Documentation]    Per Basic Security Profile 1.1's R3220 & R3221, datetime should only be precise to milliseconds.
    Apply Security Timestamp    30 sec
    Call Soap Method    theAnswer
    ${created}    ${expires}=    Get Created and Expires
    Should Not Match Regexp    ${created}    \\.\\d{4}
    Should Not Match Regexp    ${expires}    \\.\\d{4}

Username and Password
    Call Soap Method    theAnswer
    Username and Password Should Be Absent
    Apply Username Token    root    secret
    Call Soap Method    theAnswer
    Username and Password Should Be    root    secret
    Apply Username Token    super    letmein
    Call Soap Method    theAnswer
    Username and Password Should Be    super    letmein

Password Has Type
    [Documentation]    Type is optional in the WS-Security specification when using PasswordText, but it is mandatory in WS-I's Basic Security Profile; therefore it should always be sent.
    Apply Username Token    root    secret
    Call Soap Method    theAnswer
    ${xml}=    Get Last Sent
    Element Attribute Should Be    ${xml}    Type    http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText    Header/Security/UsernameToken/Password
    Apply Username Token    root    secret    digest=True
    Call Soap Method    theAnswer
    ${xml}=    Get Last Sent
    Element Attribute Should Be    ${xml}    Type    http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest    Header/Security/UsernameToken/Password

Blank Password
    Apply Username Token    root    ${EMPTY}
    Call Soap Method    theAnswer
    Username and Password Should Be    root    ${EMPTY}

UsernameToken: Created
    Apply Username Token    user
    Call Soap Method    theAnswer
    Created Should Be Absent
    Apply Username Token    user    setcreated=True
    Call Soap Method    theAnswer
    ${first created}=    Get Created In UsernameToken
    ${diff}=    Xml Datetime Difference    ${first created}
    Should Be True    ${diff} < 2
    Call Soap Method    theAnswer
    ${second created}=    Get Created In UsernameToken
    Should Not Be Equal    ${first created}    ${second created}

Nonce
    Apply Username Token    user
    Call Soap Method    theAnswer
    Nonce Should Be Absent
    Apply Username Token    user    setnonce=True
    Call Soap Method    theAnswer
    Nonce Should Be Present
    ${first nonce}=    Get Nonce
    Call Soap Method    theAnswer
    ${second nonce}=    Get Nonce
    Should Not Be Equal    ${first nonce}    ${second nonce}

Nonce Has EncodingType
    [Documentation]    EncodingType is optional in the WS-Security specification when using PasswordText, but it is mandatory in WS-I's Basic Security Profile; therefore it should always be sent.
    Apply Username Token    user    setnonce=True
    Call Soap Method    theAnswer
    ${xml}=    Get Last Sent
    Element Attribute Should Be    ${xml}    EncodingType    http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary    Header/Security/UsernameToken/Nonce

Username No Password
    Apply Username Token    user
    Call Soap Method    theAnswer
    Password Should Be Absent

Timestamp and UsernameToken
    Apply Security Timestamp
    Apply Username Token    user
    Call Soap Method    theAnswer
    ${xml}=    Get Last Sent
    Element Should Exist    ${xml}    Header/Security/Timestamp
    Element Should Exist    ${xml}    Header/Security/UsernameToken

Digest No Password
    Run Keyword And Expect Error    Password is required when digest is True.    Apply Username Token    user    digest=True

Digest No Nonce Or Created
    Apply Username Token    user    password    digest=True
    Call Soap Method    theAnswer
    ${digest}=    Get Password
    Should Be Equal As Strings    ${digest}    b'W6ph5Mm5Pz8GgiULbPgzG37mj9g='

Digest
    Apply Username Token    user    password    True    True    digest=True
    Set Fixed Nonce    5ABcqPZWb6ImI2E6tob8MQ==
    Set Fixed Created    2010-06-08T07:26:50Z
    Call Soap Method    theAnswer
    ${digest}=    Get Password
    Should Be Equal As Strings    ${digest}    b'GMVUkQeviQzk4zHJMGa/WoCsCoY='
    ${created}=    Get Created In UsernameToken
    Should Be Equal As Strings    ${created}    2010-06-08T07:26:50Z
    ${nonce}=    Get Nonce
    Should Be Equal As Strings    ${nonce}    b'5ABcqPZWb6ImI2E6tob8MQ=='

mustUnderstand value
    [Documentation]    Suds uses "true" for mustUnderstand, which is appropriate for SOAP 1.2, but for 1.1 it should be "1" or "0".
    Apply Security Timestamp
    Call Soap Method    theAnswer
    ${xml}=    Get Last Sent
    Element Attribute Should Be    ${xml}    mustUnderstand    1    Header/Security

*** Keywords ***
Created Should Be Absent
    ${xml}=    Get Last Sent
    Element Should Not Exist    ${xml}    Header/Security/UsernameToken/Created

Get Created In UsernameToken
    ${xml}=    Get Last Sent
    ${created}=    Get Element Text    ${xml}    Header/Security/UsernameToken/Created
    [Return]    ${created}

Get Created and Expires
    ${xml}=    Get Last Sent
    ${created}=    Get Element Text    ${xml}    Header/Security/Timestamp/Created
    ${expires}=    Get Element Text    ${xml}    Header/Security/Timestamp/Expires
    [Return]    ${created}    ${expires}

Get Nonce
    ${xml}=    Get Last Sent
    ${nonce}=    Get Element Text    ${xml}    Header/Security/UsernameToken/Nonce
    [Return]    ${nonce}

Get Password
    ${xml}=    Get Last Sent
    ${nonce}=    Get Element Text    ${xml}    Header/Security/UsernameToken/Password
    [Return]    ${nonce}

Nonce Should Be Absent
    ${xml}=    Get Last Sent
    ${first nonce}=    Element Should Not Exist    ${xml}    Header/Security/UsernameToken/Nonce

Nonce Should Be Present
    ${xml}=    Get Last Sent
    ${first nonce}=    Get Element Text    ${xml}    Header/Security/UsernameToken/Nonce
    Should Not Be Empty    ${first nonce}

Password Should Be Absent
    ${xml}=    Get Last Sent
    Element Should Not Exist    ${xml}    Header/Security/UsernameToken/Password

Timestamp Duration Should Be
    [Arguments]    ${difference}
    ${created}    ${expires}=    Get Created and Expires
    ${actual difference}=    Xml Datetime Difference    ${created}    ${expires}
    Should Be Equal As Numbers    ${actual difference}    ${difference}

Username and Password Should Be
    [Arguments]    ${username}    ${password}
    ${xml}=    Get Last Sent
    Element Text Should Be    ${xml}    ${username}    Header/Security/UsernameToken/Username
    Element Text Should Be    ${xml}    ${password}    Header/Security/UsernameToken/Password

Username and Password Should Be Absent
    ${xml}=    Get Last Sent
    Element Should Not Exist    ${xml}    Header/Security/UsernameToken/Username
    Element Should Not Exist    ${xml}    Header/Security/UsernameToken/Password
