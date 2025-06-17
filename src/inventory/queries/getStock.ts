export interface GetStockQuery {
  productId: string;
}

import { inventory } from '../../shared/database';

export const getStock = async (q: GetStockQuery) => {
  const qty = inventory.get(q.productId) ?? 0;
  return { id: q.productId, qty };
};
