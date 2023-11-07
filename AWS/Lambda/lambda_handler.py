import boto3
import json
import uuid
import logging
import base64
from decimal import Decimal

logger = logging.getLogger()
logger.setLevel(logging.INFO)
dynamoDb = boto3.resource('dynamodb')
table = dynamoDb.Table('test-table')

base_path = '/api'
product = f'{base_path}/product'
logger = logging.getLogger()

def lambda_handler(event, context):

    logger.info(f'Event: {event}')
    logger.info(f'Context: {context}')

    try:
        path: str = event.get("path")
        method = event.get('httpMethod')
        logger.info(f'Path: {path}')
        logger.info(f'Method: {method}')
        if method in ['POST', 'PUT']:
            if event.get("isBase64Encoded") == True:
                body = json.loads(base64.b64decode(event.get('body')))
            else:
                body = json.loads(event.get('body'))

        elif method == 'GET' and path == product:
            if queryParams := event.get('queryStringParameters', {}):
                if Id := queryParams.get('Id', None):
                    if product_data := get_product_by_id(Id):
                        return build_response(200, {"data":product_data, 
                                                    "message": "success",
                                                    "details": f"Fetched data key {Id}"})
                    else:
                        return build_response(404, {"message": "Not Found", "details": f"Data with key {Id} not found", "data": None})
            else:
                return build_response(200, {"data": get_products(), 
                                            "message": "success",
                                            "details":"Fetched all data"})


        elif method == 'POST' and path == product:
            if Id:= create_product(body):
                return build_response(201, {"message": "success", 
                                            "details":f"Created Product with Id {Id}",
                                            "data": None})
            else:
                return build_response(500, {"message": "Internal Server Error", 
                                            "details": f"Error: {e.args}",
                                            "data": None})

        elif method == 'PUT' and path == product:
            Id = event.get('queryStringParameters').get('Id')
            if update_product(Id, body):
                return build_response(200, {"message": "success", 
                                            "details":f"Updated Product with key {Id}",
                                            "data": None})
            else:
                return build_response(500, {"message": "Internal Server Error", 
                                            "details": f"Error: {e.args}",
                                            "data": None})

        elif method == 'DELETE' and path == product:

            Id = event.get('queryStringParameters').get('Id')
            if delete_product(Id):
                return build_response(200, {"message": "success", 
                                            "details":f"Deleted Product with key {Id}",
                                            "data": None})
            else:
                return build_response(500, {"message": "Internal Server Error", 
                                            "details": f"Error: {e.args}",
                                            "data": None})

        else:
            return build_response(404, {"message": "Not Found", "details": f"Path {path} not found", "data": None})

    except Exception as e:
        logger.error(f'Error: {e}')
        return build_response(500, {"message": "Internal Server Error", "details": f"Error: {e.args}"})

def get_products():
    try:
        resp = table.scan()
        result = resp.get('Items')

        while 'LastEvaluatedKey' in resp:
            resp = table.scan(ExclusiveStartKey=resp['LastEvaluatedKey'])
            result.extend(resp['Items'])
        logger.info("Reading all data from table")
        return result
    except Exception as e:
        logger.error(f'Error: {e}')
        return []


def get_product_by_id(Id):
    try:
        resp = table.get_item(Key={'Id': Id})
        result = resp.get('Item')
        logger.info(f'Reading data from table with key: {Id}')
        return result
    except Exception as e:
        logger.error(f'Error: {e}')
        return {}

def create_product(product):
    try:
        product['Id'] = str(uuid.uuid4())
        table.put_item(Item=product)
        logger.info('Creating Product in DynamoDB')
        return product['Id']
    except Exception as e:
        logger.error(f'Error: {e}')
        return None

def update_product(Id, product):
    try:
        update_expression, expression_attribute_values = generate_update_expression(product)
        table.update_item( Key={'Id': Id}, 
                            UpdateExpression=update_expression, 
                            ExpressionAttributeValues=expression_attribute_values)
        logger.info(f'Updating with key {Id}')
        return True
    except Exception as e:
        logger.error(f'Error: {e}')
        return False

def generate_update_expression(update_values:dict) -> (str, dict):

    update_expression = "SET "
    expression_attribute_values = {}

    for key, value in update_values.items():
        placeholder = f":{key.replace('.', '_')}"
        update_expression += f"{key} = {placeholder}, "
        expression_attribute_values[placeholder] = value

    update_expression = update_expression.rstrip(", ")
    return update_expression, expression_attribute_values

def delete_product(Id):
    try:
        table.delete_item(Key={'Id': Id})
        logger.info(f'Deleting data with key {Id}')
        return True
    except Exception as e:
        logger.error(f'Error: {e}')
        return False

def build_response(status_code, body):
    response = {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },

    }
    if body:
        response['body'] = json.dumps(body, cls=CustomEncoder)
    return response


class CustomEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(CustomEncoder, self).default(obj)
