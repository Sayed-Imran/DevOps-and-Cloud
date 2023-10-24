import boto3
import json
import uuid
import logging
import base64
from custom_encoder import CustomEncoder

logger = logging.getLogger()
logger.setLevel(logging.INFO)
dynamoDb = boto3.resource('dynamodb')
table = dynamoDb.Table('product-inventory')

base_path = '/api/v1/product-inventory'
health_check = f'{base_path}/health'
product = f'{base_path}/product'
products = f'{base_path}/products'
logger = logging.getLogger()

def lambda_handler(event, context):

    logger.info(f'Event: {event}')
    logger.info(f'Context: {context}')
    
    try:
        path = event.get("path")
        method = event.get('httpMethod')
        logger.info(f'Path: {path}')
        logger.info(f'Method: {method}')
        if method in ['POST', 'PATCH']:
            if event.get("isBase64Encoded") == True:
                body = json.loads(base64.b64decode(event.get('body')))
            else:
                body = json.loads(event.get('body'))

        if method == 'GET' and path == health_check:
            return build_response(200, {"message": "success", "details": "Lambda is healthy", "data": None})

        elif method == 'GET' and path == products:
            return build_response(200, {"data": get_products(), 
                                        "message": "success",
                                        "details":"Fetched all data from table product-inventory "})

        elif method == 'GET' and path == product:
            product_id = event.get('queryStringParameters').get('product_id')
            if product_data := get_product_by_id(product_id):
                return build_response(200, {"data":product_data, 
                                            "message": "success",
                                            "details": f"Fetched data from table product-inventory with key {product_id}"})
            else:
                return build_response(404, {"message": "Not Found", "details": f"Product with key {product_id} not found", "data": None})


        elif method == 'POST' and path == product:
            if pid:= create_product(body):
                return build_response(201, {"message": "success", 
                                            "details":f"Created Product with pid {pid}",
                                            "data": None})
            else:
                return build_response(500, {"message": "Internal Server Error", 
                                            "details": f"Error: {e.args}",
                                            "data": None})

        elif method == 'PATCH' and path == product:
            product_id = event.get('queryStringParameters').get('product_id')
            if update_product(product_id, body):
                return build_response(200, {"message": "success", 
                                            "details":f"Updated Product with key {product_id}",
                                            "data": None})
            else:
                return build_response(500, {"message": "Internal Server Error", 
                                            "details": f"Error: {e.args}",
                                            "data": None})

        elif method == 'DELETE' and path == product:
            
            product_id = event.get('queryStringParameters').get('product_id')
            if delete_product(product_id):
                return build_response(200, {"message": "success", 
                                            "details":f"Deleted Product with key {product_id}",
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
        logger.info("Reading all data from table product-inventory")
        return result
    except Exception as e:
        logger.error(f'Error: {e}')
        return []


def get_product_by_id(product_id):
    try:
        resp = table.get_item(Key={'pid': product_id})
        result = resp.get('Item')
        logger.info(f'Reading Product from table product-inventory with key: {product_id}')
        return result
    except Exception as e:
        logger.error(f'Error: {e}')
        return {}

def create_product(product):
    try:
        product['pid'] = str(uuid.uuid4())
        table.put_item(Item=product)
        logger.info('Creating Product in DynamoDB')
        return product['pid']
    except Exception as e:
        logger.error(f'Error: {e}')
        return None

def update_product(product_id, product):
    try:
        update_expression, expression_attribute_values = generate_update_expression(product)
        table.update_item( Key={'product_id': product_id}, 
                            UpdateExpression=update_expression, 
                            ExpressionAttributeValues=expression_attribute_values)
        logger.info(f'Updating Product with key {product_id} in table product-inventory')
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

def delete_product(product_id):
    try:
        table.delete_item(Key={'pid': product_id})
        logger.info(f'Deleting Product with key {product_id} in table product-inventory')
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