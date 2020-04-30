'use strict';
const Sequelize = require('sequelize');

// setup test connection. Using memory based SQLite for speed
const sequelize = new Sequelize('sequelize-reassociate', '', '', {
  dialect: 'sqlite',
  logging: false,
});

// define models
const User = sequelize.define('user', {
  name: Sequelize.STRING
}, {
  classMethods: {
    reassociate: () => {
      return {
        comments: 1
      }
    }
  }
});

const Comment = sequelize.define('comment', {
  body: Sequelize.STRING,
});

// setup associations
User.hasMany(Comment);
Comment.belongsTo(User);

module.exports = {
  sequelize,
  models: {
    User, Comment
  }
};