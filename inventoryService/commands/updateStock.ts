import { publishEvent } from '../../src/shared/eventBus';
import { inventory } from '../../src/shared/database';

export interface UpdateStockCommand {
  productId: string;
  qty: number;
}

export const updateStock = async (cmd: UpdateStockCommand) => {
  inventory.set(cmd.productId, cmd.qty);
  await publishEvent({ type: 'StockUpdated', payload: cmd });
  return { status: 'updated', id: cmd.productId };
};
