import { APIGatewayProxyHandlerV2 } from 'aws-lambda';
import { createOrder } from './commands/createOrder';
import { getOrder } from './queries/getOrder';

export const handler: APIGatewayProxyHandlerV2 = async (event) => {
  if (event.requestContext.http.method === 'POST') {
    const body = JSON.parse(event.body || '{}');
    const result = await createOrder({ orderId: body.orderId, data: body });
    return { statusCode: 200, body: JSON.stringify(result) };
  }
  if (event.requestContext.http.method === 'GET') {
    const id = event.queryStringParameters?.id || '';
    const result = await getOrder({ orderId: id });
    return { statusCode: 200, body: JSON.stringify(result) };
  }
  return { statusCode: 400, body: 'Unsupported' };
};
