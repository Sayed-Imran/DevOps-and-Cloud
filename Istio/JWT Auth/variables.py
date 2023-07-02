import json, time
from jinja2 import Environment, FileSystemLoader
from jwcrypto import jwk, jwt
import pathlib

PAYLOAD = {
    'iss': 'sayedimran@crazeops.tech',
    'iat': int(time.time()),
    'exp': int(time.time()) + 86400,
    'role': 'admin',
}

PRIVATE_KEY="./keys/private-key.pem"

pem_data = pathlib.Path(PRIVATE_KEY).read_text()
pem_data_encode = pem_data.encode("utf-8")
key = jwk.JWK.from_pem(pem_data_encode)
PUBLIC = json.loads(key.export(private_key=False))


JWT_TOKEN = jwt.JWT(header={"alg": "RS256", "typ": "JWT", "kid": PUBLIC["kid"]},claims=PAYLOAD)
JWT_TOKEN.make_signed_token(key)
print(JWT_TOKEN.serialize())


jwt_data = jwt.JWT(jwt=JWT_TOKEN.serialize())
jwt_data.validate(key)
CLAIMS = jwt_data.claims
HEADER = jwt_data.header


GATEWAY_NAME = 'fastapi-gateway'
DOMAIN = 'fastapi-app.default.domain.local'
VS_NAME = 'fastapi-vs'
NAMESPACE = 'default'
ISSUER = 'sayedimran@crazeops.tech'
REQ_AUTH_NAME = 'custom-jwt-auth'
AUTHZPOLICY_NAME = 'fastapi-authzpolicy'
ACTION = 'DENY'
RULE_MATCH_KEY_VALUE = 'app: fastapi-app'
ENVIRONMENT = Environment(loader=FileSystemLoader("templates/"))
REQUEST_AUTH_TEAMPLATE = ENVIRONMENT.get_template("RequestAuthentication.yaml")
AUTHZ_POLICY_TEAMPLATE = ENVIRONMENT.get_template("AuthorizationPolicy.yaml")
GATEWAY_TEMPLATE = ENVIRONMENT.get_template("IstioGateway.yaml")
VIRTUALSERVICE_TEMPLATE = ENVIRONMENT.get_template("VirtualService.yaml")
REQUEST_AUTH_FILENAME = 'RequestAuthentication.yaml'
AUTHZ_POLICY_FILENAME = 'AuthzPolicy.yaml'
GATEWAY_FILENAME = 'IstioGateway.yaml'
VIRTUALSERVICE_FILENAME = 'Virtualservice.yaml'

REQUEST_AUTH_CONTENT = REQUEST_AUTH_TEAMPLATE.render(
    NAMESPACE=NAMESPACE,
    ISSUER=ISSUER,
    REQ_AUTH_NAME=REQ_AUTH_NAME,
    RULE_MATCH_KEY_VALUE=RULE_MATCH_KEY_VALUE,
    PUBLIC=PUBLIC
)

AUTHZ_POLICY_CONTENT = AUTHZ_POLICY_TEAMPLATE.render(
    NAMESPACE=NAMESPACE,
    ACTION=ACTION,
    AUTHZPOLICY_NAME=AUTHZPOLICY_NAME,
    RULE_MATCH_KEY_VALUE=RULE_MATCH_KEY_VALUE
)

GATEWAY_CONTENT = GATEWAY_TEMPLATE.render(
    GATEWAY_NAME=GATEWAY_NAME,
    NAMESPACE=NAMESPACE,
    DOMAIN=DOMAIN
)

VIRTUALSERVICE_CONTENT = VIRTUALSERVICE_TEMPLATE.render(
    VS_NAME=VS_NAME,
    NAMESPACE=NAMESPACE,
    DOMAIN=DOMAIN
)