from subprocess import run
from variables import (
    AUTHZ_POLICY_CONTENT,
    GATEWAY_CONTENT,
    REQUEST_AUTH_CONTENT,
    REQUEST_AUTH_FILENAME,
    AUTHZ_POLICY_FILENAME,
    GATEWAY_FILENAME,
    VIRTUALSERVICE_CONTENT,
    VIRTUALSERVICE_FILENAME
)


with open(REQUEST_AUTH_FILENAME, mode="w", encoding="utf-8") as message:
    message.write(REQUEST_AUTH_CONTENT)

with open(AUTHZ_POLICY_FILENAME, mode="w", encoding="utf-8") as message:
    message.write(AUTHZ_POLICY_CONTENT)

with open(GATEWAY_FILENAME, mode="w", encoding="utf-8") as message:
    message.write(GATEWAY_CONTENT)
    
with open(VIRTUALSERVICE_FILENAME, mode="w", encoding="utf-8") as message:
    message.write(VIRTUALSERVICE_CONTENT)