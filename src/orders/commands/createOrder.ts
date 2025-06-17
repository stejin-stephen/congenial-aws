import { publishEvent } from '../../shared/eventBus';
import { DynamoDBClient, PutItemCommand } from '@aws-sdk/client-dynamodb';

export interface CreateOrderCommand {
  orderId: string;
  data: unknown;
}

export const createOrder = async (cmd: CreateOrderCommand) => {
  const client = new DynamoDBClient({});
  const tableName = process.env.ORDERS_TABLE || 'orders';
  const params = new PutItemCommand({
    TableName: tableName,
    Item: {
      id: { S: cmd.orderId },
      data: { S: JSON.stringify(cmd.data) },
    },
  });
  await client.send(params);
  await publishEvent({ type: 'OrderCreated', payload: cmd });
  return { status: 'created', id: cmd.orderId };
};
