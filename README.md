# feathers-commands

> Create custom commands/routes for services beyond the [6 basic methods](https://docs.feathersjs.com/guides/basics/rest.html#rest-and-services) provided by FeathersJS


## Install
```
$ npm install feathers-commands
```

## Usage
```js
const app = express(feathers())

// Register api
app.configure(require('feathers-commands'));

// Create service
app.use('myService', {
    get: (id)=> ...
    create: (data)=> ...
});

// Register commands
app.service('myService').command('sayHello/:title?', (data, params)=> {
    const title = params.title || 'Mr.';
    return Promise.resolve(`Hello to ${title} ${data.name}`);
});

app.service('myService').command('getStatus/:id', function(data, params) {
    return this.get(params.id).then (doc)=> doc.status
});
```

##### Running commands internally
```js
app.service('myService').run('sayHello', {name:'Daniel'});
app.service('myService').run('getStatus', null, {id:'abc123'});
```

##### Running commands via REST
```
POST /myService/sayHello => 'Hello to Mr. undefined'
POST /myService/sayHello/Mrs {"name":"Angela"} => 'Hello to Mrs. Angela'
POST /myService/getStatus/def456 => '<status>'
POST /myService/getStatus => 404 NOT FOUND
```

##### Hooks
Hooks will be invoked for custom commands just like they do for the [6 native methods](https://docs.feathersjs.com/guides/basics/rest.html#rest-and-services)
```js
app.service('myService').hooks({
    before: {
        all: ()=> console.log('all hook')
        getStatus: [
            ()=> console.log('1st specific hook')
            ()=> console.log('2nd specific hook')
        ]
    },
    after: {
        sayHello: ()=> console.log('3rd specific hook')
    }
})
```

##### `this` context
Commands will be invoked under the service context, meaning that `this` refers to the feathers-wrapped service object.

##### websocket support
Currently websocket transporters such as Primus and Socket.IO aren't directly supported. PRs are welcome.


## License
MIT © [Daniel Kalen](https://github.com/danielkalen)