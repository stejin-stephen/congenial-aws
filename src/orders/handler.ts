import { APIGatewayProxyHandler } from 'aws-lambda';
import { createOrder } from './commands/createOrder';
import { getOrder } from './queries/getOrder';

export const handler: APIGatewayProxyHandler = async (event) => {
  if (event.httpMethod === 'POST') {
    const body = JSON.parse(event.body || '{}');
    const result = await createOrder({ orderId: body.orderId, data: body });
    return { statusCode: 200, body: JSON.stringify(result) };
  }
  if (event.httpMethod === 'GET') {
    const id = event.queryStringParameters?.id || '';
    const result = await getOrder({ orderId: id });
    return { statusCode: 200, body: JSON.stringify(result) };
  }
  return { statusCode: 400, body: 'Unsupported' };
};
