function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.endsWith('.html')) {
    uri = uri.slice(0, -5);
  }
  if (uri.endsWith('index')) {
    uri = uri.slice(0, -5);
  }
  if (uri.endsWith('/')) {
    uri = uri.slice(0, -1);
  }
  // This function overrides the default root object, so this is here to make up for that.
  if (uri == '') {
    uri = '/index.html';
  }

  request.uri = uri;

  return request;
}
