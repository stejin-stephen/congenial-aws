export interface GetOrderQuery {
  orderId: string;
}

export const getOrder = async (q: GetOrderQuery) => {
  // TODO: Fetch from DynamoDB
  return { id: q.orderId, data: {} };
};
