export interface GetStockQuery {
  productId: string;
}

export const getStock = async (q: GetStockQuery) => {
  // TODO: Fetch from DynamoDB
  return { id: q.productId, qty: 0 };
};
