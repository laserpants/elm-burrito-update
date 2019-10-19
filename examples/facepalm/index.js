'use strict';

require('./index.html');
require('./api.js');

var Elm = require('./src/Main.elm').Elm;

var storageKey = 'elm-burrito-update-demo-app-session';

var session = sessionStorage.getItem(storageKey) || localStorage.getItem(storageKey);

var app = Elm.Main.init({
  node: document.getElementById('elm-code'),
  flags: {
    session: session || '',
    basePath: 'laserpants.github.io' == location.hostname ? '/elm-burrito-update/examples/facepalm/dist' : ''
  }
});

if (app.ports && app.ports.setSession) {
  app.ports.setSession.subscribe(function(data) {
    var api = data.user.rememberMe ? localStorage : sessionStorage;
    api.setItem(storageKey, JSON.stringify(data));
  });
}

if (app.ports && app.ports.clearSession) {
  app.ports.clearSession.subscribe(function(data) {
    localStorage.removeItem(storageKey);
    sessionStorage.removeItem(storageKey);
  });
}

var usernamesTaken = ['bob', 'laserpants', 'neo', 'neonpants', 'admin', 'speedo'];

var delay = 300;

if (app.ports && app.ports.websocketOut && app.ports.websocketIn) {
  app.ports.websocketOut.subscribe(function(data) {
    var message = JSON.parse(data);
    if ('username_available_query' === message.type) {
      setTimeout(function() {
        var response = {
          type: 'username_available_response',
          username: message.username,
          available: (-1 === usernamesTaken.indexOf(message.username))
        };
        app.ports.websocketIn.send(JSON.stringify(response));
      }, delay);
    }
  });
}
