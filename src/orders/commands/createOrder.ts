import { publishEvent } from '../../shared/eventBus';

export interface CreateOrderCommand {
  orderId: string;
  data: unknown;
}

export const createOrder = async (cmd: CreateOrderCommand) => {
  // TODO: Persist to DynamoDB
  await publishEvent({ type: 'OrderCreated', payload: cmd });
  return { status: 'created', id: cmd.orderId };
};
