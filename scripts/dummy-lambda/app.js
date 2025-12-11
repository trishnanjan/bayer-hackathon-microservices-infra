// Minimal Lambda handler compatible with API Gateway HTTP API (payload version 2.0)
exports.handler = async (event) => {
  console.log('event', JSON.stringify(event));
  const body = { message: 'Hello from dummy lambda', path: event.rawPath || event.path };
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
};
