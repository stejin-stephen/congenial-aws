export interface Event {
  type: string;
  payload: unknown;
}

import { EventEmitter } from 'events';

const emitter = new EventEmitter();

export const publishEvent = async (event: Event) => {
  console.log(`Publishing event: ${event.type}`);
  emitter.emit(event.type, event);
};

export const onEvent = (type: string, handler: (event: Event) => void) => {
  emitter.on(type, handler);
};

export const handleEvent = async (event: Event) => {
  console.log(`Handling event: ${event.type}`);
};
