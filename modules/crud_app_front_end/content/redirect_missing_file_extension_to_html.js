function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri == '/') {
    // This function overrides the default root object, so this is here to make up for that.
    request.uri = '/index.html'
  } else if (uri.endsWith('/') || uri.endsWith('.')) {
    request.uri = uri.slice(0, -1) + '.html';
  } else if (!uri.includes('.')) {
    request.uri += '.html'
  }

  return request;
}
