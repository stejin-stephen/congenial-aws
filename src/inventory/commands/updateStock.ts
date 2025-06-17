import { publishEvent } from '../../shared/eventBus';

export interface UpdateStockCommand {
  productId: string;
  qty: number;
}

export const updateStock = async (cmd: UpdateStockCommand) => {
  await publishEvent({ type: 'StockUpdated', payload: cmd });
  return { status: 'updated', id: cmd.productId };
};
