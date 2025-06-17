export interface Event {
  type: string;
  payload: unknown;
}

export const publishEvent = async (event: Event) => {
  // TODO: integrate with AWS EventBridge or other messaging system
  console.log(`Publishing event: ${event.type}`);
};

export const handleEvent = async (event: Event) => {
  console.log(`Handling event: ${event.type}`);
};
