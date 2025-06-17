import { APIGatewayProxyHandler } from 'aws-lambda';
import { updateStock } from './commands/updateStock';
import { getStock } from './queries/getStock';

export const handler: APIGatewayProxyHandler = async (event) => {
  if (event.httpMethod === 'POST') {
    const body = JSON.parse(event.body || '{}');
    const result = await updateStock({ productId: body.productId, qty: body.qty });
    return { statusCode: 200, body: JSON.stringify(result) };
  }
  if (event.httpMethod === 'GET') {
    const id = event.queryStringParameters?.id || '';
    const result = await getStock({ productId: id });
    return { statusCode: 200, body: JSON.stringify(result) };
  }
  return { statusCode: 400, body: 'Unsupported' };
};
