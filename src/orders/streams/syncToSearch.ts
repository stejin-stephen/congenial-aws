import { DynamoDBStreamEvent, DynamoDBStreamHandler } from 'aws-lambda';
import { Client as OpenSearchClient } from '@opensearch-project/opensearch';

const search = new OpenSearchClient({
  node: process.env.OPENSEARCH_ENDPOINT || 'http://localhost:9200',
});
const indexName = process.env.ORDERS_INDEX || 'orders';

export const handler: DynamoDBStreamHandler = async (event: DynamoDBStreamEvent) => {
  for (const record of event.Records) {
    if (record.eventName === 'INSERT' && record.dynamodb?.NewImage) {
      const id = record.dynamodb.NewImage.id.S as string;
      const dataAttr = record.dynamodb.NewImage.data.S as string;
      const body = JSON.parse(dataAttr);
      await search.index({ index: indexName, id, body });
    }
  }
};
