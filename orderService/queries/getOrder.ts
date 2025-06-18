export interface GetOrderQuery {
  orderId: string;
}

import { orders } from '../../shared/database';

export const getOrder = async (q: GetOrderQuery) => {
  const data = orders.get(q.orderId);
  return { id: q.orderId, data };
};
