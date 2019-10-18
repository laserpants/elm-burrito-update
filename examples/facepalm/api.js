var xhook = require('xhook');

var users =
[
  {
    id: 1,
    name: 'Mr. Test',
    password: 'test',
    username: 'test',
    email: 'test@test.com',
    rememberMe: false
  }
];

var posts =
[
  {
    id: 1,
    title: 'What is the facepalm?',
    body: 'A facepalm is the physical gesture of placing one’s hand across one’s face or lowering one’s face into one’s hand or hands, covering or closing one’s eyes.',
    comments: 
    [{
       id: 1,
       postId: 1,
       email: 'facepalm@test.com',
       body: 'Thanks for this information. I would just like to mention here the double facepalm, which is similar to the facepalm but performed with two hands. Keep up the good work!'
     },
     {
       id: 2,
       postId: 1,
       email: 'info@spam.org',
       body: 'Buy potatoes online. Delivery next day.'
    }]
  },
  {
    id: 2,
    title: 'Online use of the facepalm',
    body: 'Use of the gesture is not limited to visual representations. Often just the word, facepalm, is used to show someone’s disapproval or embarrassment.',
    comments: []
  }
];

var userId = 1;
var postId = 2;
var commentId = 0;
var delay = 400;

xhook.before(function(request, callback) {

  if (request.url.endsWith('auth/register') && 'POST' === request.method) {
    setTimeout(function() {
      var params = JSON.parse(request.body);
      params.id = ++userId;
      users.push(params);
      var user = {
        id: params.id,
        name: params.name,
        username: params.username,
        email: params.email,
        phoneNumber: params.phoneNumber,
        rememberMe: false
      };
      callback({
        status: 200,
        data: JSON.stringify({ status: 'success', user: user }),
        headers: { 'Content-Type': 'application/json' }
      });
    }, delay);
  }
  else if (request.url.endsWith('auth/login') && 'POST' === request.method) {
    setTimeout(function() {
      var params = JSON.parse(request.body),
          filtered = users.filter(function(user) {
        return user.username === params.username && user.password === params.password;
      });
      if (filtered.length > 0) {
        var user = filtered[0];
        user.rememberMe = params.rememberMe;
        var response = { session: { user: user } };
        callback({
          status: 200,
          data: JSON.stringify(response),
          headers: { 'Content-Type': 'application/json' }
        });
      } else {
        console.log('401 Unauthorized');
        callback({
          status: 401,
          data: JSON.stringify({ error: 'Unauthorized' }),
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }, delay);
  } else if (request.url.endsWith('posts')) {
    if ('GET' === request.method) {
      setTimeout(function() {
        callback({
          status: 200,
          data: JSON.stringify({ posts: posts.slice().reverse() }),
          headers: { 'Content-Type': 'application/json' }
        });
      }, delay);
    } else if ('POST' === request.method) {
      setTimeout(function() {
        var post = JSON.parse(request.body);
        post.id = ++postId;
        post.comments = [];
        posts.push(post);
        callback({
          status: 200,
          data: JSON.stringify({ post: post }),
          headers: { 'Content-Type': 'application/json' }
        });
      }, delay);
    }
  } else if (/posts\/\d+$/.test(request.url) && 'GET' === request.method) {
    setTimeout(function() {
      var id = request.url.match(/posts\/(\d+)$/)[1],
          filtered = posts.filter(function(post) { return post.id == id; });
      if (filtered.length > 0) {
        var response = filtered[0];
        callback({
          status: 200,
          data: JSON.stringify({ post: response }),
          headers: { 'Content-Type': 'application/json' }
        });
      } else {
        console.log('Not Found');
        callback({
          status: 404,
          data: JSON.stringify({ error: 'Not Found' }),
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }, delay);
  } else if (/posts\/\d+\/comments$/.test(request.url) && 'POST' === request.method) {
    setTimeout(function() {
      var comment = JSON.parse(request.body);
          filtered = posts.filter(function(post) { return post.id == comment.postId; });
      if (filtered.length > 0) {
        var post = filtered[0];
        post.comments = post.comments || [];
        comment.id = ++commentId;
        post.comments.unshift(comment);
        callback({
          status: 200,
          data: JSON.stringify({ post: post, comment: comment }),
          headers: { 'Content-Type': 'application/json' }
        });
      } else {
        console.log('Not Found');
        callback({
          status: 404,
          data: JSON.stringify({ error: 'Not Found' }),
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }, delay);
  } else {
    callback();
  }

});
